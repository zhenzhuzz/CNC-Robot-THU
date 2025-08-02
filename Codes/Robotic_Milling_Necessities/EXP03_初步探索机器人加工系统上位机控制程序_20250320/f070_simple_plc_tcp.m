function spindle_gui()
    % PLC连接参数（请确认）
    plcIP = "192.168.0.1";  % PLC的实际IP
    plcPort = 2000;
    client = tcpclient(plcIP, plcPort, 'Timeout', 10);
    
    % 创建GUI界面
    fig = uifigure('Name', '主轴控制界面', 'Position', [400 400 450 350]);

    % 连接按钮
    btnConnect = uibutton(fig, 'push', 'Position', [150 300 150 40], 'Text', '连接主轴', ...
        'ButtonPushedFcn', @(btn, event) connectPLC(client, btn));
    
    % 显示设定转速
    lblSetSpeed = uilabel(fig, 'Position', [50 220 120 30], 'Text', '设定转速：', 'FontSize', 14, 'HorizontalAlignment', 'right');
    txtSetSpeed = uieditfield(fig, 'numeric', 'Position', [180 220 100 25], 'Editable', 'off', 'Value', 0);
    
    % 显示实际转速
    lblActualSpeed = uilabel(fig, 'Position', [50 150 120 30], 'Text', '实际转速：', 'FontSize', 14, 'HorizontalAlignment', 'right');
    txtActualSpeed = uieditfield(fig, 'numeric', 'Position', [180 150 100 25], 'Editable', 'off', 'Value', 0);

    % 滑动条 (0~15000rpm)
    sld = uislider(fig, 'Position', [80 90 300 3], 'Limits', [0 15000], 'Value', 0, ...
        'ValueChangedFcn', @(sld, event) sliderChanged(client, sld, txtSetSpeed));
    
    % 更新状态
    status = struct('connected', false);
    
    % 连接PLC的函数
    function connectPLC(client, btn)
        try
            write(client, unicode2native('!!00000,1#', 'UTF-8')); % 初始发送一个简单的命令
            status.connected = true;
            btn.BackgroundColor = [0 1 0]; % 变为绿色，表示已连接
            disp('主轴已连接');
        catch
            status.connected = false;
            btn.BackgroundColor = [1 0 0]; % 变为红色，表示连接失败
            disp('连接失败');
        end
    end

    % 滑动条变化时的回调函数
    function sliderChanged(client, sld, txtSetSpeed)
        if status.connected
            targetSpeed = round(sld.Value);
            txtSetSpeed.Value = targetSpeed;
            sendCommandToPLC(client, targetSpeed);
            disp(['设定转速：', sprintf('!!%05d,1#', targetSpeed)]);
        else
            disp('主轴未上电');
            sld.Value = 0; % 如果没有连接，滑动条回到0
        end
    end

    % 文本框更新时的回调函数
    function textBoxChanged(src, ~)
        if status.connected
            targetSpeed = round(src.Value);
            sld.Value = targetSpeed; % 滑动条也更新
            sendCommandToPLC(client, targetSpeed);
            disp(['设定转速：', sprintf('!!%05d,1#', targetSpeed)]);
        else
            disp('主轴未上电');
            src.Value = 0; % 如果没有连接，文本框回到0
        end
    end

    % 发送命令到PLC并读取反馈数据
    function sendCommandToPLC(client, targetSpeed)
        cmd = sprintf('!!%05d,1#', targetSpeed);
        write(client, unicode2native(cmd, 'UTF-8'));
        
        % 实时读取PLC返回数据
        if client.NumBytesAvailable > 0
            data = char(read(client, client.NumBytesAvailable));
            % 清理数据：去除多余的字符（例如换行符）
            data = strtrim(data);
            
            % 将数据转换为数字并进行有效性检查
            actualSpeed = str2double(data);
            if ~isnan(actualSpeed) && actualSpeed >= 0
                txtActualSpeed.Value = actualSpeed;  % 设置实际转速
                disp(['实际转速：', data]);  % 输出实际转速
            else
                disp('无效的实际转速数据');
            end
        end
    end

    % 绑定文本框的值变化
    txtSetSpeed.ValueChangedFcn = @textBoxChanged;

    % 关闭界面时自动停止并断开连接
    fig.CloseRequestFcn = @(~,~) closeApp(client);
    
    % 确保关闭时安全断开连接
    function closeApp(client)
        if status.connected
            write(client, unicode2native('!!00000,0#', 'UTF-8'));  % 发停止信号
        end
        clear client;
        delete(fig);
        disp('程序已关闭');
    end
end
