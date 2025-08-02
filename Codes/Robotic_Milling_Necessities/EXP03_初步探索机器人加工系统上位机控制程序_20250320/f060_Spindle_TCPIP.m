function f060_Spindle_TCPIP()
    %% 创建TCP连接
    spindleIP = "192.168.0.1";  % 测试用本地IP，实际使用时改为主轴IP
    spindlePort = 2000;
    toolManager = tcpclient(spindleIP, spindlePort);
    pause(0.5);
    disp('主轴连接成功！');

    %% 创建GUI界面
    fig = uifigure('Name','主轴转速控制','Position',[400 400 450 250]);

    % 显示设定转速Label
    lblSetSpeed = uilabel(fig,...
        'Position',[50 180 120 30],...
        'Text','设定转速：',...
        'FontSize',14,...
        'HorizontalAlignment','right');

    % 设定转速显示文本框
    txtSetSpeed = uieditfield(fig,'numeric',...
        'Position',[180 185 100 25],...
        'Editable','off',...
        'Value',0);

    % 显示实际转速Label
    lblActualSpeed = uilabel(fig,...
        'Position',[50 130 120 30],...
        'Text','实际转速：',...
        'FontSize',14,...
        'HorizontalAlignment','right');

    % 实际转速显示文本框
    txtActualSpeed = uieditfield(fig,'numeric',...
        'Position',[180 135 100 25],...
        'Editable','off',...
        'Value',0);

    % Slider控件 (0~5000rpm)
    sld = uislider(fig,...
        'Position',[80 80 300 3],...
        'Limits',[0 5000],...
        'Value',0,...
        'ValueChangedFcn',@sliderChanged,...
        'ValueChangingFcn',@sliderChanging);

    %% 初始主轴停止
    AlterSpeedTo(toolManager, 0, false);

    %% 滑动条正在移动时实时更新转速
    function sliderChanging(~, event)
        speed = round(event.Value);
        txtSetSpeed.Value = speed;
        AlterSpeedTo(toolManager, speed, speed > 0);
    end

    %% 滑动条移动停止后更新一次
    function sliderChanged(~, event)
        speed = round(event.Value);
        txtSetSpeed.Value = speed;
        AlterSpeedTo(toolManager, speed, speed > 0);
    end

    %% 定时读取实际转速（主轴反馈）
    speedRecvTimer = timer('ExecutionMode','fixedSpacing',...
                           'Period',0.1,... % 100ms一次
                           'TimerFcn',@updateActualSpeed);
    start(speedRecvTimer);

    %% 读取主轴实时转速并更新GUI
    function updateActualSpeed(~, ~)
        if toolManager.NumBytesAvailable > 0
            data = read(toolManager, toolManager.NumBytesAvailable, 'char');
            data = erase(data, "#"); % 去除结束符
            actualSpeed = str2double(strtrim(data));
            if ~isnan(actualSpeed)
                txtActualSpeed.Value = actualSpeed;
            end
        end
    end


    %% 关闭界面时自动停止主轴并断开连接
    fig.CloseRequestFcn = @appClose;

    function appClose(~, ~)
        stop(speedRecvTimer);
        delete(speedRecvTimer);
        for i=1:5
            AlterSpeedTo(toolManager,0,false);
            pause(0.01);
        end
        clear toolManager;
        delete(fig);
        disp('已关闭主轴连接和界面');
    end

    %% 主轴通信函数
    function AlterSpeedTo(toolManager, speed, powerOn)
        connStatus = powerOn; % 1为上电，0为下电
        speedStr = sprintf('%05d', speed);
        cmd = "!!" + speedStr + "," + string(connStatus) + "#";
        write(toolManager, unicode2native(cmd, 'UTF-8')); % 直接发送字节流
    end

end