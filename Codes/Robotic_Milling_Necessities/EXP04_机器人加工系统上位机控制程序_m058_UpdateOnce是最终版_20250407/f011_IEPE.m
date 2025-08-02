function accelerometer_GUI
    % 创建一个简单的 GUI 界面
    fig = uifigure('Name', '加速度计控制面板', 'Position', [100 100 400 120]);

    % 创建两个按钮，并设置它们的回调函数
    btnOn = uibutton(fig, 'push', ...
        'Text', '加速度计上电', ...
        'Position', [50, 50, 120, 30], ...
        'ButtonPushedFcn', @startAcquisition);
    
    btnOff = uibutton(fig, 'push', ...
        'Text', '加速度计下电', ...
        'Position', [230, 50, 120, 30], ...
        'ButtonPushedFcn', @stopAcquisition);

    % 全局变量（通过嵌套函数共享）用于存储 DataAcquisition 对象
    dq = [];

    %% 回调函数：启动采集
    function startAcquisition(~, ~)
        % 如果采集已经在进行，则提示用户
        if ~isempty(dq) && isvalid(dq) && dq.Running
            uialert(fig, '加速度计已上电，正在采集数据。', '提示');
            return;
        end

        % 创建 DataAcquisition 对象并设置采样率
        dq = daq("ni");
        dq.Rate = 12800;

        % 添加 IEPE 通道
        % 注意：此处通道类型为 "IEPE"，对应 IEPE 模式采集
        ch = addinput(dq, "cDAQ1Mod1", "ai0", "IEPE");
        % 可通过 disp(ch) 查看 ch 对象的属性：
        % ch.ADCTimingMode, ch.ExcitationCurrent, ch.ExcitationSource,
        % ch.Coupling, ch.TerminalConfig, ch.Range, ch.Name, ch.ID,
        % ch.Device, ch.MeasurementType
        disp("当前通道属性：");
        disp(ch);

        % 设置回调，每 0.1 秒（对应1280个扫描点）触发一次数据读取
        dq.ScansAvailableFcnCount = 128;
        dq.ScansAvailableFcn = @displayScans;

        % 启动连续采集
        start(dq, "continuous");
        disp("加速度计上电，开始连续采集数据...");
    end

    %% 回调函数：停止采集
    function stopAcquisition(~, ~)
        if isempty(dq) || ~isvalid(dq) || ~dq.Running
            uialert(fig, '加速度计已经下电或未在采集数据。', '提示');
            return;
        end
        stop(dq);
        disp("加速度计下电，停止采集数据.");
    end

    %% 回调函数：周期性数据处理
    function displayScans(src, evt)
        % 读取当前周期内采集的数据
        [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
        % 显示当前回调周期采集的数据点数量及数据内容
        fprintf("当前回调周期内采集到的扫描点数量: %d\n", size(data, 1));
        disp(data);
    end
end
