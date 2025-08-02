%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% m058_UpdateOnce_accXYZ_ABBcontrol_NI_Spindle_TCPIP_GUI_04.m
% 作者：Zhen Zhu
% 源代码github仓库：Every day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function m060_Align_msg_accXYZ_ABBcontrol_NI_Spindle_TCPIP_GUI_05()
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
    threshold = 0.15;                        % 决策函数阈值

    % --- 数据记录相关参数 ---
    isRecording = false;                    % 数据记录状态标志
    dataLog = [];                           % 记录数据矩阵（timestamp, 加速度, 主轴转速）
    recordStartTime = [];                   % 记录开始时间

    % 用于存储消息的全局变量
    isRecordingMessages = false;  % 用于标识是否开始记录消息

    % 在脚本开头，声明一个全局 struct 数组
    messageLog = struct( ...
        'time',       {}, ... % 时间戳 / timestamp
        'spindleMsg', {}, ... % 主轴消息 / spindle message
        'accelMsg',   {}, ... % 加速度计消息 / accel message
        'robotMsg',   {}  ... % 机器人消息 / robot message
    );

    % 用于记录消息的三个数组
    spindleMessages = {};  % 存储主轴消息
    accelMessages = {};    % 存储加速度计消息
    robotMessages = {};    % 存储机器人消息

    % --- 监测状态变量 ---
    isMonitoring = false;
    currentSpindleSpeed = NaN;              % 当前主轴转速

    % --- 抑制状态变量 ---
    isSuppressActive = false;
    isFirstUpdate = true;  % 用来标记是否是第一次更新转速
    lastTargetSpeed = NaN;  % 初始化为 NaN


    % --- 自定义调速相关参数 ---
    isCustomSpeedActive = false;
    customSpeedTimer = [];
    customSpeedStartTime = [];

    % --- 转速拟合修正系数 ---
    slope = 0.867785714285714;
    intercept = 17.7714285714283;
    
    %% 创建 GUI 界面
    
    % 创建主窗体，并设置标题和位置
    fig = uifigure('Name', '主轴&加速度计&ABB机器人控制面板', 'Position', [300 100 850 700]);
    
    % 主界面布局：共3行
    % 第1行：控制面板（主轴、加速度计、ABB机器人）
    % 第2行：按钮区域（包括机器人连接相关按钮）
    % 第3行：数据显示区域（增加机器人状态显示）
    mainLayout = uigridlayout(fig, [3,1]);
    mainLayout.RowHeight = {'0.8x','0.2x','2x'};
    
    %% 第一行：控制面板区域（分为3列）
    controlPanel = uipanel(mainLayout, 'Title', '控制面板');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = 1;
    cpLayout = uigridlayout(controlPanel, [1,3]);
    cpLayout.ColumnWidth = {'1x','1x','1x'};
    
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
    
    lblSpeed = uilabel(spindleLayout, 'Text', '设定转速（rpm）:');
    lblSpeed.Layout.Row = 2;
    lblSpeed.Layout.Column = 1;
    txtSpeed = uieditfield(spindleLayout, 'numeric', 'Value', targetSpeed, 'ValueChangedFcn', @(src, event) updateTargetSpeed(src.Value));
    txtSpeed.ValueDisplayFormat = '%.0f';
    txtSpeed.Layout.Row = 2;
    txtSpeed.Layout.Column = 2;
    
    % --- 中间：加速度计控制区域 ---
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
    
    lblSamplingRate = uilabel(accelLayout, 'Text', '采样率（S/s）:');
    lblSamplingRate.Layout.Row = 2;
    lblSamplingRate.Layout.Column = 1;
    txtSamplingRate = uieditfield(accelLayout, 'numeric', 'Value', defaultSamplingRate, 'ValueChangedFcn', @updateSamplingRate);
    txtSamplingRate.ValueDisplayFormat = '%.0f';
    txtSamplingRate.Layout.Row = 2;
    txtSamplingRate.Layout.Column = 2;
    
    % --- 右侧：ABB机器人控制区域 ---
    robotPanel = uipanel(cpLayout, 'Title', 'ABB机器人');
    robotPanel.Layout.Row = 1;
    robotPanel.Layout.Column = 3;
    % 内部采用 3 行 2 列布局
    robotLayout = uigridlayout(robotPanel, [3,2]);
    robotLayout.RowHeight = {'1x','1x','1x'};
    robotLayout.ColumnWidth = {'1x','1x'};
    
    % 第1行：机器人上电、下电按钮
    btnRobotOn = uibutton(robotLayout, 'Text', '机器人上电', 'ButtonPushedFcn', @robotPowerOnCallback);
    btnRobotOn.Layout.Row = 1;
    btnRobotOn.Layout.Column = 1;
    btnRobotOff = uibutton(robotLayout, 'Text', '机器人下电', 'ButtonPushedFcn', @robotPowerOffCallback);
    btnRobotOff.Layout.Row = 1;
    btnRobotOff.Layout.Column = 2;
    
    % 第2行：启动、停止按钮，图标分别为 ▶ 和 ■
    btnRobotStart = uibutton(robotLayout, 'Text', '▶', 'ButtonPushedFcn', @robotStartCallback);
    btnRobotStart.Layout.Row = 2;
    btnRobotStart.Layout.Column = 1;
    btnRobotStop = uibutton(robotLayout, 'Text', '■', 'ButtonPushedFcn', @robotStopCallback);
    btnRobotStop.Layout.Row = 2;
    btnRobotStop.Layout.Column = 2;
    
    % 第3行：设定速度文本与数值编辑框，初始值设为 100
    lblRobotSpeed = uilabel(robotLayout, 'Text', '设定速度（%）:');
    lblRobotSpeed.Layout.Row = 3;
    lblRobotSpeed.Layout.Column = 1;
    txtRobotSpeed = uieditfield(robotLayout, 'numeric', 'Value', 100, 'ValueChangedFcn', @robotSpeedCallback);
    txtRobotSpeed.ValueDisplayFormat = '%.0f';
    txtRobotSpeed.Layout.Row = 3;
    txtRobotSpeed.Layout.Column = 2;
    
    %% 第二行：按钮区域（共1行6列）
    btnLayout = uigridlayout(mainLayout, [1,7]);
    btnLayout.RowHeight = {'1x'};
    btnLayout.ColumnWidth = {'1x','1x','1x','1x','1x','1x','1x'};
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
    
    % 在监控开启按钮右侧添加“抑制开启”按钮
    btnSuppressOn = uibutton(btnLayout, 'Text', '抑制开启', 'ButtonPushedFcn', @suppressButtonCallback);
    btnSuppressOn.Layout.Row = 1;
    btnSuppressOn.Layout.Column = 5;

    btnPPtoMain = uibutton(btnLayout, 'Text', '指针复位', 'ButtonPushedFcn', @PPtoMainCallback);
    btnPPtoMain.Layout.Row = 1;
    btnPPtoMain.Layout.Column = 6;
    
    % 建立连接按钮：点击时判断是否已连接，若未连接则弹出连接窗口；若已连接则直接断开
    btnRobotConn = uibutton(btnLayout, 'Text', '建立连接', 'ButtonPushedFcn', @robotConnPopupCallback);
    btnRobotConn.Layout.Row = 1;
    btnRobotConn.Layout.Column = 7;
    
    %% 第三行：数据显示区域（分为3列）
    displayPanel = uipanel(mainLayout, 'Title', '数据显示');
    displayPanel.Layout.Row = 3;
    displayPanel.Layout.Column = 1;
    displayLayout = uigridlayout(displayPanel, [1,3]);
    displayLayout.ColumnWidth = {'1x','1x','1x'};
    
    txtSpindleDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'转速显示（rpm）：'});
    txtSpindleDisplay.Layout.Row = 1;
    txtSpindleDisplay.Layout.Column = 1;
    
    txtAccelDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'加速度计显示：'});
    txtAccelDisplay.Layout.Row = 1;
    txtAccelDisplay.Layout.Column = 2;
    
    txtRobotStatusDisplay = uitextarea(displayLayout, 'Editable', 'off', 'Value', {'机器人状态显示：'});
    txtRobotStatusDisplay.Layout.Row = 1;
    txtRobotStatusDisplay.Layout.Column = 3;
    
    %% 加载ABB动态库和定义全局共享变量（ABB相关）
    try
        NET.addAssembly('C:\Program Files (x86)\ABB\SDK\PCSDK 2025\ABB.Robotics.Controllers.PC.dll');
    catch ME
        abbMsg(['加载ABB DLL失败: ' ME.message]);
    end
    import ABB.Robotics.Controllers.*;
    import ABB.Robotics.Controllers.Discovery.*;
    import ABB.Robotics.Controllers.RapidDomain.*;
    
    abbTable = [];
    abbMsgArea = [];
    controllersABB = [];
    controllerABB = [];
    
    %% 创建主轴定时器
    spindleTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'TimerFcn', @spindleTimerFcn);
    
    %% 窗口关闭回调
    fig.CloseRequestFcn = @(src,event) closeApp();
    
    %% 机器人连接弹窗回调（单独弹出界面建立连接）
    function robotConnPopupCallback(src, ~)
        if isempty(controllerABB)
            % 未连接，弹出模态窗口
            connFig = uifigure('Name', '机器人连接设置', 'Position', [400 300 400 150], 'WindowStyle', 'modal');
            connLayout = uigridlayout(connFig, [3,2]);
            connLayout.RowHeight = {'1x','1x','1x'};
            connLayout.ColumnWidth = {'1x','1x'};
            
            btnRefreshABB = uibutton(connLayout, 'Text', '刷新', 'ButtonPushedFcn', @refreshScanABB);
            btnRefreshABB.Layout.Row = 1; 
            btnRefreshABB.Layout.Column = 1;
            
            btnConnectABB = uibutton(connLayout, 'Text', '连接', 'ButtonPushedFcn', @connectControllerABB);
            btnConnectABB.Layout.Row = 1; 
            btnConnectABB.Layout.Column = 2;
            
            abbTable = uitable(connLayout, 'ColumnName', {'IP地址','系统名称','状态'});
            abbTable.Layout.Row = [2 3];
            abbTable.Layout.Column = [1 2];
        else
            % 已连接，直接断开连接
            disconnectRobotCallback();
            src.Text = '建立连接';
        end
    end
    
    %% ------------------------- ABB机器人相关功能函数 ------------------------------
    
    % 刷新扫描ABB控制器
    function refreshScanABB(~, ~)
        try
            scanner = Discovery.NetworkScanner();
            scanner.Scan();
            controllersABB = scanner.Controllers;
            n = controllersABB.Count;
            if n == 0
                abbTable.Data = {};
                abbMsg('未扫描到ABB控制器！');
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
            abbMsg(['扫描错误: ' ME.message]);
        end
    end

    % 连接选中的ABB控制器
    function connectControllerABB(~, ~)
        if isempty(abbTable.Data)
            abbMsg('请先刷新扫描！');
            return;
        end
        sel = abbTable.Selection;
        if isempty(sel)
            abbMsg('请先选择一行！');
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
            abbMsg(['已连接控制器: ' char(info.SystemName)]);
            % 更新主界面“建立连接”按钮文本为“断开连接”
            btnRobotConn.Text = '断开连接';
        else
            abbMsg('选中的控制器不可用或已被占用！');
        end
    end

    % 断开ABB控制器连接
    function disconnectRobotCallback(~, ~)
        if isempty(controllerABB)
            abbMsg('未建立机器人连接');
        else
            try
                % 判断是否处于上电状态（这里假设 MotorsOn 表示上电）
                if controllerABB.State == ABB.Robotics.Controllers.ControllerState.MotorsOn
                    % 先停止程序
                    robotStopCallback();
                    pause(0.5);  % 可加入短暂延时，确保停止命令生效
                    % 再下电
                    robotPowerOffCallback();
                    pause(0.5);  % 确保下电操作完成
                end
            catch ME
                abbMsg(['机器人停止或下电失败: ' ME.message]);
            end
            controllerABB.Logoff();
            controllerABB.Dispose();
            controllerABB = [];
            abbMsg('已断开机器人连接');
            btnRobotConn.Text = '建立连接';
        end
    end


    % ABB机器人上电
    function robotPowerOnCallback(~, ~)
        if isempty(controllerABB)
            abbMsg('机器人未连接，请先建立连接');
            return;
        end
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                controllerABB.State = ABB.Robotics.Controllers.ControllerState.MotorsOn;
                abbMsg('机器人上电成功');
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['上电错误: ' ME.message]);
        end
    end

    % ABB机器人下电
    function robotPowerOffCallback(~, ~)
        if isempty(controllerABB)
            abbMsg('机器人未连接，请先建立连接');
            return;
        end
        try
            if controllerABB.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                controllerABB.State = ABB.Robotics.Controllers.ControllerState.MotorsOff;
                abbMsg('机器人下电成功');
            else
                abbMsg('请切换到自动模式');
            end
        catch ME
            abbMsg(['下电错误: ' ME.message]);
        end
    end

    % 程序指针复位（PPtoMain）
    function PPtoMainCallback(~, ~)
        if isempty(controllerABB)
            abbMsg('机器人未连接，请先建立连接');
            return;
        end
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
            abbMsg(['复位错误: ' ME.message]);
        end
    end

    % 启动ABB机器人程序（用 ▶ 表示）
    function robotStartCallback(~, ~)
        if isempty(controllerABB)
            abbMsg('机器人未连接，请先建立连接');
            return;
        end
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
            abbMsg(['启动错误: ' ME.message]);
        end
    end

    % 停止ABB机器人程序（用 ■ 表示）
    function robotStopCallback(~, ~)
        if isempty(controllerABB)
            abbMsg('机器人未连接，请先建立连接');
            return;
        end
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
            abbMsg(['停止错误: ' ME.message]);
        end
    end

    % 设置ABB机器人运动速度（0~100）
    function robotSpeedCallback(src, ~)
        if isempty(controllerABB)
            abbMsg('机器人未连接，请先建立连接');
            return;
        end
        speedVal = src.Value;
        if isnan(speedVal) || speedVal < 0 || speedVal > 100
            abbMsg('请输入0到100之间的有效数值');
            return;
        end
        try
            controllerABB.MotionSystem.SpeedRatio = int32(speedVal);
            abbMsg(['速度已设置为 ' num2str(speedVal) '%']);
        catch ME
            abbMsg(['设置速度错误: ' ME.message]);
        end
    end

    % --- 更新ABB消息显示 ---
    function abbMsg(msg)
        txtRobotStatusDisplay.Value = [{msg}; txtRobotStatusDisplay.Value];
        if length(txtRobotStatusDisplay.Value) > 200
            txtRobotStatusDisplay.Value = txtRobotStatusDisplay.Value(1:200);
        end
        
        % 如果正在记录消息，则将机器人消息添加到日志
        if isRecordingMessages
            logMessage('robot', msg);    % 记录到统一日志 / log to unified struct
        end
    end



    
    %% ------------------------- ABB机器人相关功能函数结束 ------------------------------
    
    %% 以下为其他现有模块的回调函数

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
    function updateTargetSpeed(newSpeed)
        if isSpindleConnected
            % 只有当目标转速发生变化时才更新
            if newSpeed ~= targetSpeed
                targetSpeed = newSpeed;  % 更新目标转速
                
                % 更新文本框中的值
                txtSpeed.Value = targetSpeed;
                
                % 发送新的转速命令给主轴
                sendSpindleCmd();
                
                % 在数据显示区显示新的转速
                prependSpindleDisplay(['更新目标转速为: ' num2str(targetSpeed)]);
            end
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
                    prependSpindleDisplay(['主轴转速: ' num2str(speedVal)]);
                end
                if isRecording && ~accelRunning
                    t = toc(recordStartTime);
                    % stamp, accX, accY, accZ, spin, chatter, freq, amp, procTime
                    newRow = [ ...
                        t,        ... % 时间戳 / timestamp
                        NaN,      ... % accX 无数据 / 加速度计 X
                        NaN,      ... % accY 无数据 / 加速度计 Y
                        NaN,      ... % accZ 无数据 / 加速度计 Z
                        currentSpindleSpeed, ... % 主轴转速 / spindle speed
                        NaN,      ... % isChatter 无数据
                        NaN,      ... % prominentFreq 无数据
                        NaN,      ... % max_amp 无数据
                        NaN       ... % processingTime 无数据
                    ];
                    dataLog = [ dataLog; newRow];
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
            accelDAQ = daq("ni");  % 创建 NI DAQ 对象
        catch ME
            uialert(fig, ['无法创建DAQ对象: ' ME.message], '错误');
            return;
        end
        try
            % 采集 ai0, ai1, ai2 三个通道的数据
            ch0 = addinput(accelDAQ, "cDAQ1Mod1", "ai0", "Accelerometer");  % 加速度计X
            ch1 = addinput(accelDAQ, "cDAQ1Mod1", "ai1", "Accelerometer");  % 加速度计Y
            ch2 = addinput(accelDAQ, "cDAQ1Mod1", "ai2", "Accelerometer");  % 加速度计Z
            % 设置灵敏度
            ch0.Sensitivity = 0.01000;
            ch1.Sensitivity = 0.01000;
            ch2.Sensitivity = 0.01000;
            
            newRate = round(txtSamplingRate.Value);  % 设置采样率
            accelDAQ.Rate = newRate;
            txtSamplingRate.Value = accelDAQ.Rate;
            
            accelDAQ.ScansAvailableFcnCount = round(accelDAQ.Rate / 10);  % 设置每次采样的扫描数
            accelDAQ.ScansAvailableFcn = @accelDAQCallback;  % 设置数据回调函数
            start(accelDAQ, "continuous");  % 开始连续数据采集
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
            % 获取加速度计数据的最新值
            latestX = data(end, 1);  % accX 数据
            latestY = data(end, 2);  % accY 数据
            latestZ = data(end, 3);  % accZ 数据
            
            % 更新数据显示
            prependAccelDisplay(['采集数据: X = ' num2str(latestX) ', Y = ' num2str(latestY) ', Z = ' num2str(latestZ)]);
            
            % 当开启监测时，进行振动分析
            if isMonitoring
                % 仅使用 accX 数据传递给 decisionReport 进行分析
                [reportData, reportStr] = decisionReport(timestamps, data(:, 1), currentSpindleSpeed, threshold);
                prependAccelDisplay(reportStr);  % 显示振动分析报告
            end
            
            % 数据记录：记录所有三个通道的数据，并附加当前主轴转速
            if isRecording
                numPoints = length(timestamps);
                
                % 获取决策报告中的数据
                chatterData = repmat(reportData.isChatter, numPoints, 1);
                freqData = repmat(reportData.prominentFreq, numPoints, 1);
                ampData = repmat(reportData.max_amp, numPoints, 1);
                timeData = repmat(reportData.processingTime, numPoints, 1);
                
                % 将新数据添加到 dataLog 中
                newRows = [timestamps, data, repmat(currentSpindleSpeed, numPoints, 1), chatterData, freqData, ampData, timeData];
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
            % 开始记录数据
            dataLog = [];
            isRecording = true;
            isRecordingMessages = true;  % 开始记录消息
            src.Text = '■';
            recordStartTime = tic;
            prependSpindleDisplay('开始记录数据...');
            prependAccelDisplay('开始记录数据...');
        else
            % 停止记录数据
            isRecording = false;
            isRecordingMessages = false;  % 停止记录消息
            if ~isempty(dataLog)
                dataLog(:,1) = dataLog(:,1) - dataLog(1,1);  % 调整时间戳
            end
            src.Text = '记录数据';
            
            % 保存数据到文件
            % 将每一列赋值到 base workspace
            assignin('base', 'timestamps', dataLog(:, 1));           % 时间戳
            assignin('base', 'accX', dataLog(:, 2));                 % 加速度计 X 数据
            assignin('base', 'accY', dataLog(:, 3));                 % 加速度计 Y 数据
            assignin('base', 'accZ', dataLog(:, 4));                 % 加速度计 Z 数据
            assignin('base', 'spinSpeed', dataLog(:, 5));         % 主轴转速
            assignin('base', 'isChatter', dataLog(:, 6));            % 是否发生颤振
            assignin('base', 'prominentFreq', dataLog(:, 7));        % 突出频率
            assignin('base', 'maxAmp', dataLog(:, 8));               % 最大幅值
            assignin('base', 'processingTime', dataLog(:, 9));       % 处理时间

            
            [filename, pathname] = uiputfile('*.txt', '保存数据记录为TXT文件');
            if ischar(filename)
                fullpath = fullfile(pathname, filename);
                writematrix(dataLog, fullpath, 'Delimiter', '\t');
            end
            
            % 保存消息日志到文件（不弹出对话框，默认保存到本地）
            % --- 保存消息日志到文件（带 try/catch） ---
            if ~isempty(messageLog)
                logFolder = fullfile(pwd, 'logs');
                if ~exist(logFolder,'dir'), mkdir(logFolder); end
                timeStamp   = datestr(now,'yyyy-mm-dd_HH-MM-SS');
                logFilePath = fullfile(logFolder, ['message_log_' timeStamp '.txt']);
                try
                    % 打开文件 / open file
                    fid = fopen(logFilePath,'w');
                    % 逐行写入 / write each entry
                    for i = 1:numel(messageLog)
                        fprintf(fid, '%.3f\t%s\t%s\t%s\n', ...
                            messageLog(i).time, ...
                            messageLog(i).spindleMsg, ...
                            messageLog(i).accelMsg, ...
                            messageLog(i).robotMsg);
                    end
                    fclose(fid);
                    prependSpindleDisplay(['消息日志已保存到: ' logFilePath]);
                catch
                    % 如果写入失败，弹窗提示 / alert if save fails
                    uialert(fig, '无法保存日志文件', '错误');
                end
            end

            prependAccelDisplay('数据记录停止，数据已保存');
            messageLog = [];  % 清空消息日志，以备下次记录不混入旧数据

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


    % 抑制按钮回调
    function suppressButtonCallback(src, ~)
        if isSuppressActive
            isSuppressActive = false;
            src.Text = '抑制开启';  % 修改按钮文字为"抑制开启"
            prependAccelDisplay('抑制关闭，主轴转速停止调整');  % 显示抑制关闭消息
        else
            isSuppressActive = true;
            src.Text = '抑制关闭';  % 修改按钮文字为"抑制关闭"
            prependAccelDisplay('抑制开启，主轴转速开始调整');  % 显示抑制开启消息

            % 重置 lastTargetSpeed，以便下一次抑制开启时重新计算
            lastTargetSpeed = NaN;
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
        if ~isSpindleConnected || spindlePowerOn == 0
            stop(customSpeedTimer);
            delete(customSpeedTimer);
            customSpeedButton.Text = '自定义调速开启';
            prependSpindleDisplay('主轴下电，自动停止自定义调速');
            return;
        end
    
        elapsedTime = toc(customSpeedStartTime);
        newSpeed = customSpeedProfile(elapsedTime);
        % 调用统一的 updateTargetSpeed 函数更新转速
        updateTargetSpeed(newSpeed);  % 传入新的转速值进行更新
        prependSpindleDisplay(['自定义调速更新: t = ' num2str(elapsedTime, '%.2f') ' s, 目标转速 = ' num2str(newSpeed) ' rpm']);
        
        if newSpeed == 0
            stop(customSpeedTimer);
            delete(customSpeedTimer);
            spindlePowerOffClick();
            prependSpindleDisplay('调速结束，主轴已下电');
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
            spd = 0;  % 返回 0 表示结束调速（可根据需要改为 -1 下电信号）
        end
    end

    % --- 决策报告子函数 ---  
    function [reportData, reportStr] = decisionReport(t_chunk, acc_chunk, currentSpin, threshold)
        tic;
        [isChatter, prominentFreq, ~, ~, max_amp] = f060_Decision_fft_filter_report(t_chunk, acc_chunk, currentSpin, threshold); % Capture max_amp
        
        % Use isChatter to determine decision status
        if isChatter
            decisionStr = '颤振';  % Chatter (abnormal vibration)
            
            % 当发生颤振时，计算新的主轴转速
            newSpin = f070_NewSpinSpeed_04(prominentFreq, currentSpin);  % 调用新函数计算新转速
            
            % 只有在抑制开启时才更新转速
            if isSuppressActive
                % 限制转速的最大值为 13000 rpm
                newSpin = min(newSpin, 13000);  % 将转速限制为最大 13000 rpm
                
                % 如果 lastTargetSpeed 为 NaN，说明还没有更新过转速
                if isnan(lastTargetSpeed)
                    % 第一次更新转速
                    updateTargetSpeed(newSpin);  % 更新目标转速
                    lastTargetSpeed = newSpin;  % 将新的目标转速保存
                else
                    % 只有当 currentSpin 达到或大于 lastTargetSpeed 时才更新
                    if currentSpin >= lastTargetSpeed || abs(currentSpin - lastTargetSpeed) < 10  % 当前转速接近目标转速（例如允许 10 rpm 的误差）
                        updateTargetSpeed(newSpin);  % 更新目标转速
                        lastTargetSpeed = newSpin;  % 更新 lastTargetSpeed 为新的目标转速
                    end
                end
            end
        else
            decisionStr = '稳定';  % Stable
            newSpin = NaN;  % 如果没有颤振，设置 newSpin 为 NaN
        end
        
        processingTime = toc;
        
        % 格式化决策报告字符串，并包含 newSpin 信息
        reportStr = sprintf('t = %.1f s, %s, fc = %.2f Hz, Xf = %.4f, n_new = %.2f rpm, pass = %.4f s', ...
            t_chunk(end), decisionStr, prominentFreq, max_amp, newSpin, processingTime);
        
        % 返回报告数据，包括所有需要记录的数据
        reportData.isChatter = isChatter;
        reportData.prominentFreq = prominentFreq;
        reportData.max_amp = max_amp;
        reportData.processingTime = processingTime;
        reportData.newSpin = newSpin;  % 记录新的转速
    end


    % 统一日志记录子函数 Unified log helper (放在脚本最后)

    function logMessage(source, msg)
        % 相对 recordStartTime 的秒数 / elapsed seconds
        t = toc(recordStartTime);
        % 如果是新时间点，就新建一行空结构
        if isempty(messageLog) || abs(t - messageLog(end).time) > 1e-7
            entry.time       = t;
            entry.spindleMsg = "";
            entry.accelMsg   = "";
            entry.robotMsg   = "";
            messageLog(end+1) = entry;
        end
        % 填写对应字段 / fill the matching field
        switch source
            case 'spindle'
                messageLog(end).spindleMsg = msg;
            case 'accel'
                messageLog(end).accelMsg   = msg;
            case 'robot'
                messageLog(end).robotMsg   = msg;
        end
    end




    % --- 将信息添加到主轴数据展示区 ---
    function prependSpindleDisplay(msg)
        newVal = [{msg}; txtSpindleDisplay.Value];
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtSpindleDisplay.Value = newVal;
        
        % 如果正在记录消息，则将主轴消息添加到日志
        if isRecordingMessages
            logMessage('spindle', msg);  % 记录到统一日志 / log to unified struct
        end
    end



    % --- 将信息添加到加速度计数据展示区 ---
    function prependAccelDisplay(msg)
        newVal = [{msg}; txtAccelDisplay.Value];
        if length(newVal) > 200
            newVal = newVal(1:200);
        end
        txtAccelDisplay.Value = newVal;
        % 再把同样的内容展示到“主轴”显示框
        txtSpindleDisplay.Value = newVal;
        
        % 如果正在记录消息，则将加速度计消息添加到日志
        if isRecordingMessages
            logMessage('accel', msg);  % 记录到统一日志 / log to unified struct
        end
    end


    function clearDisplayCallback(~, ~)
        txtSpindleDisplay.Value = {'转速显示（rpm）：'};
        txtAccelDisplay.Value = {'加速度计显示：'};
        txtRobotStatusDisplay.Value = {'机器人状态显示：'};
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
