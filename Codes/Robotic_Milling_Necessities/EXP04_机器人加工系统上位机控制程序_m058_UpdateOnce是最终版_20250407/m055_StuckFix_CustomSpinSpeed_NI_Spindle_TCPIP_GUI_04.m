%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m055_StuckFix_CustomSpinSpeed_NI_Spindle_TCPIP_GUI_04.m
%
% 说明：
%   本程序实现了主轴与加速度计的联合控制及数据监测、记录功能，
%   并在GUI中增加了“自定义调速”功能。
%
%   自定义调速功能说明：
%       - 定义了一个调速曲线函数 customSpeedProfile，
%         根据经过时间返回目标转速（例如：0秒时5000rpm，3秒时3000rpm，5秒时2000rpm）。
%       - 在记录数据和监测按钮所在行增加一个按钮，按钮文字为“自定义调速开启”；
%         当按下后，按钮文字切换为停止图标（■），并启动定时器调用 customSpeedProfile 更新转速。
%       - 开启前会判断主轴是否已上电，否则弹出提示。
%
% 作者：Zhen Zhu
% 日期：Every day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function m055_StuckFix_CustomSpinSpeed_NI_Spindle_TCPIP_GUI_04()
    %% 初始化参数

    % --- 主轴（Spindle）相关参数 ---
    spindleIP = "127.0.0.1";                % 主轴的 IP 地址
    spindlePort = 2000;                     % 主轴通信端口
    spindleClient = [];                     % TCP/IP 客户端对象
    isSpindleConnected = false;             % 主轴连接状态标志
    targetSpeed = 0;                        % 主轴设定转速
    spindlePowerOn = 1;                     % 主轴上电状态标志（1 表示上电）

    spindleOffRequested = false;            % 主轴下电请求标志
    spindleOffCounter = 0;                  % 连续发送停机命令的计数器
    spindleOffThreshold = 5;                % 停机命令发送的周期阈值

    % --- 加速度计（Accelerometer）相关参数 ---
    accelDAQ = [];                          % NI DAQ 对象
    accelRunning = false;                   % 加速度计采集状态标志
    defaultSamplingRate = 12800;            % 默认采样率
    threshold = 0.5;                          % 决策函数阈值

    % --- 数据记录相关参数 ---
    isRecording = false;                    % 数据记录状态标志
    dataLog = [];                           % 记录数据矩阵（timestamp, 加速度, 主轴转速）
    recordStartTime = [];                   % 记录开始时间

    % --- 监测状态变量 ---
    isMonitoring = false;
    currentSpindleSpeed = NaN;              % 当前主轴转速

    % --- 自定义调速相关参数 ---
    isCustomSpeedActive = false;
    customSpeedTimer = [];
    customSpeedStartTime = [];

    % --- 转速拟合修正系数 ---
    slope = 0.867785714285714;
    intercept = 17.7714285714283;

    %% 创建 GUI 界面

    % 创建主窗体，并设置标题和位置
    fig = uifigure('Name', '主轴与加速度计控制面板', 'Position', [300 100 850 700]);

    % 设置主界面的布局，共分为3行：
    % 第一行：控制面板（主轴和加速度计控制区域）
    % 第二行：按钮区域（记录数据、监测开启、自定义调速）
    % 第三行：数据展示区
    mainLayout = uigridlayout(fig, [3,1]);
    mainLayout.RowHeight = {'0.8x','0.2x','2x'};

    %% 第一行：控制面板区域（左右分栏）
    controlPanel = uipanel(mainLayout, 'Title', '控制面板');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;
    cpLayout = uigridlayout(controlPanel, [1,2]);
    cpLayout.ColumnWidth = {'1x','1x'};

    % --- 左侧：主轴控制区域 ---
    spindlePanel = uipanel(cpLayout, 'Title', '主轴');
    spindlePanel.Layout.Row = 1;
    spindlePanel.Layout.Column = 1;
    spindleLayout = uigridlayout(spindlePanel, [2,2]);
    spindleLayout.RowHeight = {'1x','1x'};
    spindleLayout.ColumnWidth = {'1x','1x'};

    btnSpindleOn = uibutton(spindleLayout, 'Text', '主轴上电', 'ButtonPushedFcn', @spindlePowerOnClick);
    btnSpindleOn.Layout.Row = 1;
    btnSpindleOn.Layout.Column = 1;
    btnSpindleOff = uibutton(spindleLayout, 'Text', '主轴下电', 'ButtonPushedFcn', @spindlePowerOffClick);
    btnSpindleOff.Layout.Row = 1;
    btnSpindleOff.Layout.Column = 2;

    lblSpeed = uilabel(spindleLayout, 'Text', '设定转速:');
    lblSpeed.Layout.Row = 2;
    lblSpeed.Layout.Column = 1;
    txtSpeed = uieditfield(spindleLayout, 'numeric', 'Value', targetSpeed, 'ValueChangedFcn', @updateTargetSpeed);
    txtSpeed.ValueDisplayFormat = '%.0f';
    txtSpeed.Layout.Row = 2;
    txtSpeed.Layout.Column = 2;

    % --- 右侧：加速度计控制区域 ---
    accelPanel = uipanel(cpLayout, 'Title', '加速度计');
    accelPanel.Layout.Row = 1;
    accelPanel.Layout.Column = 2;
    accelLayout = uigridlayout(accelPanel, [2,2]);
    accelLayout.RowHeight = {'1x','1x'};
    accelLayout.ColumnWidth = {'1x','1x'};

    btnAccelOn = uibutton(accelLayout, 'Text', '加速度计上电', 'ButtonPushedFcn', @accelPowerOn);
    btnAccelOn.Layout.Row = 1;
    btnAccelOn.Layout.Column = 1;
    btnAccelOff = uibutton(accelLayout, 'Text', '加速度计下电', 'ButtonPushedFcn', @accelPowerOff);
    btnAccelOff.Layout.Row = 1;
    btnAccelOff.Layout.Column = 2;

    lblSamplingRate = uilabel(accelLayout, 'Text', '采样率:');
    lblSamplingRate.Layout.Row = 2;
    lblSamplingRate.Layout.Column = 1;
    txtSamplingRate = uieditfield(accelLayout, 'numeric', 'Value', defaultSamplingRate, 'ValueChangedFcn', @updateSamplingRate);
    txtSamplingRate.ValueDisplayFormat = '%.0f';
    txtSamplingRate.Layout.Row = 2;
    txtSamplingRate.Layout.Column = 2;

    %% 第二行：按钮区域（自定义调速、清空显示、记录数据、监测开启）
    btnLayout = uigridlayout(mainLayout, [1,4]);
    btnLayout.RowHeight = {'1x'};
    btnLayout.ColumnWidth = {'1x','1x','1x','1x'};
    btnLayout.Layout.Row = 2;
    btnLayout.Layout.Column = 1;
    
    customSpeedButton = uibutton(btnLayout, 'Text', '自定义调速开启', 'ButtonPushedFcn', @customSpeedButtonCallback);
    customSpeedButton.Layout.Row = 1;
    customSpeedButton.Layout.Column = 1;
    
    btnClearDisplay = uibutton(btnLayout, 'Text', '清空数据显示', 'ButtonPushedFcn', @clearDisplayCallback);
    btnClearDisplay.Layout.Row = 1;
    btnClearDisplay.Layout.Column = 2;
    
    btnRecord = uibutton(btnLayout, 'Text', '记录数据', 'ButtonPushedFcn', @recordButtonCallback);
    btnRecord.Layout.Row = 1;
    btnRecord.Layout.Column = 3;
    
    btnMonitor = uibutton(btnLayout, 'Text', '监测开启', 'ButtonPushedFcn', @monitorButtonCallback);
    btnMonitor.Layout.Row = 1;
    btnMonitor.Layout.Column = 4;


    %% 第三行：数据展示区域
    displayPanel = uipanel(mainLayout, 'Title', '数据显示');
    displayPanel.Layout.Row = 3;
    displayPanel.Layout.Column = 1;
    displayLayout = uigridlayout(displayPanel, [1,2]);
    displayLayout.ColumnWidth = {'1x','1x'};

    txtSpindleDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'转速显示：'});
    txtSpindleDisplay.Layout.Row = 1;
    txtSpindleDisplay.Layout.Column = 1;
    txtAccelDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'加速度计显示：'});
    txtAccelDisplay.Layout.Row = 1;
    txtAccelDisplay.Layout.Column = 2;

    %% 创建主轴定时器
    spindleTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @spindleTimerFcn);

    %% 窗口关闭回调
    fig.CloseRequestFcn = @(src,event) closeApp();

    %% 回调函数

    % --- 主轴上电回调 ---
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
            % sendSpindleCmd(true);
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

    % --- 主轴下电回调 ---
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

    % --- 更新主轴转速回调 ---
    function updateTargetSpeed(src, ~)
        if isSpindleConnected
            targetSpeed = src.Value;
            sendSpindleCmd();
            prependSpindleDisplay(['更新目标转速为: ' num2str(targetSpeed)]);
        else
            prependSpindleDisplay('主轴未连接，无法更新转速');
        end
    end

    % --- 主轴定时器回调 ---
    function spindleTimerFcn(~, ~)
        if isSpindleConnected
            if ~spindleOffRequested
                data = receiveSpindleData();
                if ~isempty(data)
                    speedVal = parseSpindleData(data);
                    currentSpindleSpeed = speedVal;
                    prependSpindleDisplay(['主轴数据: ' num2str(speedVal)]);
                end
                if isRecording && ~accelRunning
                    t = toc(recordStartTime);
                    newRow = [t, NaN, currentSpindleSpeed];
                    dataLog = [dataLog; newRow];
                end
            else
                sendSpindleCmd(true);
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
    function sendSpindleCmd(noCorrection)
        % 如果未传入参数，则默认使用修正（即noCorrection为false）
        if nargin < 1
            noCorrection = false;
        end
        if isSpindleConnected
            if noCorrection
                % 不修正，直接发送targetSpeed
                cmd = sprintf('!!%05d,%d#', targetSpeed, spindlePowerOn);
            else
                % 使用修正公式： round(targetSpeed*slope+intercept)
                cmd = sprintf('!!%05d,%d#', round(targetSpeed*slope+intercept), spindlePowerOn);
            end
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

    % --- 解析主轴数据 ---
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

    % --- 加速度计上电回调 ---
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
            ch = addinput(accelDAQ, "cDAQ1Mod1", "ai0", "Accelerometer");
            ch.Sensitivity = 0.01000;
            newRate = round(txtSamplingRate.Value);
            accelDAQ.Rate = newRate;
            txtSamplingRate.Value = accelDAQ.Rate;
            accelDAQ.ScansAvailableFcnCount = round(accelDAQ.Rate/10);
            accelDAQ.ScansAvailableFcn = @accelDAQCallback;
            start(accelDAQ, "continuous");
        catch ME
            uialert(fig, ['加速度计配置失败: ' ME.message], '错误');
            return;
        end
        accelRunning = true;
        prependAccelDisplay('加速度计上电，开始连续采集数据...');
    end

    % --- 加速度计下电回调 ---
    function accelPowerOff(~, ~)
        if isempty(accelDAQ) || ~isvalid(accelDAQ) || ~accelDAQ.Running
            uialert(fig, '加速度计已经下电或未在采集数据。', '提示');
            return;
        end
        if isMonitoring
            isMonitoring = false;
            btnMonitor.Text = '监测开启';
            prependAccelDisplay('监测已自动停止（加速度计下电）');
        end
        stop(accelDAQ);
        accelRunning = false;
        prependAccelDisplay('加速度计下电，停止采集数据.');
    end

    % --- 更新采样率回调 ---
    function updateSamplingRate(src, ~)
        newRate = round(src.Value);
        src.Value = newRate;
        if accelRunning && ~isempty(accelDAQ) && isvalid(accelDAQ)
            stop(accelDAQ);
            accelDAQ.Rate = newRate;
            adjustedRate = accelDAQ.Rate;
            src.Value = adjustedRate;
            accelDAQ.ScansAvailableFcnCount = round(adjustedRate/10);
            start(accelDAQ, "continuous");
            prependAccelDisplay(['更新采样率为: ' num2str(adjustedRate)]);
        else
            if ~isempty(accelDAQ) && isvalid(accelDAQ)
                accelDAQ.Rate = newRate;
                src.Value = accelDAQ.Rate;
            end
        end
    end

    % --- 加速度计回调函数 ---
    function accelDAQCallback(src, evt)
        [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        if ~isempty(timestamps) && ~isempty(data)
            latestValue = data(end,1);
            prependAccelDisplay(['采集数据: ' num2str(latestValue)]);
            if isMonitoring
                reportStr = decisionReport(timestamps, data, currentSpindleSpeed, threshold);
                prependAccelDisplay(reportStr);
            end
            if isRecording
                numPoints = length(timestamps);
                newRows = [timestamps, data, repmat(currentSpindleSpeed, numPoints, 1)];
                dataLog = [dataLog; newRows];
            end
        end
    end

    % --- 记录数据按钮回调 ---
    function recordButtonCallback(src, ~)
        if ~(isSpindleConnected || accelRunning)
            uialert(fig, '主轴或加速度计至少一个必须上电', '提示');
            return;
        end
        if ~isRecording
            dataLog = [];
            isRecording = true;
            src.Text = '■';
            recordStartTime = tic;
            prependSpindleDisplay('开始记录数据...');
            prependAccelDisplay('开始记录数据...');
        else
            isRecording = false;
            if ~isempty(dataLog)
                dataLog(:,1) = dataLog(:,1) - dataLog(1,1);
            end
            src.Text = '记录数据';
            assignin('base', 'timestamps', dataLog(:,1));
            assignin('base', 'accX', dataLog(:,2));
            assignin('base', 'spinSpeed', dataLog(:,3));
            [filename, pathname] = uiputfile('*.txt', '保存数据记录为TXT文件');
            if ischar(filename)
                fullpath = fullfile(pathname, filename);
                writematrix(dataLog, fullpath, 'Delimiter', '\t');
            end
            prependAccelDisplay('数据记录停止，数据已保存');
        end
    end

    % --- 监测按钮回调 ---
    function monitorButtonCallback(src, ~)
        if ~accelRunning
            uialert(fig, '加速度计未上电，无法开启监测', '提示');
            return;
        end
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

    % --- 自定义调速按钮回调 ---
    function customSpeedButtonCallback(src, ~)
        if ~isSpindleConnected
            uialert(fig, '主轴未上电，无法开启自定义调速', '提示');
            return;
        end
        if ~isCustomSpeedActive
            isCustomSpeedActive = true;
            src.Text = '■';  % 开启后按钮文字变为停止图标
            customSpeedStartTime = tic;
            customSpeedTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @customSpeedTimerFcn);
            start(customSpeedTimer);
            prependSpindleDisplay('自定义调速已开启');
        else
            isCustomSpeedActive = false;
            src.Text = '自定义调速开启';
            if ~isempty(customSpeedTimer) && isvalid(customSpeedTimer)
                stop(customSpeedTimer);
                delete(customSpeedTimer);
            end
            prependSpindleDisplay('自定义调速已停止');
        end
    end

    function customSpeedTimerFcn(~, ~)
        % 如果主轴已下电，则停止自定义调速，并恢复按钮文本
        if ~isSpindleConnected || spindlePowerOn == 0
            stop(customSpeedTimer);
            delete(customSpeedTimer);
            customSpeedButton.Text = '自定义调速开启';  % 恢复按钮文本
            prependSpindleDisplay('主轴下电，自动停止自定义调速');
            return;
        end

        elapsedTime = toc(customSpeedStartTime);
        newSpeed = customSpeedProfile(elapsedTime);
        if newSpeed ~= targetSpeed
            targetSpeed = newSpeed;
            % 更新文本框的显示
            txtSpeed.Value = targetSpeed;
            sendSpindleCmd();
            prependSpindleDisplay(['自定义调速更新: t = ' num2str(elapsedTime, '%.2f') ' s, 目标转速 = ' num2str(targetSpeed) ' rpm']);
            
            % 如果返回 -1，则停止调速并下电主轴
            if targetSpeed == -1
                stop(customSpeedTimer);
                delete(customSpeedTimer);
                spindlePowerOffClick();  % 调用下电回调函数
                prependSpindleDisplay('调速结束，主轴已下电');
            end
        end
    end


    % --- 自定义调速曲线函数 ---
    function spd = customSpeedProfile(t)
        if t < 10
            spd = 3750;
        elseif t < 20
            spd = 5000;
        elseif t < 30
            spd = 7500;
        else
            spd = 0;  % 返回 -1 表示下电信号
        end
    end


    % --- 决策报告子函数 ---
    function reportStr = decisionReport(t_chunk, acc_chunk, currentSpin, threshold)
        tic;
        [isSafe, prominentFreq, ~, ~] = m060_Decision_fft_filter_report(t_chunk, acc_chunk, currentSpin, threshold);
        processingTime = toc;
        if isSafe
            decisionStr = '稳定';
        else
            decisionStr = '颤振';
        end
        reportStr = sprintf('t = %.3f s: 决策 = %s, 突出频率 = %.2f Hz, 处理时间 = %.4f s', ...
            t_chunk(end), decisionStr, prominentFreq, processingTime);
    end

    % --- 将信息添加到主轴数据展示区 ---
    function prependSpindleDisplay(msg)
        % 将新消息添加到现有消息前面
        newVal = [{msg}; txtSpindleDisplay.Value];
        % 如果总消息数超过200条，则截取前200条（最新的200条消息）
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtSpindleDisplay.Value = newVal;
    end


    % --- 将信息添加到加速度计数据展示区 ---
    function prependAccelDisplay(msg)
        newVal = [{msg}; txtAccelDisplay.Value];
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtAccelDisplay.Value = newVal;
    end

    function clearDisplayCallback(~, ~)
        txtSpindleDisplay.Value = {'转速显示：'};
        txtAccelDisplay.Value = {'加速度计显示：'};
    end


    % --- 清理主轴连接 ---
    function cleanupSpindleConnection()
        if ~isempty(spindleClient)
            clear spindleClient;
            prependSpindleDisplay('主轴连接已清理');
        end
    end

    % --- 窗口关闭回调 ---
    function closeApp()
        if strcmp(spindleTimer.Running, 'on')
            stop(spindleTimer);
        end
        if ~isempty(customSpeedTimer) && isvalid(customSpeedTimer)
            stop(customSpeedTimer);
            delete(customSpeedTimer);
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
