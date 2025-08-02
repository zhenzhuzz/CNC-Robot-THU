clc;
clear;
close all;

%% 设置 UDP 端口
u = udpport("datagram", "IPV4", "LocalHost", "192.168.88.2", "LocalPort", 1600);
disp('UDP服务器正在监听192.168.88.2:1600...');

%% 创建实时显示图窗和子图
figure;
hAx(1) = subplot(3,1,1);
hLine(1) = plot(hAx(1), nan, nan);
title(hAx(1), 'X轴振动值');
xlabel(hAx(1), '时间 (s)');
ylabel(hAx(1), '幅值');

hAx(2) = subplot(3,1,2);
hLine(2) = plot(hAx(2), nan, nan);
title(hAx(2), 'Y轴振动值');
xlabel(hAx(2), '时间 (s)');
ylabel(hAx(2), '幅值');

hAx(3) = subplot(3,1,3);
hLine(3) = plot(hAx(3), nan, nan);
title(hAx(3), 'Z轴振动值');
xlabel(hAx(3), '时间 (s)');
ylabel(hAx(3), '幅值');

%% 数据存储设置
timeWindow = 1;                % 绘制的时间窗口长度，单位：秒
rawSampleRate = 8000;          % 预估原始数据采样率
maxBufferPoints = rawSampleRate * timeWindow;  % 缓冲区大小

xData = zeros(1, maxBufferPoints);
yData = zeros(1, maxBufferPoints);
zData = zeros(1, maxBufferPoints);
timeVec = zeros(1, maxBufferPoints);
index = 0;
t0 = tic;  % 起始时间

%% 绘图降采样设置：决定1秒内绘制的点数
desiredPlotPointsPerSec = 1000;  % 例如设为4000，则每秒图像上仅显示4000个点；设为200，则只显示200个点

%% 绘图刷新率统计变量
plotUpdateCounter = 0;
refreshStartTime = tic;

%% 主循环：持续读取 UDP 数据，并实时更新图像
while ishandle(hAx(1))
    if u.NumDatagramsAvailable > 0
        % 读取所有可用数据包
        datagrams = read(u, u.NumDatagramsAvailable, "uint8");
        for k = 1:length(datagrams)
            packet = datagrams(k).Data;
            % 确保数据包至少包含10个字节（保证有 x, y, z 数据）
            if numel(packet) >= 10
                % 解包：字节索引对应说明（低位在前）
                % x轴振动值：packet(5:6)
                % y轴振动值：packet(7:8)
                % z轴振动值：packet(9:10)
                acc_x = typecast(uint8(packet(5:6)), 'int16');
                acc_y = typecast(uint8(packet(7:8)), 'int16');
                acc_z = typecast(uint8(packet(9:10)), 'int16');
                
                % 动态追加数据，采用滑动窗口策略
                index = index + 1;
                if index > maxBufferPoints
                    xData(1:end-1) = xData(2:end);
                    yData(1:end-1) = yData(2:end);
                    zData(1:end-1) = zData(2:end);
                    timeVec(1:end-1) = timeVec(2:end);
                    index = maxBufferPoints;
                end
                xData(index) = double(acc_x);
                yData(index) = double(acc_y);
                zData(index) = double(acc_z);
                timeVec(index) = toc(t0);
            end
        end
        
        % 获取最近 timeWindow 秒的数据
        currentTime = toc(t0);
        idx = find(timeVec >= currentTime - timeWindow);
        nPoints = length(idx);
        
        % 对数据进行均匀降采样
        if nPoints > desiredPlotPointsPerSec
            sampleIdx = round(linspace(1, nPoints, desiredPlotPointsPerSec));
            idx_ds = idx(sampleIdx);
        else
            idx_ds = idx;
        end
        
        % 更新图形数据：只绘制降采样后的数据
        set(hLine(1), 'XData', timeVec(idx_ds), 'YData', xData(idx_ds));
        set(hLine(2), 'XData', timeVec(idx_ds), 'YData', yData(idx_ds));
        set(hLine(3), 'XData', timeVec(idx_ds), 'YData', zData(idx_ds));
        drawnow limitrate;
        plotUpdateCounter = plotUpdateCounter + 1;
    end
    
    % 每秒输出一次实际的绘图刷新率及设定的绘图点数
    if toc(refreshStartTime) >= 1
        fprintf('每秒绘图刷新率：%d次, 每秒绘制点数：%d\n', plotUpdateCounter, desiredPlotPointsPerSec);
        plotUpdateCounter = 0;
        refreshStartTime = tic;
    end
end
