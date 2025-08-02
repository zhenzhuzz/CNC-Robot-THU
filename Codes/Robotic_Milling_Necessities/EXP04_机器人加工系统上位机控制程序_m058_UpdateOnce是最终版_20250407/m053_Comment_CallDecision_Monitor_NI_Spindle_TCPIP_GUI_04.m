%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m053_Comment_CallDecision_Monitor_NI_Spindle_TCPIP_GUI_04.m
%
% 说明：
%   本程序实现了主轴与加速度计的联合控制及数据监测、记录功能，主要包括：
%
%   1. 主轴控制（通过 TCP/IP 通讯）：
%       - 主轴上电、下电
%       - 设置主轴转速
%       - 通过定时器实时接收主轴数据，并显示在 GUI 中
%
%   2. 加速度计控制（使用 NI DAQ）：
%       - 加速度计上电、下电
%       - 设定采样率（采样率会由 NI 采集卡自动校正，显示为DAQ实际使用的值）
%
%   3. 数据记录与监测：
%       - 数据记录：将加速度计采集到的 timestamp、加速度数据和主轴转速组合成一个三列矩阵进行记录，
%         记录数据结束后自动将 timestamps 调整为从 0 开始，并将记录保存到工作区（同时弹出对话框保存为 TXT 文件）。
%       - 监测：当监测开启时，每次加速度计采集到数据时调用决策函数 m060_Decision_fft_filter_report，
%         并将决策结果（例如：稳定/颤振、突出频率、处理时间等）以报告形式显示在加速度计数据展示区。
%
%   4. 其他：
%       - 当加速度计下电时，监测自动停止，监测按钮文本也恢复为“监测开启”。
%       - 界面包括三个区域：控制面板（主轴和加速度计控制），记录/监测按钮区，以及数据展示区。
%
% 使用说明：
%   1. 启动程序后，通过 GUI 控制面板进行主轴和加速度计的上电操作。
%   2. 根据需要设置主轴转速和加速度计采样率（采样率会自动由 NI DAQ 校正）。
%   3. 点击“记录数据”按钮开始记录数据，再次点击结束记录，数据会保存至工作区并弹出对话框保存为 TXT 文件。
%   4. 点击“监测开启”按钮开始监测，此时每次采集到加速度数据后，程序会调用决策函数并在加速度计显示区输出报告。
%
% 作者：Zhen Zhu
% 日期：Every day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function m053_Comment_CallDecision_Monitor_NI_Spindle_TCPIP_GUI_04()
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
    % 阈值直接在初始化参数中设定（无需用户输入）
    threshold = 1;                          % 决策函数阈值

    % --- 数据记录相关参数 ---
    isRecording = false;                    % 数据记录状态标志
    % dataLog 记录矩阵，包含三列：
    % 第一列： NI DAQ 返回的 timestamp
    % 第二列： 加速度数据
    % 第三列： 主轴转速
    dataLog = [];
    
    % 记录开始时间（用于主轴单独上电时生成时间戳）
    recordStartTime = [];
    
    % 监测状态变量（监测开启后每次采集时调用决策函数）
    isMonitoring = false;
    
    % 全局保存最新主轴转速，用于数据记录和显示
    currentSpindleSpeed = NaN;

    %% 创建 GUI 界面

    % 创建主窗体，并设置标题和位置
    fig = uifigure('Name', '主轴与加速度计控制面板', 'Position', [300 100 800 700]);

    % 设置主界面的布局，共分为三行：
    % 第一行：控制面板（主轴和加速度计控制区域）
    % 第二行：记录与监测按钮区
    % 第三行：数据展示区
    mainLayout = uigridlayout(fig, [3,1]);
    mainLayout.RowHeight = {'0.8x','0.2x','2x'};

    %% 第一行：控制面板区域（左右分栏）

    % 创建控制面板，并在其中设置左右两列布局
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

    % 主轴上电按钮
    btnSpindleOn = uibutton(spindleLayout, 'Text', '主轴上电', 'ButtonPushedFcn', @spindlePowerOnClick);
    btnSpindleOn.Layout.Row = 1;
    btnSpindleOn.Layout.Column = 1;
    % 主轴下电按钮
    btnSpindleOff = uibutton(spindleLayout, 'Text', '主轴下电', 'ButtonPushedFcn', @spindlePowerOffClick);
    btnSpindleOff.Layout.Row = 1;
    btnSpindleOff.Layout.Column = 2;

    % 主轴转速标签和输入框
    lblSpeed = uilabel(spindleLayout, 'Text', '设定转速:');
    lblSpeed.Layout.Row = 2;
    lblSpeed.Layout.Column = 1;
    txtSpeed = uieditfield(spindleLayout, 'numeric', 'Value', targetSpeed, 'ValueChangedFcn', @updateTargetSpeed);
    txtSpeed.Layout.Row = 2;
    txtSpeed.Layout.Column = 2;

    % --- 右侧：加速度计控制区域 ---
    % 采用2行2列的布局：
    % 第一行放加速度计上电和下电按钮，
    % 第二行放采样率标签与输入框
    accelPanel = uipanel(cpLayout, 'Title', '加速度计');
    accelPanel.Layout.Row = 1;
    accelPanel.Layout.Column = 2;
    accelLayout = uigridlayout(accelPanel, [2,2]);
    accelLayout.RowHeight = {'1x','1x'};
    accelLayout.ColumnWidth = {'1x','1x'};
    
    % 加速度计上电按钮
    btnAccelOn = uibutton(accelLayout, 'Text', '加速度计上电', 'ButtonPushedFcn', @accelPowerOn);
    btnAccelOn.Layout.Row = 1;
    btnAccelOn.Layout.Column = 1;
    % 加速度计下电按钮
    btnAccelOff = uibutton(accelLayout, 'Text', '加速度计下电', 'ButtonPushedFcn', @accelPowerOff);
    btnAccelOff.Layout.Row = 1;
    btnAccelOff.Layout.Column = 2;
    
    % 采样率标签和输入框
    lblSamplingRate = uilabel(accelLayout, 'Text', '采样率:');
    lblSamplingRate.Layout.Row = 2;
    lblSamplingRate.Layout.Column = 1;
    txtSamplingRate = uieditfield(accelLayout, 'numeric', 'Value', defaultSamplingRate, 'ValueChangedFcn', @updateSamplingRate);
    txtSamplingRate.ValueDisplayFormat = '%.0f';
    txtSamplingRate.Layout.Row = 2;
    txtSamplingRate.Layout.Column = 2;

    %% 第二行：记录和监测按钮区域

    % 创建一个包含两个按钮的布局，分别为记录数据和监测按钮
    recordLayout = uigridlayout(mainLayout, [1,2]);
    recordLayout.RowHeight = {'1x'};
    recordLayout.ColumnWidth = {'1x','1x'};
    recordLayout.Layout.Row = 2;
    recordLayout.Layout.Column = 1;
    
    % 记录数据按钮
    btnRecord = uibutton(recordLayout, 'Text', '记录数据', 'ButtonPushedFcn', @recordButtonCallback);
    % 监测按钮
    btnMonitor = uibutton(recordLayout, 'Text', '监测开启', 'ButtonPushedFcn', @monitorButtonCallback);

    %% 第三行：数据展示区域

    % 创建数据展示区域，并分为左右两部分：
    % 左侧用于显示主轴数据，右侧用于显示加速度计数据（含监测报告）
    displayPanel = uipanel(mainLayout, 'Title', '数据展示');
    displayPanel.Layout.Row = 3;
    displayPanel.Layout.Column = 1;
    displayLayout = uigridlayout(displayPanel, [1,2]);
    displayLayout.ColumnWidth = {'1x','1x'};

    % 主轴数据展示区
    txtSpindleDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'转速显示：'});
    txtSpindleDisplay.Layout.Row = 1;
    txtSpindleDisplay.Layout.Column = 1;
    % 加速度计数据展示区
    txtAccelDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'加速度计显示：'});
    txtAccelDisplay.Layout.Row = 1;
    txtAccelDisplay.Layout.Column = 2;

    %% 创建主轴定时器
    % 定时器用于周期性接收主轴数据（每0.1秒）
    spindleTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @spindleTimerFcn);

    %% 窗口关闭回调
    % 关闭窗口时停止定时器和DAQ，清理连接
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
            % 上电后发送复位命令
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
                % 接收主轴数据
                data = receiveSpindleData();
                if ~isempty(data)
                    speedVal = parseSpindleData(data);
                    currentSpindleSpeed = speedVal;  % 更新主轴转速变量
                    prependSpindleDisplay(['主轴数据: ' num2str(speedVal)]);
                end
                % 若加速度计未上电但记录开启，生成主轴数据的时间戳
                if isRecording && ~accelRunning
                    t = toc(recordStartTime);
                    newRow = [t, NaN, currentSpindleSpeed];
                    dataLog = [dataLog; newRow];
                end
            else
                % 如果处于下电请求状态，持续发送停机命令
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
            % 格式化命令字符串，包含转速和上电状态
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

    % --- 解析主轴数据 ---
    function speedVal = parseSpindleData(data)
        % 将收到的数据以 '#' 分割，并取倒数第二个完整消息
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
            % 创建 NI DAQ 对象
            accelDAQ = daq("ni");
        catch ME
            uialert(fig, ['无法创建DAQ对象: ' ME.message], '错误');
            return;
        end
        try
            % 添加加速度计输入通道（请根据实际设备修改设备ID和通道）
            ch = addinput(accelDAQ, "cDAQ1Mod1", "ai0", "Accelerometer");
            ch.Sensitivity = 0.01000;  % 设置灵敏度
            % 直接取采样率输入框中的值，NI 采集卡会自动调整
            newRate = round(txtSamplingRate.Value);
            accelDAQ.Rate = newRate;
            % 更新文本框显示为DAQ实际使用的采样率
            txtSamplingRate.Value = accelDAQ.Rate;
            % 设置每0.1秒触发一次回调（采样点数自动计算）
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
        % 当加速度计下电时，如果监测处于开启状态，则自动停止监测，并更新监测按钮文本
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
        % 获取用户输入的新采样率
        newRate = round(src.Value);
        src.Value = newRate;
        if accelRunning && ~isempty(accelDAQ) && isvalid(accelDAQ)
            stop(accelDAQ);
            % 将新采样率赋值给DAQ对象，DAQ会自动调整为硬件允许的值
            accelDAQ.Rate = newRate;
            % 读取DAQ实际使用的采样率，并更新文本框
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
        % 读取当前回调周期内的数据（例如0.1秒内约1280个采样点）
        [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        if ~isempty(timestamps) && ~isempty(data)
            % 显示当前回调周期内最新的采样点数据
            latestValue = data(end,1);
            prependAccelDisplay(['采集数据: ' num2str(latestValue)]);
            % 如果监测开启，则调用决策报告子函数
            if isMonitoring
                % 传入当前回调的时间戳、加速度数据、当前主轴转速及阈值
                reportStr = decisionReport(timestamps, data, currentSpindleSpeed, threshold);
                prependAccelDisplay(reportStr);
            end
            % 如果记录数据开启，则将本次采集到的数据全部保存到 dataLog 中
            if isRecording
                numPoints = length(timestamps);
                newRows = [timestamps, data, repmat(currentSpindleSpeed, numPoints, 1)];
                dataLog = [dataLog; newRows];
            end
        end
    end

    % --- 记录数据按钮回调 ---
    function recordButtonCallback(src, ~)
        % 只要主轴或加速度计任一上电即可启用记录
        if ~(isSpindleConnected || accelRunning)
            uialert(fig, '主轴或加速度计至少一个必须上电', '提示');
            return;
        end
        if ~isRecording
            dataLog = [];              % 清空旧记录数据
            isRecording = true;
            src.Text = '■';
            recordStartTime = tic;     % 记录开始时间，用于生成主轴单独数据的时间戳
            prependSpindleDisplay('开始记录数据...');
            prependAccelDisplay('开始记录数据...');
        else
            isRecording = false;
            % 调整记录数据的时间戳，使其以0为起点
            if ~isempty(dataLog)
                dataLog(:,1) = dataLog(:,1) - dataLog(1,1);
            end
            src.Text = '记录数据';
            % 分别保存 timestamps, accX, spinSpeed 到工作区
            assignin('base', 'timestamps', dataLog(:,1));
            assignin('base', 'accX', dataLog(:,2));
            assignin('base', 'spinSpeed', dataLog(:,3));
            % 弹出文件保存对话框，将 dataLog 保存为 TXT 文件（无表头）
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

    % --- 决策报告子函数 ---
    function reportStr = decisionReport(t_chunk, acc_chunk, currentSpin, threshold)
        % 测量决策函数调用时间
        tic;
        [isSafe, prominentFreq, f, X_f_filtered] = m060_Decision_fft_filter_report(t_chunk, acc_chunk, currentSpin, threshold);
        processingTime = toc;
        % 根据决策结果生成决策字符串
        if isSafe
            decisionStr = '稳定';
        else
            decisionStr = '颤振';
        end
        % 构造报告字符串，包含最新的时间戳、决策、突出频率以及处理时间
        reportStr = sprintf('t = %.3f s: 决策 = %s, 突出频率 = %.2f Hz, 处理时间 = %.4f s', ...
            t_chunk(end), decisionStr, prominentFreq, processingTime);
    end

    % --- 将信息添加到主轴数据展示区 ---
    function prependSpindleDisplay(msg)
        txtSpindleDisplay.Value = [{msg}; txtSpindleDisplay.Value];
    end

    % --- 将信息添加到加速度计数据展示区 ---
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

    % --- 窗口关闭回调 ---
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
