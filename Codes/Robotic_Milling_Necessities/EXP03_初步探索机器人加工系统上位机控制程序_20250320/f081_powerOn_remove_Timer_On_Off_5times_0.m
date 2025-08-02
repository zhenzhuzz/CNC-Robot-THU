function simple_plc_tcp()
    %% 初始化参数
    % plcIP = "192.168.0.1";
    plcIP = "127.0.0.1";
    plcPort = 2000;
    client = [];
    udpObj = [];  % UDP对象，初始为空
    isPLCConnected = false;  % PLC（主轴）连接状态
    isAccConnected = false;  % 加速度计连接状态
    targetSpeed = 0;         % 初始转速
    powerOn = 1;             % 初始上电状态

    % 用于PLC下电时连续发送停机命令的控制变量
    plcOffRequested = false;
    plcOffCounter = 0;       % 计数器，记录已连续发送的停机周期
    plcOffThreshold = 5;     % 例如5个周期=5秒（根据实际情况可调整）

    %% 创建GUI界面
    fig = uifigure('Name', 'PLC与加速度计通讯', 'Position', [500 200 600 500]);
    
    %% 主界面总体网格布局：2行（控制面板与数据展示）
    mainLayout = uigridlayout(fig, [2,1]);
    mainLayout.RowHeight = {'1x','2x'};
    
    %% 控制面板（上半部分）
    controlPanel = uipanel(mainLayout, 'Title', '控制面板');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;
    
    % 控制面板内采用2列布局：左侧PLC控制，右侧加速度计控制
    controlLayout = uigridlayout(controlPanel, [1,2]);
    controlLayout.ColumnWidth = {'1x','1x'};
    
    % 左侧：PLC控制面板
    plcPanel = uipanel(controlLayout, 'Title', 'PLC控制');
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
    
    % 右侧：加速度计控制面板
    accPanel = uipanel(controlLayout, 'Title', '加速度计控制');
    accPanel.Layout.Row = 1;
    accPanel.Layout.Column = 2;
    accLayout = uigridlayout(accPanel, [1,2]);
    accLayout.ColumnWidth = {'1x','1x'};
    
    btnAccOn = uibutton(accLayout, 'Text', '加速度计上电', 'ButtonPushedFcn', @accPowerOnClick);
    btnAccOff = uibutton(accLayout, 'Text', '加速度计下电', 'ButtonPushedFcn', @accPowerOffClick);
    btnAccOn.Layout.Row = 1;
    btnAccOn.Layout.Column = 1;
    btnAccOff.Layout.Row = 1;
    btnAccOff.Layout.Column = 2;
    
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
    plcTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.01, 'TimerFcn', @plcTimerFcn);
    
    %% 创建加速度计定时器（用于处理UDP数据）
    accTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.01, 'TimerFcn', @accTimerFcn);
    
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

            % 启动PLC定时器（用于接收数据及在下电状态下连续发送停机命令）
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
            % 设置下电请求标志，让PLC定时器连续发送停机命令
            plcOffRequested = true;
            plcOffCounter = 0;
            btnPowerOn.Text = '主轴上电';
            disp('主轴下电请求已发出，等待PLC确认停机');
        else
            disp('PLC未连接，无法执行下电操作');
        end
    end

    %% 加速度计上电回调函数
    function accPowerOnClick(~, ~)
        if ~isAccConnected
            try
                udpObj = udpport("datagram", "IPV4", "LocalHost", "192.168.88.2", "LocalPort", 1600);
            catch ME
                disp(['加速度计UDP连接失败: ' ME.message]);
                return;
            end
            isAccConnected = true;
            btnAccOn.Text = '加速度计已连接';
            if strcmp(accTimer.Running, 'off')
                start(accTimer);
            end
            disp('加速度计UDP连接已建立');
        else
            disp('加速度计已连接，无法重复连接');
        end
    end

    %% 加速度计下电回调函数
    function accPowerOffClick(~, ~)
        if isAccConnected
            isAccConnected = false;
            btnAccOn.Text = '加速度计上电';
            disp('加速度计下电，UDP通信已停止');
            cleanupUDP();
            if strcmp(accTimer.Running, 'on')
                stop(accTimer);
            end
        else
            disp('加速度计未连接，无法执行下电操作');
        end
    end

    %% PLC定时器回调函数（仅用于接收数据和下电时连续发送停机命令）
    function plcTimerFcn(~, ~)
        if isPLCConnected
            if ~plcOffRequested
                % 仅接收数据，不发送转速命令
                data = receiveData();
                if ~isempty(data)
                    parsed = parseData(data);
                    txtDisplay.Value = {['PLC数据: ', num2str(parsed)]};
                    disp(['PLC数据: ', num2str(parsed)]);
                end
            else
                % 下电请求状态：持续发送停机命令（0指令）
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

    %% 加速度计定时器回调函数
    function accTimerFcn(~, ~)
        if isAccConnected && ~isempty(udpObj) && udpObj.NumDatagramsAvailable > 0
            processAccData();
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
        data = regexprep(strtrim(data), '[^\d]', '');
        parsed = str2double(data);
    end

    %% 更新转速回调函数（修改为单次发送）
    function updateTargetSpeed(src, ~)
        if isPLCConnected
            targetSpeed = src.Value;
            sendCmd();  % 直接发送新的转速命令
            disp(['更新目标转速为: ', num2str(targetSpeed)]);
        else
            disp('PLC未连接，无法更新转速');
        end
    end

    %% 处理加速度数据：读取所有UDP数据包并逐包解析
    function processAccData()
        datagrams = read(udpObj, udpObj.NumDatagramsAvailable, "uint8");
        for k = 1:length(datagrams)
            packet = datagrams(k).Data;
            if numel(packet) >= 10
                [acc_x, acc_y, acc_z] = parseAccPacket(packet);
                disp(['加速度计数据 -> acc_x: ', num2str(acc_x), ...
                      ', acc_y: ', num2str(acc_y), ...
                      ', acc_z: ', num2str(acc_z)]);
            else
                disp('UDP数据包长度不足10字节，无法解析加速度数据。');
            end
        end
    end

    %% 解析单个加速度数据包
    function [acc_x, acc_y, acc_z] = parseAccPacket(packet)
        acc_x = typecast(uint8(packet(5:6)), 'int16');
        acc_y = typecast(uint8(packet(7:8)), 'int16');
        acc_z = typecast(uint8(packet(9:10)), 'int16');
    end

    %% 清理PLC连接
    function cleanupConnection()
        if ~isempty(client)
            clear client;
            disp('PLC连接已清理');
        end
    end

    %% 清理UDP连接
    function cleanupUDP()
        if ~isempty(udpObj)
            try
                delete(udpObj);
            catch ME
                disp(['删除UDP连接时出错: ' ME.message]);
            end
            udpObj = [];
            disp('加速度计UDP连接已清理');
        end
    end

    %% 窗口关闭处理
    function closeApp()
        if strcmp(plcTimer.Running, 'on')
            stop(plcTimer);
        end
        if strcmp(accTimer.Running, 'on')
            stop(accTimer);
        end
        delete(plcTimer);
        delete(accTimer);
        if isPLCConnected
            sendCmd();
            clear client;
            disp('PLC连接关闭，程序结束');
        end
        if isAccConnected
            cleanupUDP();
        end
        delete(fig);
    end
end
