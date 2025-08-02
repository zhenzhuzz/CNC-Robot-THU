function simpleDAQ_GUI
    % 创建主窗口
    hFig = figure('Name', 'DAQ 控制界面', ...
                  'Position', [100, 100, 600, 400], ...
                  'MenuBar', 'none', 'NumberTitle', 'off');
    
    %% 第一行：两个按钮
    btnOn = uicontrol('Style', 'pushbutton', 'String', '加速度计上电', ...
        'FontSize', 12, 'Position', [50, 350, 150, 30], 'Callback', @startDAQ);
    btnOff = uicontrol('Style', 'pushbutton', 'String', '加速度计下电', ...
        'FontSize', 12, 'Position', [220, 350, 150, 30], 'Callback', @stopDAQ, 'Enable', 'off');
    
    %% 第二行：采样率调节（文本框 + 滑动条）
    uicontrol('Style', 'text', 'String', '采样率 (Hz):', ...
        'FontSize', 12, 'HorizontalAlignment', 'right', 'Position', [50, 310, 80, 20]);
    hRateEdit = uicontrol('Style', 'edit', 'String', '12800', ...
        'FontSize', 12, 'Position', [140, 310, 100, 25], 'Callback', @rateEditCallback);
    % 这里的滑动条上下限可根据实际设备的RateLimit调整，此处简单设置为1000-25600 Hz
    hRateSlider = uicontrol('Style', 'slider', 'Min', 1000, 'Max', 25600, 'Value', 12800, ...
        'Position', [260, 310, 200, 25], 'Callback', @rateSliderCallback);
    
    %% 第三行：输出显示区域（多行文本框）
    hOutput = uicontrol('Style', 'edit', 'Max', 10, 'Min', 1, 'Enable', 'inactive', ...
        'HorizontalAlignment', 'left', 'FontSize', 12, 'Position', [50, 50, 500, 240], 'String', '');
    
    %% 全局变量：DAQ对象
    dq = [];
    
    %% 回调函数定义
    % 加速度计上电：创建DAQ、添加通道并开始采集数据
    function startDAQ(~, ~)
        try
            if isempty(dq) || ~isvalid(dq)
                % 创建DAQ对象，厂商这里用 "ni"（根据需要更改）
                dq = daq("ni");
                % 设置采样率，根据文本框内容（默认12800Hz）
                dq.Rate = str2double(get(hRateEdit, 'String'));
                % 添加加速度计通道，注意此处设备ID、通道号和测量类型需与实际硬件匹配
                ch = addinput(dq, "cDAQ1Mod1", "ai0", "Accelerometer");
                % 设置灵敏度（单位：g对应的电压值）
                ch.Sensitivity = 0.01000;
                % 设置回调，每当采集到一定数据量时触发，此处设为2560个扫描样本
                dq.ScansAvailableFcnCount = 2560;
                dq.ScansAvailableFcn = @(src, event) scansAvailableFcn(src, event);
            end
            % 启动连续采集
            start(dq, "continuous");
            set(btnOn, 'Enable', 'off');
            set(btnOff, 'Enable', 'on');
        catch ME
            errordlg(ME.message, '启动错误');
        end
    end

    % 加速度计下电：停止数据采集
    function stopDAQ(~, ~)
        try
            if ~isempty(dq) && isvalid(dq)
                stop(dq);
            end
            set(btnOn, 'Enable', 'on');
            set(btnOff, 'Enable', 'off');
        catch ME
            errordlg(ME.message, '停止错误');
        end
    end

    % 数据采集回调函数：读取数据并更新输出显示
    function scansAvailableFcn(src, ~)
        try
            % 读取当前回调块内的数据，输出为矩阵形式
            [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
            % 对采集到的数据计算平均值（仅取第一通道数据）
            avgAccel = mean(data(:,1));
            % 生成显示字符串，包含当前时间和平均加速度（单位g）
            lineStr = sprintf('%s - 平均加速度: %.4f g\n', datestr(now, 'HH:MM:SS.FFF'), avgAccel);
            % 获取当前输出文本框内容（以单元数组存储每一行）
            currentText = get(hOutput, 'String');
            if ischar(currentText)
                currentText = cellstr(currentText);
            end
            % 追加新的一行
            newText = [currentText; {lineStr}];
            % 若行数过多，则只保留最新100行
            if numel(newText) > 100
                newText = newText(end-99:end);
            end
            % 更新输出显示
            set(hOutput, 'String', newText);
            drawnow;
        catch ME
            disp(['采集回调错误: ' ME.message]);
        end
    end

    % 采样率文本框回调：更新滑动条和DAQ采样率
    function rateEditCallback(src, ~)
        val = str2double(get(src, 'String'));
        if isnan(val) || val < get(hRateSlider, 'Min') || val > get(hRateSlider, 'Max')
            errordlg('采样率无效，请输入正确范围内的数值。', '错误');
            set(src, 'String', num2str(get(hRateSlider, 'Value')));
        else
            set(hRateSlider, 'Value', val);
            if ~isempty(dq) && isvalid(dq)
                dq.Rate = val;
            end
        end
    end

    % 采样率滑动条回调：更新文本框和DAQ采样率
    function rateSliderCallback(src, ~)
        val = get(src, 'Value');
        set(hRateEdit, 'String', num2str(val));
        if ~isempty(dq) && isvalid(dq)
            dq.Rate = val;
        end
    end

    %% 窗口关闭时停止采集并释放DAQ对象
    set(hFig, 'CloseRequestFcn', @closeGUI);
    function closeGUI(~, ~)
        try
            if ~isempty(dq) && isvalid(dq)
                stop(dq);
                delete(dq);
            end
        catch
        end
        delete(hFig);
    end
end
