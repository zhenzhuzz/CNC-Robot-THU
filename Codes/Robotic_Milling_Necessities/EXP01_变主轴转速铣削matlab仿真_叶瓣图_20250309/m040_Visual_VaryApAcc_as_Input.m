%% m040_Visual_GUI_VaryApAcc_as_Input.m
% 交互式GUI：实时显示加速度数据及其FFT
% 注意：请确保 f020_readAcc.m 和 f010_fourier.m 在当前路径下

% 清除环境变量
% clear; close all; clc;

% ---------------------------
% 参数设置
% ---------------------------
filepath = 'E:\EXP\YM\Acc2Surf\Figures\VaryApAcc\Acc\s7000d05-40f1300.txt';
% filepath = 'E:\EXP\YM\EXP20211020\LMS\3-3_s10000d10f1500_C.txt';
% filepath='n4600-8500-10000_ap2e-32e-32e-3_fz1e-4_z4_t6e-1.txt';

samplingRate = 12800;   % 采样率 (Hz)
windowSize    = 0.5;    % 时间窗口 (秒)
windowSamples = round(windowSize * samplingRate);
n = 9000;            % 主轴转速

% ---------------------------
% 读取数据 (只读取 X 方向)
% ---------------------------
% dataMatrix = f020_readAcc(filepath, 'X');  % f020_readAcc 只返回 [time, Acc_X]
% time   = dataMatrix(:, 1);
% accData = dataMatrix(:, 2);
time   = timestamps;
accData = data;

% ---------------------------
% 创建GUI界面
% ---------------------------
% 增加 GUI 高度以适应 4 个子图
fig = uifigure('Name', 'Real-time Acceleration and FFT Visualization', 'Position', [100 20 800 850]);

% 创建四个子图 (使用 uiaxes 更适合 uifigure)
ax1 = uiaxes(fig, 'Position', [50 650 700 150]); % 全貌加速度信号
ax2 = uiaxes(fig, 'Position', [50 500 700 150]); % 当前窗口加速度信号
ax3 = uiaxes(fig, 'Position', [50 350 700 150]); % 当前窗口 FFT
ax4 = uiaxes(fig, 'Position', [50 200 700 150]); % 滤掉 n/60 及其谐波后的 FFT

% ---------------------------
% 创建滑块控件
% ---------------------------
% 滑块范围：从1到 (总样本数 - 当前窗口样本数 + 1)
slider = uislider(fig, ...
    'Position', [150, 50, 500, 3], ...
    'Limits', [1, length(time)-windowSamples+1], ...
    'Value', 1);
% 使用 ValueChangingFcn 回调，在滑动过程中实时更新
slider.ValueChangingFcn = @(src, event) updatePlots(round(event.Value), time, accData, samplingRate, windowSize, n, ax1, ax2, ax3, ax4);

% ---------------------------
% 初始化显示
% ---------------------------
updatePlots(round(slider.Value), time, accData, samplingRate, windowSize, n, ax1, ax2, ax3, ax4);

%% 局部函数
function updatePlots(currentIndex, time, accData, samplingRate, windowSize, n, ax1, ax2, ax3, ax4)
    % 计算窗口内样本数
    windowSamples = round(windowSize * samplingRate);
    % 检查越界
    if currentIndex + windowSamples - 1 > length(time)
        currentIndex = length(time) - windowSamples + 1;
    end
    
    % 提取当前时间窗口数据
    windowTime = time(currentIndex:currentIndex+windowSamples-1);
    windowAcc  = accData(currentIndex:currentIndex+windowSamples-1);
    
    % ---------------------------
    % 绘制全貌加速度信号，并用红色矩形框标出当前窗口
    % ---------------------------
    cla(ax1);  % 清除旧图
    plot(ax1, time, accData, 'k'); % 全貌信号（黑色）
    hold(ax1, 'on');
    % 计算矩形框：位置 [x, y, width, height]
    x_rect    = windowTime(1);
    y_rect    = min(accData);
    width_rect = windowTime(end) - windowTime(1);
    height_rect = max(accData) - min(accData);
    rectangle(ax1, 'Position', [x_rect, y_rect, width_rect, height_rect], ...
        'EdgeColor', 'r', 'LineWidth', 2);
    hold(ax1, 'off');
    title(ax1, 'Full-time Acceleration Signal');
    xlabel(ax1, 'Time (s)');
    ylabel(ax1, 'Acceleration (m/s^2)');
    
    % ---------------------------
    % 绘制当前时间窗口的加速度信号
    % ---------------------------
    cla(ax2);
    plot(ax2, windowTime, windowAcc, 'r');
    title(ax2, 'Current Window Acceleration Signal');
    xlabel(ax2, 'Time (s)');
    ylabel(ax2, 'Acceleration (m/s^2)');
    
    % ---------------------------
    % 计算并绘制当前窗口的 FFT (使用 f010_fourier)
    % ---------------------------
    cla(ax3);
    [f, X_f] = f010_fourier(windowTime, windowAcc);
    plot(ax3, f, X_f);
    title(ax3, 'Current Window FFT');
    xlabel(ax3, 'Frequency (Hz)');
    ylabel(ax3, 'Magnitude');
    xlim(ax3, [0 2000]);
    
    % ---------------------------
    % 滤除 n/60 及其谐波后绘制 FFT
    % ---------------------------
    cla(ax4);
    % 设定滤除频率：主频及其谐波
    fundamental = n/60; % 例如 11000/60 ≈ 183.33 Hz
    % tolerance = (f(2)-f(1))/2; % 容差设为频率分辨率的一半
    tolerance = 10;
    filtered_X_f = X_f;
    % 计算最大谐波阶数
    maxHarmonic = floor(max(f)/fundamental);
    for m = 1:maxHarmonic
        idx = abs(f - m*fundamental) < tolerance;
        filtered_X_f(idx) = 0;
    end
    plot(ax4, f, filtered_X_f);
    title(ax4, 'Filtered FFT (without n/60 and harmonics)');
    xlabel(ax4, 'Frequency (Hz)');
    ylabel(ax4, 'Magnitude');
    xlim(ax4, [0 2000]);
    ylim(ax4, ax3.YLim);
    
    drawnow;
end
