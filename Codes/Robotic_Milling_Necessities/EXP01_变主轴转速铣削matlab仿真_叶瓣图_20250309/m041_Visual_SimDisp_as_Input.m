%% m060_realtime_acc_fft_gui.m
% 交互式GUI：实时显示加速度数据及其FFT
% 注意：请确保 f020_readAcc.m 和 f010_fourier.m 在当前路径下

% 清除环境变量
clear; close all; clc;

% ---------------------------
% 参数设置
% ---------------------------
% filepath = 'E:\EXP\YM\Acc2Surf\Figures\VaryApAcc\Acc\s11000d05-40f1700.txt';
% filepath = 'E:\EXP\YM\EXP20211020\LMS\3-3_s10000d10f1500_C.txt';
filepath = 'MillingData_n4520_8200_10000_ap222_fr4.5e+02_z4_t1.txt';

samplingRate = 25600;   % 采样率 (Hz)
windowSize    = 0.2;    % 时间窗口 (秒)
windowSamples = round(windowSize * samplingRate);

% ---------------------------
% 读取数据 (只读取 X 方向)
% ---------------------------
dataMatrix = f020_readAcc(filepath, 'X');  % f020_readAcc 只返回 [time, Acc_X]
time   = dataMatrix(:, 1);
accData = dataMatrix(:, 2);

% ---------------------------
% 对数据进行均匀化插值
% ---------------------------
% 构造均匀时间向量，从原始时间起点到终点，采样间隔为 1/samplingRate
uniformTime = (time(1) : 1/samplingRate : time(end))';
% 对加速度数据进行线性插值
uniformAcc = interp1(time, accData, uniformTime, 'linear', 'extrap');
% 用均匀化的数据替换原始数据
time   = uniformTime;
accData = uniformAcc;

% ---------------------------
% 创建GUI界面
% ---------------------------
% 创建 uifigure（现代 GUI 窗口）
fig = uifigure('Name', 'Real-time Acceleration and FFT Visualization', 'Position', [100 100 800 600]);

% 创建三个子图 (使用 uiaxes 更适合 uifigure)
ax1 = uiaxes(fig, 'Position', [50 400 700 150]); % 全貌加速度信号
ax2 = uiaxes(fig, 'Position', [50 230 700 150]); % 当前窗口加速度信号
ax3 = uiaxes(fig, 'Position', [50 60 700 150]);  % 当前窗口 FFT

% ---------------------------
% 创建滑块控件
% ---------------------------
% 滑块范围：从1到 (总样本数 - 当前窗口样本数 + 1)
slider = uislider(fig, ...
    'Position', [150, 20, 500, 3], ...
    'Limits', [1, length(time)-windowSamples+1], ...
    'Value', 1);
% 使用 ValueChangingFcn 回调，在滑动过程中实时更新
slider.ValueChangingFcn = @(src, event) updatePlots(round(event.Value), time, accData, samplingRate, windowSize, ax1, ax2, ax3);

% ---------------------------
% 初始化显示
% ---------------------------
updatePlots(round(slider.Value), time, accData, samplingRate, windowSize, ax1, ax2, ax3);

%% 局部函数
function updatePlots(currentIndex, time, accData, samplingRate, windowSize, ax1, ax2, ax3)
    % 计算窗口内样本数（基于均匀化后的采样率）
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
    xlim(ax3,[0 2000]);
    title(ax3, '当前时间窗的FFT');
    xlabel(ax3, '频率 (Hz)');
    ylabel(ax3, '幅值');

    drawnow;
end
