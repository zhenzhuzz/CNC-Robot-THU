function m057_adjust_elements_postion_04()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 综合控制面板
%
% 说明：
%   此程序将原有的主轴控制、加速度计控制以及ABB机器人控制分别
%   放入三个并列的面板中，形成上半部分的三列控制区；下半部分为全局
%   控制按钮和数据显示区（显示主轴与加速度计的数据）。
%
% 作者：Zhen Zhu（整合示例）
% 日期：Every day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %% ------------------------- 加载动态库 --------------------------------
    try
        NET.addAssembly('C:\Program Files (x86)\ABB\SDK\PCSDK 2025\ABB.Robotics.Controllers.PC.dll');
    catch ME
        uialert(mainFig, ['加载DLL失败: ' ME.message], '错误');
    end
    import ABB.Robotics.Controllers.*;
    import ABB.Robotics.Controllers.Discovery.*;
    import ABB.Robotics.Controllers.RapidDomain.*;

    %% ------------------------- 参数初始化 --------------------------------
    % --- 主轴参数 ---
    spindleIP = "127.0.0.1";                % 主轴的 IP 地址
    spindlePort = 2000;                     % 主轴通信端口
    spindleClient = [];
    isSpindleConnected = false;
    targetSpeed = 0;
    spindlePowerOn = 1;
    spindleOffRequested = false;
    spindleOffCounter = 0;
    spindleOffThreshold = 5;
    
    % --- 加速度计参数 ---
    accelDAQ = [];
    accelRunning = false;
    defaultSamplingRate = 12800;
    threshold = 0.5;
    
    % --- 数据记录相关 ---
    isRecording = false;
    dataLog = [];
    recordStartTime = [];
    
    % --- 监测状态 ---
    isMonitoring = false;
    currentSpindleSpeed = NaN;
    
    % --- 自定义调速 ---
    isCustomSpeedActive = false;
    customSpeedTimer = [];
    customSpeedStartTime = [];
    
    % --- 转速修正系数 ---
    slope = 0.867785714285714;
    intercept = 17.7714285714283;
    
    %% -------------------- 定义全局共享变量 -------------------------------
    % 用于主轴与加速度计控件的句柄
    txtSpeed = [];
    txtSamplingRate = [];
    % 用于ABB控制面板的控件与数据
    abbTable = [];
    abbMsgArea = [];
    abbPanel = [];
    controllersABB = [];
    controllerABB = [];
    
    % 定时器变量预先定义，避免后续回调中未定义的问题
    spindleTimer = [];
    
    %% ------------------------- 创建主窗口 --------------------------------
    mainFig = uifigure('Name', '主轴与加速度计以及ABB机器人控制', 'Position', [100 50 1400 800]);
    mainFig.CloseRequestFcn = @(src,event) closeApp();
    
    % 主布局：2 行 1 列
    mainGrid = uigridlayout(mainFig, [2,1]);
    % 顶部面板固定 150 像素高度，底部自适应填满剩余区域
    mainGrid.RowHeight = {350, '1x'};
    
    %% ------------------ 上半部分：三个功能控制面板 ------------------------
    topGrid = uigridlayout(mainGrid, [1,3]);
    topGrid.Layout.Row = 1; 
    topGrid.Layout.Column = 1;
    
    % 面板1：主轴控制
    panelSpindle = uipanel(topGrid, 'Title', '主轴控制');
    % 面板2：加速度计控制
    panelAccel = uipanel(topGrid, 'Title', '加速度计控制');
    % 面板3：ABB机器人控制
    panelABB = uipanel(topGrid, 'Title', 'ABB机器人控制');
    
    % 分别在各自面板中创建控件
    createSpindleControl(panelSpindle);
    createAccelControl(panelAccel);
    createABBControlPanel(panelABB);
    
    %% --------------- 下半部分：全局控制按钮及数据显示区 --------------------
    globalPanel = uipanel(mainGrid, 'Title', '数据显示及全局控制');
    globalPanel.Layout.Row = 2; 
    globalPanel.Layout.Column = 1;
    
    % 在 globalPanel 内部分为2行：第一行为按钮区，第二行为数据显示区
    globalGrid = uigridlayout(globalPanel, [2,1]);
    % 将按钮区固定为 60 像素高度，数据显示区固定为 160 像素高度
    globalGrid.RowHeight = {60, 260};
    
    % 第一行：全局按钮区域改为 1 行 6 列
    btnGrid = uigridlayout(globalGrid, [1,6]);
    btnGrid.Layout.Row = 1; 
    btnGrid.Layout.Column = 1;
    customSpeedButton = uibutton(btnGrid, 'Text', '自定义调速开启', 'ButtonPushedFcn', @customSpeedButtonCallback);
    btnClearDisplay = uibutton(btnGrid, 'Text', '清空数据显示', 'ButtonPushedFcn', @clearDisplayCallback);
    btnRecord = uibutton(btnGrid, 'Text', '记录数据', 'ButtonPushedFcn', @recordButtonCallback);
    btnMonitor = uibutton(btnGrid, 'Text', '监测开启', 'ButtonPushedFcn', @monitorButtonCallback);
    btnPPtoMain = uibutton(btnGrid, 'Text', 'PPtoMain', 'ButtonPushedFcn', @PPtoMainABB);
    txtGlobalSpeed = uieditfield(btnGrid, 'numeric', 'Value', 100, 'ValueChangedFcn', @speedEditCallbackABB);
    txtGlobalSpeed.ValueDisplayFormat = '%.0f';
    
    % 第二行：显示区，改为 1 行 3 列（转速显示、加速度计显示、ABB机器人状态显示）
    displayGrid = uigridlayout(globalGrid, [1,3]);
    displayGrid.Layout.Row = 2; 
    displayGrid.Layout.Column = 1;
    displayGrid.RowHeight = {'1x'};
    displayGrid.ColumnWidth = {'1x','1x','1x'};
    txtSpindleDisplay    = uitextarea(displayGrid, 'Editable', 'off', 'Value', {'转速显示：'});
    txtAccelDisplay      = uitextarea(displayGrid, 'Editable', 'off', 'Value', {'加速度计显示：'});
    txtABBStatusDisplay  = uitextarea(displayGrid, 'Editable', 'off', 'Value', {'ABB机器人状态显示：'});
    
    %% ------------------------- 定时器初始化 ------------------------------
    spindleTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @spindleTimerFcn);
    
    %% ------------------------- GUI函数定义 -------------------------------
    % ----- 在指定面板中创建主轴控制区 -----
    function createSpindleControl(parentPanel)
        spGrid = uigridlayout(parentPanel, [1,1]);
        spGrid.RowHeight = {'1x'};
        spControl = uigridlayout(spGrid, [1,3]);
        spControl.RowHeight = {'1x'};
        uibutton(spControl, 'Text', '主轴上电', 'ButtonPushedFcn', @spindlePowerOnClick);
        uibutton(spControl, 'Text', '主轴下电', 'ButtonPushedFcn', @spindlePowerOffClick);
        txtSpeed = uieditfield(spControl, 'numeric', 'Value', targetSpeed, 'ValueChangedFcn', @updateTargetSpeed);
        txtSpeed.ValueDisplayFormat = '%.0f';
    end

    % --- 在指定面板中创建加速度计控制区 ---
    function createAccelControl(parentPanel)
        acGrid = uigridlayout(parentPanel, [1,1]);
        acGrid.RowHeight = {'1x'};
        acControl = uigridlayout(acGrid, [1,3]);
        acControl.RowHeight = {'1x'};
        uibutton(acControl, 'Text', '加速度计上电', 'ButtonPushedFcn', @accelPowerOn);
        uibutton(acControl, 'Text', '加速度计下电', 'ButtonPushedFcn', @accelPowerOff);
        txtSamplingRate = uieditfield(acControl, 'numeric', 'Value', defaultSamplingRate, 'ValueChangedFcn', @updateSamplingRate);
        txtSamplingRate.ValueDisplayFormat = '%.0f';
    end

    % ----- 在指定面板中创建ABB机器人控制区 -----
    function createABBControlPanel(parentPanel)
        abbPanel = parentPanel;
        abbLayout = uigridlayout(parentPanel, [7,2]);
        abbLayout.RowHeight = {40, 40, 80, 40, 40, 40, '1x'};
        abbLayout.ColumnWidth = {'1x','1x'};
        
        btnRefreshABB = uibutton(abbLayout, 'Text', 'Refresh', 'ButtonPushedFcn', @refreshScanABB);
        btnRefreshABB.Layout.Row = 1; btnRefreshABB.Layout.Column = 1;
        btnConnectABB = uibutton(abbLayout, 'Text', 'Connect', 'ButtonPushedFcn', @connectControllerABB);
        btnConnectABB.Layout.Row = 1; btnConnectABB.Layout.Column = 2;
        
        abbTable = uitable(abbLayout, 'ColumnName', {'IP Address','System Name','Availability'});
        abbTable.Layout.Row = [2 3]; abbTable.Layout.Column = [1 2];
        
        hPowerOnABB = uibutton(abbLayout, 'Text', 'ABB机器人上电', 'ButtonPushedFcn', @powerOnABB);
        hPowerOnABB.Layout.Row = 4; hPowerOnABB.Layout.Column = 1;
        hPowerOffABB = uibutton(abbLayout, 'Text', 'ABB机器人下电', 'ButtonPushedFcn', @powerOffABB);
        hPowerOffABB.Layout.Row = 4; hPowerOffABB.Layout.Column = 2;
        
        hStartABB = uibutton(abbLayout, 'Text', '▶', 'ButtonPushedFcn', @startABB);
        hStartABB.Layout.Row = 5; hStartABB.Layout.Column = 1;
        hStopABB = uibutton(abbLayout, 'Text', '■', 'ButtonPushedFcn', @stopABB);
        hStopABB.Layout.Row = 5; hStopABB.Layout.Column = 2;
        
        abbMsgArea = uitextarea(abbLayout, 'Editable', 'off', 'Value', {'ABB消息显示：'});
        abbMsgArea.Layout.Row = 7; abbMsgArea.Layout.Column = [1 2];
    end

    %% ---------------------- 回调函数定义 ------------------------------
    % ----- 主轴相关回调函数 -----
    function spindlePowerOnClick(~, ~)
        if ~isSpindleConnected
            try
                spindleClient = tcpclient(spindleIP, spindlePort);
            catch ME
                uialert(mainFig, ['主轴连接失败: ' ME.message], '错误');
                return;
            end
            isSpindleConnected = true;
            spindlePowerOn = 1;
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

    function spindlePowerOffClick(~, ~)
        if isSpindleConnected
            targetSpeed = 0;
            spindlePowerOn = 0;
            spindleOffRequested = true;
            spindleOffCounter = 0;
            prependSpindleDisplay('主轴下电请求已发出，等待主轴确认停机');
        else
            prependSpindleDisplay('主轴未连接，无法执行下电操作');
        end
    end

    function updateTargetSpeed(src, ~)
        if isSpindleConnected
            targetSpeed = src.Value;
            sendSpindleCmd();
            prependSpindleDisplay(['更新目标转速为: ' num2str(targetSpeed)]);
        else
            prependSpindleDisplay('主轴未连接，无法更新转速');
        end
    end

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

    function sendSpindleCmd(noCorrection)
        if nargin < 1
            noCorrection = false;
        end
        if isSpindleConnected
            if noCorrection
                cmd = sprintf('!!%05d,%d#', targetSpeed, spindlePowerOn);
            else
                cmd = sprintf('!!%05d,%d#', round(targetSpeed*slope+intercept), spindlePowerOn);
            end
            write(spindleClient, unicode2native(cmd, 'UTF-8'));
        end
    end

    function data = receiveSpindleData()
        if isSpindleConnected && spindleClient.NumBytesAvailable > 0
            data = char(read(spindleClient, spindleClient.NumBytesAvailable));
        else
            data = '';
        end
    end

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

    % ----- 加速度计相关回调函数 -----
    function accelPowerOn(~, ~)
        if accelRunning
            uialert(mainFig, '加速度计已上电，正在采集数据。', '提示');
            return;
        end
        try
            accelDAQ = daq("ni");
        catch ME
            uialert(mainFig, ['无法创建DAQ对象: ' ME.message], '错误');
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
            uialert(mainFig, ['加速度计配置失败: ' ME.message], '错误');
            return;
        end
        accelRunning = true;
        prependAccelDisplay('加速度计上电，开始连续采集数据...');
    end

    function accelPowerOff(~, ~)
        if isempty(accelDAQ) || ~isvalid(accelDAQ) || ~accelDAQ.Running
            uialert(mainFig, '加速度计已经下电或未在采集数据。', '提示');
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

    % ----- 全局控制按钮回调 -----
    function recordButtonCallback(src, ~)
        if ~(isSpindleConnected || accelRunning)
            uialert(mainFig, '主轴或加速度计至少一个必须上电', '提示');
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
                % 时间戳归一化，让第一条数据时间从 0 开始
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

    function monitorButtonCallback(src, ~)
        if ~accelRunning
            uialert(mainFig, '加速度计未上电，无法开启监测', '提示');
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

    function customSpeedButtonCallback(src, ~)
        if ~isSpindleConnected
            uialert(mainFig, '主轴未上电，无法开启自定义调速', '提示');
            return;
        end
        if ~isCustomSpeedActive
            isCustomSpeedActive = true;
            src.Text = '■';  % 显示停止图标
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
        if ~isSpindleConnected || spindlePowerOn == 0
            stop(customSpeedTimer);
            delete(customSpeedTimer);
            customSpeedButton.Text = '自定义调速开启';
            prependSpindleDisplay('主轴下电，自动停止自定义调速');
            return;
        end
        elapsedTime = toc(customSpeedStartTime);
        newSpeed = customSpeedProfile(elapsedTime);
        if newSpeed ~= targetSpeed
            targetSpeed = newSpeed;
            txtSpeed.Value = targetSpeed;
            sendSpindleCmd();
            prependSpindleDisplay(['自定义调速更新: t = ' num2str(elapsedTime, '%.2f') ' s, 目标转速 = ' num2str(targetSpeed) ' rpm']);
            if targetSpeed == -1
                stop(customSpeedTimer);
                delete(customSpeedTimer);
                spindlePowerOffClick();
                prependSpindleDisplay('调速结束，主轴已下电');
            end
        end
    end

    function spd = customSpeedProfile(t)
        if t < 10
            spd = 3750;
        elseif t < 20
            spd = 7500;
        elseif t < 30
            spd = 10000;
        else
            spd = -1;  % 返回 -1 作为下电信号
        end
    end

    function reportStr = decisionReport(t_chunk, acc_chunk, currentSpin, threshold)
        tic;
        [isSafe, prominentFreq, ~, ~] = f060_Decision_fft_filter_report(t_chunk, acc_chunk, currentSpin, threshold);
        processingTime = toc;
        if isSafe
            decisionStr = '稳定';
        else
            decisionStr = '颤振';
        end
        reportStr = sprintf('t = %.3f s: 决策 = %s, 突出频率 = %.2f Hz, 处理时间 = %.4f s', ...
            t_chunk(end), decisionStr, prominentFreq, processingTime);
    end

    function prependSpindleDisplay(msg)
        newVal = [{msg}; txtSpindleDisplay.Value];
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtSpindleDisplay.Value = newVal;
    end

    function prependAccelDisplay(msg)
        newVal = [{msg}; txtAccelDisplay.Value];
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtAccelDisplay.Value = newVal;
    end

    function cleanupSpindleConnection()
        if ~isempty(spindleClient)
            clear spindleClient;
            prependSpindleDisplay('主轴连接已清理');
        end
    end

    function clearDisplayCallback(~, ~)
        txtSpindleDisplay.Value = {'转速显示：'};
        txtAccelDisplay.Value = {'加速度计显示：'};
        txtABBStatusDisplay.Value = {'ABB机器人状态显示：'};
    end

    function closeApp()
        % 判断变量是否存在再调用，防止未定义错误
        if exist('spindleTimer','var') && ~isempty(spindleTimer) && strcmp(spindleTimer.Running, 'on')
            stop(spindleTimer);
        end
        if exist('customSpeedTimer','var') && ~isempty(customSpeedTimer) && isvalid(customSpeedTimer)
            stop(customSpeedTimer);
            delete(customSpeedTimer);
        end
        if exist('spindleTimer','var') && ~isempty(spindleTimer)
            delete(spindleTimer);
        end
        if isSpindleConnected
            sendSpindleCmd();
            clear spindleClient;
            prependSpindleDisplay('主轴连接关闭，程序结束');
        end
        if accelRunning && ~isempty(accelDAQ) && isvalid(accelDAQ)
            stop(accelDAQ);
        end
        isRecording = false;
        delete(mainFig);
    end

    % --- ABB相关回调函数 ----
    function refreshScanABB(~,~)
        try
            scanner = Discovery.NetworkScanner();
            scanner.Scan();
            controllersABB = scanner.Controllers;
            n = controllersABB.Count;
            if n == 0
                abbTable.Data = {};
                abbMsg('No ABB controllers found!');
            else
                dataCell = cell(n,3);
                for i = 1:n
                    info = controllersABB.Item(i-1);
                    dataCell{i,1} = char(info.IPAddress.ToString());
                    dataCell{i,2} = char(info.SystemName);
                    dataCell{i,3} = char(info.Availability.ToString());
                end
                abbTable.Data = dataCell;
                abbMsg(['扫描到 ' num2str(n) ' 个控制器']);
            end
        catch ME
            abbMsg(['Scan error: ' ME.message]);
        end
    end

    function connectControllerABB(~,~)
        if isempty(abbTable.Data)
            uialert(mainFig, '请先刷新扫描！', 'Alert');
            prependABBStatusDisplay('请先刷新扫描！');
            return;
        end
        sel = abbTable.Selection;
        if isempty(sel)
            uialert(mainFig, '请先选择一行！', 'Alert');
            prependABBStatusDisplay('请先选择一行！');
            return;
        end
        rowIdx = sel(1);
        info = controllersABB.Item(rowIdx-1);
        if info.Availability == ABB.Robotics.Controllers.Availability.Available
            if ~isempty(controllerABB)
                controllerABB.Logoff();
                controllerABB.Dispose();
                controllerABB = [];
            end
            controllerABB = ABB.Robotics.Controllers.ControllerFactory.CreateFrom(info);
            controllerABB.Logon(ABB.Robotics.Controllers.UserInfo.DefaultUser);
            uialert(mainFig, ['已登录: ' char(info.SystemName)], 'Success');
            abbMsg(['已登录控制器: ' char(info.SystemName)]);
        else
            uialert(mainFig, '选中的控制器不可用或已被占用！', 'Alert');
            prependABBStatusDisplay('选中的控制器不可用或已被占用！');
        end
    end

    function powerOnABB(~,~)
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                controllerABB.State = ABB.Robotics.Controllers.ControllerState.MotorsOn;
                abbMsg('成功上电');
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['错误: ' ME.message]);
        end
    end

    function powerOffABB(~,~)
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                controllerABB.State = ABB.Robotics.Controllers.ControllerState.MotorsOff;
                abbMsg('成功下电');
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['错误: ' ME.message]);
        end
    end

    function PPtoMainABB(~,~)
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                tasks = controllerABB.Rapid.GetTasks();
                master = ABB.Robotics.Controllers.Mastership.Request(controllerABB.Rapid);
                try
                    tasks(1).ResetProgramPointer();
                    abbMsg('程序指针已复位');
                catch ME
                    master.Dispose();
                    rethrow(ME);
                end
                master.Dispose();
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['错误: ' ME.message]);
        end
    end

    function startABB(~,~)
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                master = ABB.Robotics.Controllers.Mastership.Request(controllerABB.Rapid);
                try
                    result = controllerABB.Rapid.Start();
                    abbMsg(['程序启动, 状态: ' char(result.ToString())]);
                catch ME
                    master.Dispose();
                    rethrow(ME);
                end
                master.Dispose();
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['错误: ' ME.message]);
        end
    end

    function stopABB(~,~)
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                master = ABB.Robotics.Controllers.Mastership.Request(controllerABB.Rapid);
                try
                    controllerABB.Rapid.Stop(StopMode.Immediate);
                    abbMsg('程序停止');
                catch ME
                    master.Dispose();
                    rethrow(ME);
                end
                master.Dispose();
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['错误: ' ME.message]);
        end
    end

    function speedEditCallbackABB(src, ~)
        % 直接获取数值，无需转换字符串
        speedVal = src.Value;
        
        % 检查数值有效性和范围
        if isnan(speedVal)
            abbMsg('请输入有效的数值(0~100)');
            return;
        end
        if speedVal < 0 || speedVal > 100
            abbMsg('速度范围应在0~100之间');
            return;
        end
        
        try
            % 设置机器人速度
            controllerABB.MotionSystem.SpeedRatio = int32(speedVal);
            % 更新标签
            set(txtGlobalSpeed, 'Value', speedVal);
            abbMsg(['速度已设置为 ' num2str(speedVal) '%']);
        catch ME
            abbMsg(['设置速度时出错: ' ME.message]);
        end
    end

    % 修改后的 abbMsg 函数：同时更新ABB控制面板与全局状态显示区
    function abbMsg(msg)
        abbMsgArea.Value = [abbMsgArea.Value; {msg}];
        prependABBStatusDisplay(msg);
    end

    function prependABBStatusDisplay(msg)
        newVal = [{msg}; txtABBStatusDisplay.Value];
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtABBStatusDisplay.Value = newVal;
    end

end
