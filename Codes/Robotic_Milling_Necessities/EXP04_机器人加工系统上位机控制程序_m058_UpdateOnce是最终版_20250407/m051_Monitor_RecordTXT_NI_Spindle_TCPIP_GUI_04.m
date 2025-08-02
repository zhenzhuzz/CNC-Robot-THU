% function m051_Monitor_RecordTXT_NI_Spindle_TCPIP_GUI_04

% 1. **新增监测按钮和决策调用**
% 
%     * 在第二行中，新增加了一个按钮 `btnMonitor`（行 60～63），用于开启/停止监测。
%     * 在 `monitorButtonCallback`（行 193～198）中，根据当前监测状态切换按钮文字，并更新 `isMonitoring`。
%     * 在加速度计回调函数 `accelDAQCallback`（行 150 后部），如果 `isMonitoring` 为真，则调用决策函数 `m060_Decision_fft_filter_report(data)`。
% 2. **记录数据停止时保存TXT文件**
% 
%     * 在 `recordButtonCallback` 的停止分支（行 166～174）中，增加了弹出文件保存对话框，使用 `writematrix` 将 dataLog（经过时间处理后）保存为 TXT 文件，且不包含表头。
% 3. **允许仅有一个设备上电记录数据**
% 
%     * 修改了记录数据按钮的检查逻辑（行 157）：只要求主轴或加速度计其中至少一个上电。
%     * 当加速度计未上电时，在 `spindleTimerFcn`（行 138～141）中记录主轴数据，并利用 `toc(recordStartTime)` 生成时间戳；若加速度计上电，则以其时间戳为准。
%     * 记录时，缺失的数据自动以 `NaN` 保存。

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
    
    % 新增：记录开始时间（用于主轴单独上电时生成时间戳）
    recordStartTime = [];  % <-- 新增

    % 新增：监测状态变量
    isMonitoring = false;  % <-- 新增

    % 全局保存最新主轴转速，用于记录时和显示
    currentSpindleSpeed = NaN;

    %% 创建 GUI 界面
    fig = uifigure('Name', '主轴与加速度计控制面板', 'Position', [300 100 800 700]);

    % 主界面网格布局：3行（控制面板、记录/监测按钮、数据展示）
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
    txtSamplingRate.ValueDisplayFormat = '%.0f';  % <-- 新增
    lblSamplingRate.Layout.Row = 2; txtSamplingRate.Layout.Row = 2;
    lblSamplingRate.Layout.Column = 1; txtSamplingRate.Layout.Column = 2;

    %% 第二行：记录/监测按钮（横跨整个界面）
    % 修改：将原记录数据按钮改为两个并排按钮
    recordLayout = uigridlayout(mainLayout, [1,2]);
    recordLayout.RowHeight = {'1x'};
    recordLayout.ColumnWidth = {'1x','1x'};
    recordLayout.Layout.Row = 2; recordLayout.Layout.Column = 1;
    btnRecord = uibutton(recordLayout, 'Text', '记录数据', 'ButtonPushedFcn', @recordButtonCallback);
    btnMonitor = uibutton(recordLayout, 'Text', '监测开启', 'ButtonPushedFcn', @monitorButtonCallback);  % <-- 新增

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

    %% 创建主轴定时器（TCP 通讯，用于接收数据及下电时连续发送停机命令）
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
                % 新增：如果加速度计未上电但正在记录，生成主轴数据的时间戳
                if isRecording && ~accelRunning
                    t = toc(recordStartTime);
                    newRow = [t, NaN, currentSpindleSpeed];
                    dataLog = [dataLog; newRow];
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
            % 显示最新的一个采样点（如需显示全部可修改）
            latestValue = data(end,1);
            prependAccelDisplay(['采集数据: ' num2str(latestValue)]);
            % 新增：如果监测开启，每0.1秒调用决策函数（传入本次数据块）
            if isMonitoring
                m060_Decision_fft_filter_report(data);
            end
            if isRecording
                % 若加速度计上电，使用其时间戳；若未上电，则记录为NaN
                numPoints = length(timestamps);
                % 若主轴未上电，则currentSpindleSpeed可能为NaN
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
        % 修改：只需至少一个设备上电即可启用记录
        if ~(isSpindleConnected || accelRunning)
            uialert(fig, '主轴或加速度计至少一个必须上电', '提示');
            return;
        end
        if ~isRecording
            dataLog = [];  % 清空旧记录
            isRecording = true;
            src.Text = '■';
            % 新增：记录开始时间，用于生成主轴单独数据的时间戳
            recordStartTime = tic;  % <-- 新增
            prependSpindleDisplay('开始记录数据...');
            prependAccelDisplay('开始记录数据...');
        else
            isRecording = false;
            % 处理 timestamps：令时间从0开始
            if ~isempty(dataLog)
                dataLog(:,1) = dataLog(:,1) - dataLog(1,1);
            end
            src.Text = '记录数据';
            % 保存至工作区（以三个变量形式保存，也可改为一个matrix）
            assignin('base', 'timestamps', dataLog(:,1));
            assignin('base', 'accX', dataLog(:,2));
            assignin('base', 'spinSpeed', dataLog(:,3));
            % 新增：弹出保存对话框，保存为txt文件（无header）
            [filename, pathname] = uiputfile('*.txt', '保存数据记录为TXT文件');
            if ischar(filename)
                fullpath = fullfile(pathname, filename);
                writematrix(dataLog, fullpath, 'Delimiter', '\t');
            end
            prependAccelDisplay('数据记录停止，数据已保存');
        end
    end

    % --- 新增：监测按钮回调 ---
    function monitorButtonCallback(src, ~)
        if ~isMonitoring
            isMonitoring = true;
            src.Text = '停止监测';
            prependAccelDisplay('监测已开启');
        else
            isMonitoring = false;
            src.Text = '监测开启';
            prependAccelDisplay('监测已停止');
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
