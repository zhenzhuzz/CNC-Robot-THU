% function m050_NI_Spindle_TCPIP_GUI_04()

function m050_NI_Spindle_TCPIP_GUI_04()
    %% 初始化参数
    % 主轴（Spindle）相关参数
    spindleIP = "127.0.0.1";
    spindlePort = 2000;
    spindleClient = [];
    isSpindleConnected = false;  % 主轴连接状态
    targetSpeed = 0;             % 主轴设定转速
    spindlePowerOn = 1;          % 主轴上电状态

    spindleOffRequested = false;
    spindleOffCounter = 0;       % 连续发送停机命令计数
    spindleOffThreshold = 5;     % 例如5个周期

    % 加速度计（Accelerometer）相关参数
    accelDAQ = [];      % NI DAQ 对象
    accelRunning = false;
    defaultSamplingRate = 12800;  % 默认采样率
    allowedRates = [10240, 12800, 25600];  % 示例硬件支持的采样率

    % 数据记录相关变量
    isRecording = false;
    % dataLog 记录矩阵：第一列为 NI DAQ 返回的 timestamp，
    % 第二列为加速度数据，第三列为主轴转速
    dataLog = [];

    % 全局保存最新主轴转速，用于记录时和显示
    currentSpindleSpeed = NaN;

    %% 创建 GUI 界面
    fig = uifigure('Name', '设备通讯', 'Position', [300 200 800 600]);

    % 主界面网格布局：3行（控制面板、记录数据按钮、数据展示）
    mainLayout = uigridlayout(fig, [3,1]);
    mainLayout.RowHeight = {'1x','0.2x','2x'};

    %% 第一行：控制面板，左右分栏
    controlPanel = uipanel(mainLayout, 'Title', '控制面板');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;
    cpLayout = uigridlayout(controlPanel, [1,2]);
    cpLayout.ColumnWidth = {'1x','1x'};

    % 左侧：主轴相关控制
    spindlePanel = uipanel(cpLayout, 'Title', '主轴');
    spindlePanel.Layout.Row = 1;
    spindlePanel.Layout.Column = 1;
    spindleLayout = uigridlayout(spindlePanel, [2,2]);
    spindleLayout.RowHeight = {'1x','1x'};
    spindleLayout.ColumnWidth = {'1x','1x'};

    btnSpindleOn = uibutton(spindleLayout, 'Text', '主轴上电', 'ButtonPushedFcn', @spindlePowerOnClick);
    btnSpindleOff = uibutton(spindleLayout, 'Text', '主轴下电', 'ButtonPushedFcn', @spindlePowerOffClick);
    btnSpindleOn.Layout.Row = 1;  btnSpindleOn.Layout.Column = 1;
    btnSpindleOff.Layout.Row = 1; btnSpindleOff.Layout.Column = 2;

    lblSpeed = uilabel(spindleLayout, 'Text', '设定转速:');
    txtSpeed = uieditfield(spindleLayout, 'numeric', 'Value', targetSpeed, 'ValueChangedFcn', @updateTargetSpeed);
    lblSpeed.Layout.Row = 2; txtSpeed.Layout.Row = 2;
    lblSpeed.Layout.Column = 1; txtSpeed.Layout.Column = 2;

    % 右侧：加速度计相关控制
    accelPanel = uipanel(cpLayout, 'Title', '加速度计');
    accelPanel.Layout.Row = 1;
    accelPanel.Layout.Column = 2;
    accelLayout = uigridlayout(accelPanel, [2,2]);
    accelLayout.RowHeight = {'1x','1x'};
    accelLayout.ColumnWidth = {'1x','1x'};

    btnAccelOn = uibutton(accelLayout, 'Text', '加速度计上电', 'ButtonPushedFcn', @accelPowerOn);
    btnAccelOff = uibutton(accelLayout, 'Text', '加速度计下电', 'ButtonPushedFcn', @accelPowerOff);
    btnAccelOn.Layout.Row = 1; btnAccelOn.Layout.Column = 1;
    btnAccelOff.Layout.Row = 1; btnAccelOff.Layout.Column = 2;

    lblSamplingRate = uilabel(accelLayout, 'Text', '采样率:');
    txtSamplingRate = uieditfield(accelLayout, 'numeric', 'Value', defaultSamplingRate, 'ValueChangedFcn', @updateSamplingRate);
    % 设置采样率显示格式为整数
    txtSamplingRate.ValueDisplayFormat = '%.0f';
    lblSamplingRate.Layout.Row = 2; txtSamplingRate.Layout.Row = 2;
    lblSamplingRate.Layout.Column = 1; txtSamplingRate.Layout.Column = 2;

    %% 第二行：记录数据按钮（横跨整个界面）
    btnRecord = uibutton(mainLayout, 'Text', '记录数据', 'ButtonPushedFcn', @recordButtonCallback);
    btnRecord.Layout.Row = 2; btnRecord.Layout.Column = 1;

    %% 第三行：数据展示区域，左右分栏
    displayPanel = uipanel(mainLayout, 'Title', '数据展示');
    displayPanel.Layout.Row = 3;
    displayPanel.Layout.Column = 1;
    displayLayout = uigridlayout(displayPanel, [1,2]);
    displayLayout.ColumnWidth = {'1x','1x'};

    % 最新数据显示在顶部
    txtSpindleDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'转速显示：'});
    txtSpindleDisplay.Layout.Row = 1; txtSpindleDisplay.Layout.Column = 1;
    txtAccelDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'加速度计显示：'});
    txtAccelDisplay.Layout.Row = 1; txtAccelDisplay.Layout.Column = 2;

    %% 创建主轴定时器（TCP 通讯，用于接收数据以及下电时连续发送停机命令）
    spindleTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @spindleTimerFcn);

    %% 窗口关闭回调
    fig.CloseRequestFcn = @(src,event) closeApp();

    %% 回调函数

    % --- 主轴（Spindle）上电 ---
    function spindlePowerOnClick(~, ~)
        if ~isSpindleConnected
            try
                spindleClient = tcpclient(spindleIP, spindlePort);
            catch ME
                uialert(fig, ['主轴连接失败: ' ME.message], '错误');
                return;
            end
            isSpindleConnected = true;
            spindlePowerOn = 1;
            btnSpindleOn.Text = '主轴已连接';
            % 上电时发送一次复位命令
            sendSpindleCmd();
            if strcmp(spindleTimer.Running, 'off')
                start(spindleTimer);
            end
            spindleOffRequested = false;
            spindleOffCounter = 0;
            prependSpindleDisplay('主轴已连接');
        else
            prependSpindleDisplay('主轴已连接，无法重复连接');
        end
    end

    % --- 主轴下电 ---
    function spindlePowerOffClick(~, ~)
        if isSpindleConnected
            targetSpeed = 0;
            spindlePowerOn = 0;
            spindleOffRequested = true;
            spindleOffCounter = 0;
            btnSpindleOn.Text = '主轴上电';
            prependSpindleDisplay('主轴下电请求已发出，等待主轴确认停机');
        else
            prependSpindleDisplay('主轴未连接，无法执行下电操作');
        end
    end

    % --- 更新主轴转速（单次发送） ---
    function updateTargetSpeed(src, ~)
        if isSpindleConnected
            targetSpeed = src.Value;
            sendSpindleCmd();
            prependSpindleDisplay(['更新目标转速为: ' num2str(targetSpeed)]);
        else
            prependSpindleDisplay('主轴未连接，无法更新转速');
        end
    end

    % --- 主轴定时器回调函数 ---
    function spindleTimerFcn(~, ~)
        if isSpindleConnected
            if ~spindleOffRequested
                % 接收主轴数据
                data = receiveSpindleData();
                if ~isempty(data)
                    speedVal = parseSpindleData(data);
                    currentSpindleSpeed = speedVal;  % 更新全局转速变量
                    prependSpindleDisplay(['主轴数据: ' num2str(speedVal)]);
                end
            else
                % 下电请求状态：连续发送停机命令
                sendSpindleCmd();
                spindleOffCounter = spindleOffCounter + 1;
                if spindleOffCounter >= spindleOffThreshold
                    stop(spindleTimer);
                    cleanupSpindleConnection();
                    isSpindleConnected = false;
                    spindleOffRequested = false;
                    prependSpindleDisplay('主轴已确认停机，通信停止');
                end
            end
        end
    end

    % --- 发送主轴命令 ---
    function sendSpindleCmd()
        if isSpindleConnected
            cmd = sprintf('!!%05d,%d#', targetSpeed, spindlePowerOn);
            write(spindleClient, unicode2native(cmd, 'UTF-8'));
        end
    end

    % --- 接收主轴数据 ---
    function data = receiveSpindleData()
        if isSpindleConnected && spindleClient.NumBytesAvailable > 0
            data = char(read(spindleClient, spindleClient.NumBytesAvailable));
        else
            data = '';
        end
    end

    % --- 解析主轴数据（假定数据格式相同） ---
    function speedVal = parseSpindleData(data)
        msgs = strsplit(data, '#');
        if length(msgs) >= 2
            lastMsg = msgs{end-1};
            tokens = regexp(lastMsg, '\d+', 'match');
            if ~isempty(tokens)
                speedVal = str2double(tokens{1});
            else
                speedVal = NaN;
            end
        else
            speedVal = NaN;
        end
    end

    % --- 加速度计上电 ---
    function accelPowerOn(~, ~)
        if accelRunning
            uialert(fig, '加速度计已上电，正在采集数据。', '提示');
            return;
        end
        try
            accelDAQ = daq("ni");
        catch ME
            uialert(fig, ['无法创建DAQ对象: ' ME.message], '错误');
            return;
        end
        try
            % 添加加速度计通道（请根据实际设备修改设备ID及通道）
            ch = addinput(accelDAQ, "cDAQ1Mod1", "ai0", "Accelerometer");
            ch.Sensitivity = 0.01000;
            % 采样率调整为允许值，并以整数显示
            newRate = round(adjustSamplingRate(txtSamplingRate.Value));
            accelDAQ.Rate = newRate;
            txtSamplingRate.Value = newRate;
            % 设置回调：每当采集到一定扫描点数时触发（例如0.1秒数据）
            accelDAQ.ScansAvailableFcnCount = round(newRate/10);
            accelDAQ.ScansAvailableFcn = @accelDAQCallback;
            start(accelDAQ, "continuous");
        catch ME
            uialert(fig, ['加速度计配置失败: ' ME.message], '错误');
            return;
        end
        accelRunning = true;
        prependAccelDisplay('加速度计上电，开始连续采集数据...');
    end

    % --- 加速度计下电 ---
    function accelPowerOff(~, ~)
        if isempty(accelDAQ) || ~isvalid(accelDAQ) || ~accelDAQ.Running
            uialert(fig, '加速度计已经下电或未在采集数据。', '提示');
            return;
        end
        stop(accelDAQ);
        accelRunning = false;
        prependAccelDisplay('加速度计下电，停止采集数据.');
    end

    % --- 更新采样率回调 ---
    function updateSamplingRate(src, ~)
        newRate = round(adjustSamplingRate(src.Value));
        src.Value = newRate;
        if accelRunning && ~isempty(accelDAQ) && isvalid(accelDAQ)
            stop(accelDAQ);
            accelDAQ.Rate = newRate;
            accelDAQ.ScansAvailableFcnCount = round(newRate/10);
            start(accelDAQ, "continuous");
            prependAccelDisplay(['更新采样率为: ' num2str(newRate)]);
        end
    end

    % --- 加速度计 DAQ 回调函数 ---
    function accelDAQCallback(src, evt)
        % 读取当前周期内采集的数据（例如0.1秒内约1280个点）
        [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        if ~isempty(timestamps) && ~isempty(data)
            % 显示最新的一个采样点
            latestValue = data(end,1);
            prependAccelDisplay(['采集数据: ' num2str(latestValue)]);
            if isRecording
                % 将所有采样点记录下来，每行格式：[timestamp, 加速度数据, 主轴转速]
                numPoints = length(timestamps);
                newRows = [timestamps, data, repmat(currentSpindleSpeed, numPoints, 1)];
                dataLog = [dataLog; newRows];
            end
        end
    end

    % --- 自动调整采样率为允许值 ---
    function adjustedRate = adjustSamplingRate(rate)
        [~, idx] = min(abs(allowedRates - rate));
        adjustedRate = allowedRates(idx);
    end

    % --- 记录数据按钮回调 ---
    function recordButtonCallback(src, ~)
        if ~isSpindleConnected
            uialert(fig, '主轴未上电', '提示');
            return;
        end
        if ~accelRunning
            uialert(fig, '加速度计未上电', '提示');
            return;
        end

        if ~isRecording
            dataLog = [];  % 清空旧记录
            isRecording = true;
            src.Text = '■';
            prependSpindleDisplay('开始记录数据...');
            prependAccelDisplay('开始记录数据...');
        else
            isRecording = false;
            % 处理 timestamps：将每个 timestamp 减去第一个，令时间从0开始
            if ~isempty(dataLog)
                dataLog(:,1) = dataLog(:,1) - dataLog(1,1);
            end
            src.Text = '记录数据';
            % 下面两行是dataLog保存成table
            % dataLogTable = array2table(dataLog, 'VariableNames', {'time', 'accX', 'spinSpeed'});
            % assignin('base', 'dataLog', dataLogTable);            prependSpindleDisplay('数据记录停止，数据已保存到工作区变量 dataLog');
            % 下面一行是dataLog保存成matrix
            % assignin('base', 'dataLog', dataLog);
            assignin('base', 'timestamps', dataLog(:,1));
            assignin('base', 'accX', dataLog(:,2));
            assignin('base', 'spinSpeed', dataLog(:,3));
            prependAccelDisplay('数据记录停止，数据已保存到工作区变量 dataLog');
        end
    end

    % --- 将信息预先添加到主轴显示区域（最新在顶部） ---
    function prependSpindleDisplay(msg)
        txtSpindleDisplay.Value = [{msg}; txtSpindleDisplay.Value];
    end

    % --- 将信息预先添加到加速度计显示区域（最新在顶部） ---
    function prependAccelDisplay(msg)
        txtAccelDisplay.Value = [{msg}; txtAccelDisplay.Value];
    end

    % --- 清理主轴连接 ---
    function cleanupSpindleConnection()
        if ~isempty(spindleClient)
            clear spindleClient;
            prependSpindleDisplay('主轴连接已清理');
        end
    end

    % --- 窗口关闭处理 ---
    function closeApp()
        if strcmp(spindleTimer.Running, 'on')
            stop(spindleTimer);
        end
        delete(spindleTimer);
        if isSpindleConnected
            sendSpindleCmd();
            clear spindleClient;
            prependSpindleDisplay('主轴连接关闭，程序结束');
        end
        if accelRunning && ~isempty(accelDAQ) && isvalid(accelDAQ)
            stop(accelDAQ);
        end
        isRecording = false;
        delete(fig);
    end

end
