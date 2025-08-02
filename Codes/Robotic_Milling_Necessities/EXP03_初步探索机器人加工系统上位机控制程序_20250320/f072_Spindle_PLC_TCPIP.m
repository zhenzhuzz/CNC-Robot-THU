function simple_plc_tcp()
    %% 初始化参数
    % plcIP = "192.168.0.1";
    plcIP = "127.0.0.1";
    plcPort = 2000;
    client = [];
    isPLCConnected = false;  % PLC（主轴）连接状态
    targetSpeed = 0;         % 初始转速
    powerOn = 1;             % 初始上电状态

    % 用于PLC下电时连续发送停机命令的控制变量
    plcOffRequested = false;
    plcOffCounter = 0;       % 计数器，记录已连续发送的停机周期
    plcOffThreshold = 5;     % 例如5个周期=5秒（根据实际情况可调整）
    
    % 数据记录相关变量（记录到工作区，不写文件）
    isRecording = false;
    % 预分配1000行2列数据：[RelativeTime, spinSpeed]
    dataLog = cell(1000, 2);
    dataCount = 0;  % 记录有效数据行数
    % 记录开始时刻（使用 tic/toc 高精度计时）
    recordStartTime = [];
    
    % lastSpinSpeed 用于保存最新PLC接收到的转速数据
    lastSpinSpeed = NaN;  

    %% 创建GUI界面
    % 修改标题，去除加速度计字样
    fig = uifigure('Name', 'PLC通讯', 'Position', [500 200 600 600]);
    
    %% 主界面总体网格布局：2行（控制面板与数据展示）
    mainLayout = uigridlayout(fig, [2,1]);
    mainLayout.RowHeight = {'1x','2x'};
    
    %% 控制面板（上半部分）
    controlPanel = uipanel(mainLayout, 'Title', '控制面板');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;
    
    % 控制面板分为两行：第一行为PLC控制，第二行为数据记录按钮
    controlPanelLayout = uigridlayout(controlPanel, [2,1]);
    controlPanelLayout.RowHeight = {'6x','1x'};
    
    % 第一行：PLC控制面板
    plcPanel = uipanel(controlPanelLayout, 'Title', 'PLC控制');
    plcPanel.Layout.Row = 1;
    plcPanel.Layout.Column = 1;
    plcLayout = uigridlayout(plcPanel, [2,2]);
    plcLayout.RowHeight = {'1x','1x'};
    plcLayout.ColumnWidth = {'1x','1x'};
    
    btnPowerOn = uibutton(plcLayout, 'Text', '主轴上电', 'ButtonPushedFcn', @powerOnClick);
    btnPowerOff = uibutton(plcLayout, 'Text', '主轴下电', 'ButtonPushedFcn', @powerOffClick);
    btnPowerOn.Layout.Row = 1;
    btnPowerOn.Layout.Column = 1;
    btnPowerOff.Layout.Row = 1;
    btnPowerOff.Layout.Column = 2;
    
    lblSpeed = uilabel(plcLayout, 'Text', '设定转速:');
    txtSpeed = uieditfield(plcLayout, 'numeric', 'Value', targetSpeed, 'ValueChangedFcn', @updateTargetSpeed);
    lblSpeed.Layout.Row = 2;
    lblSpeed.Layout.Column = 1;
    txtSpeed.Layout.Row = 2;
    txtSpeed.Layout.Column = 2;
    
    % 第二行：数据记录按钮
    btnRecord = uibutton(controlPanelLayout, 'Text', '记录数据', 'ButtonPushedFcn', @recordButtonCallback);
    btnRecord.Layout.Row = 2;
    btnRecord.Layout.Column = 1;
    
    %% 数据展示区域（下半部分）
    displayPanel = uipanel(mainLayout, 'Title', '数据展示');
    displayPanel.Layout.Row = 2;
    displayPanel.Layout.Column = 1;
    displayLayout = uigridlayout(displayPanel, [1,1]);
    txtDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'通讯数据将在此显示...'});
    txtDisplay.Layout.Row = 1;
    txtDisplay.Layout.Column = 1;
    
    %% 窗口关闭回调
    fig.CloseRequestFcn = @(src,event) closeApp();
    
    %% 创建PLC定时器（用于接收PLC数据以及在下电时连续发送停机命令）
    plcTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @plcTimerFcn);
    
    %% PLC 上电回调函数
    function powerOnClick(~, ~)
        if ~isPLCConnected
            try
                client = tcpclient(plcIP, plcPort);
            catch ME
                disp(['PLC连接失败: ' ME.message]);
                return;
            end
            isPLCConnected = true;
            powerOn = 1;
            btnPowerOn.Text = '主轴已连接';
            
            % 上电时发送1次复位命令 "!!00000,1#"
            sendCmd();
            
            % 启动PLC定时器
            if strcmp(plcTimer.Running, 'off')
                start(plcTimer);
            end
            % 重置下电标志
            plcOffRequested = false;
            plcOffCounter = 0;
            disp('主轴已连接');
        else
            disp('主轴已连接，无法重复连接');
        end
    end

    %% PLC 下电回调函数
    function powerOffClick(~, ~)
        if isPLCConnected
            targetSpeed = 0;
            powerOn = 0;
            plcOffRequested = true;
            plcOffCounter = 0;
            btnPowerOn.Text = '主轴上电';
            disp('主轴下电请求已发出，等待PLC确认停机');
        else
            disp('PLC未连接，无法执行下电操作');
        end
    end

    %% PLC定时器回调函数（接收数据及下电时连续发送停机命令）
    function plcTimerFcn(~, ~)
        if isPLCConnected
            if ~plcOffRequested
                % 接收PLC数据
                data = receiveData();
                if ~isempty(data)
                    parsed = parseData(data);
                    lastSpinSpeed = parsed;  % 更新最新转速
                    txtDisplay.Value = {['PLC数据: ', num2str(parsed)]};
                    disp(['PLC数据: ', num2str(parsed)]);
                    % 记录PLC数据
                    if isRecording
                        t = toc(recordStartTime);
                        logDataRow(t, parsed);
                    end
                end
            else
                % 下电请求状态：持续发送停机命令
                sendCmd();
                plcOffCounter = plcOffCounter + 1;
                if plcOffCounter >= plcOffThreshold
                    stop(plcTimer);
                    cleanupConnection();
                    isPLCConnected = false;
                    plcOffRequested = false;
                    disp('PLC已确认停机，通信停止');
                end
            end
        end
    end

    %% 发送PLC命令
    function sendCmd()
        if isPLCConnected
            cmd = sprintf('!!%05d,%d#', targetSpeed, powerOn);
            write(client, unicode2native(cmd, 'UTF-8'));
        end
    end

    %% 接收PLC数据
    function data = receiveData()
        if isPLCConnected && client.NumBytesAvailable > 0
            data = char(read(client, client.NumBytesAvailable));
        else
            data = '';
        end
    end

    %% 解析PLC数据
    function parsed = parseData(data)
        % 分割字符串，假定数据总以 '#' 结尾，所以最后一个元素为空
        msgs = strsplit(data, '#');
        % 取倒数第二个元素作为最后一个完整消息
        lastMsg = msgs{end-1};
        % 提取第一个数字作为转速
        tokens = regexp(lastMsg, '\d+', 'match');
        parsed = str2double(tokens{1});
    end

    %% 更新转速回调函数（单次发送）
    function updateTargetSpeed(src, ~)
        if isPLCConnected
            targetSpeed = src.Value;
            sendCmd();
            disp(['更新目标转速为: ', num2str(targetSpeed)]);
        else
            disp('PLC未连接，无法更新转速');
        end
    end

    %% 数据记录：将一行数据存入预分配的 cell 数组
    function logDataRow(t, spin)
        % newRow 为 cell 类型：[时间, spinSpeed]
        newRow = {t, spin};
        dataCount = dataCount + 1;
        if dataCount > size(dataLog, 1)
            % 超出预分配大小则扩展 cell 数组（每次增加 1000 行）
            dataLog = [dataLog; cell(1000, 2)];
        end
        dataLog(dataCount, :) = newRow;
    end

    %% 数据记录按钮回调函数
    function recordButtonCallback(src, ~)
        if ~isPLCConnected
            disp('主轴未上电');
            return;
        end
        
        if ~isRecording
            % 开始记录：初始化预分配 cell 数组、计数器，并用 tic 初始化计时
            dataLog = cell(1000, 2);
            dataCount = 0;
            recordStartTime = tic;
            isRecording = true;
            src.Text = '■';  % 按钮显示为“停止”
            disp('开始记录数据...');
        else
            % 停止记录：保存记录数据到基础工作区
            isRecording = false;
            dataLog = dataLog(1:dataCount, :);
            assignin('base', 'dataLog', dataLog);
            src.Text = '记录数据';
            disp('数据记录停止，数据已保存到工作区变量 dataLog');
        end
    end

    %% 清理PLC连接
    function cleanupConnection()
        if ~isempty(client)
            clear client;
            disp('PLC连接已清理');
        end
    end

    %% 窗口关闭处理
    function closeApp()
        if strcmp(plcTimer.Running, 'on')
            stop(plcTimer);
        end
        delete(plcTimer);
        if isPLCConnected
            sendCmd();
            clear client;
            disp('PLC连接关闭，程序结束');
        end
        isRecording = false;
        delete(fig);
    end
end
