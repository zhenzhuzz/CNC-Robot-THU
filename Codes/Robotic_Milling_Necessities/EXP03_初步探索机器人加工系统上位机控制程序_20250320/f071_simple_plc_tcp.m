function simple_plc_tcp()
    %% 初始化参数
    plcIP = "192.168.0.1";
    plcPort = 2000;
    client = [];
    isConnected = false;    % PLC连接状态
    targetSpeed = 0;        % 初始转速
    powerOn = 1;            % 初始上电状态

    %% 创建界面
    fig = uifigure('Name', 'PLC原始通讯', 'Position', [500 500 400 250]);
    btnPowerOn = uibutton(fig, 'Position', [20 120 150 30], 'Text', '主轴上电', ...
        'ButtonPushedFcn', @powerOnClick);
    btnPowerOff = uibutton(fig, 'Position', [180 120 150 30], 'Text', '主轴下电', ...
        'ButtonPushedFcn', @powerOffClick);
    lblRecv = uilabel(fig, 'Position', [20 50 360 50], 'FontSize', 14);
    lblSpeed = uilabel(fig, 'Position', [20 160 150 30], 'Text', '设定转速:');
    txtSpeed = uieditfield(fig, 'numeric', 'Position', [170 160 100 30], 'Value', targetSpeed, ...
        'ValueChangedFcn', @updateTargetSpeed);
    fig.CloseRequestFcn = @(~,~) closeApp();

    %% 创建定时器（全局只创建一次）
    commTimer = timer('ExecutionMode','fixedSpacing','Period',0.01, ...
                      'TimerFcn', @commFcn);

    %% 上电回调函数
    function powerOnClick(~, ~)
        if ~isConnected
            try
                client = tcpclient(plcIP, plcPort);
            catch ME
                disp(['连接失败: ' ME.message]);
                return;
            end
            isConnected = true;
            powerOn = 1;  % 恢复上电状态
            btnPowerOn.Text = '主轴已连接';
            start(commTimer);
            disp('主轴已连接');
        else
            disp('主轴已连接，无法重复连接');
        end
    end

    %% 下电回调函数
    function powerOffClick(~, ~)
        if isConnected
            targetSpeed = 0;
            powerOn = 0;
            sendCmd();
            stop(commTimer);
            isConnected = false;
            btnPowerOn.Text = '主轴上电';
            disp('主轴下电，PLC通信已停止');
            cleanupConnection();
        else
            disp('PLC未连接，无法执行下电操作');
        end
    end

    %% 定时器回调：发送与接收数据
    function commFcn(~, ~)
        if isConnected
            sendCmd();
            data = receiveData();
            if ~isempty(data)
                parsed = parseData(data);
                lblRecv.Text = "PLC发来的数据: " + num2str(parsed);
                disp(parsed);
            end
        end
    end

    %% 发送命令（利用共享变量）
    function sendCmd()
        cmd = sprintf('!!%05d,%d#', targetSpeed, powerOn);
        write(client, unicode2native(cmd, 'UTF-8'));
    end

    %% 接收数据
    function data = receiveData()
        if client.NumBytesAvailable > 0
            data = char(read(client, client.NumBytesAvailable));
        else
            data = '';
        end
    end

    %% 解析数据
    function parsed = parseData(data)
        data = regexprep(strtrim(data), '[^\d]', '');
        parsed = str2double(data);
    end

    %% 更新转速回调函数
    function updateTargetSpeed(src, ~)
        if isConnected
            targetSpeed = src.Value;
            disp(['更新目标转速为: ', num2str(targetSpeed)]);
        else
            disp('PLC未连接，无法更新转速');
        end
    end

    %% 清理连接
    function cleanupConnection()
        if ~isempty(client)
            clear client;
            disp('PLC连接已清理');
        end
    end

    %% 窗口关闭处理
    function closeApp()
        if isConnected
            stop(commTimer);
            delete(commTimer);
            sendCmd();  % 发送最终命令
            clear client;
            disp('PLC连接关闭，程序结束');
        end
        delete(fig);
    end
end
