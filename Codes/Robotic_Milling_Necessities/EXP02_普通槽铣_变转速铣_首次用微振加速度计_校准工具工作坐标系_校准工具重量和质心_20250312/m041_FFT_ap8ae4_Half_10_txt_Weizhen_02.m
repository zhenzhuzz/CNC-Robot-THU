%% m010_plot_XYZ_Acc_WeiZhen_3Segments_FFT.m
clc;
clear;
close all;

%% 读取数据
filepath = '10.txt';
data = f021_readAcc_WeiZhen(filepath, 'XYZ');
time = data.Time;
X = data.X;

%% 定义三个时间段
segments = {
    [5, 6],    ... 第一段：5-6秒
    [13, 14],  ... 第二段：13-14秒
    [19, 20]   ... 第三段：19-20秒
};

f_cell = cell(1,3);
X_mag_cell = cell(1,3);

%% FFT分析
for i = 1:length(segments)
    t_start = segments{i}(1);
    t_end = segments{i}(2);

    idx = (time >= t_start) & (time <= t_end);
    time_seg = time(idx);
    X_seg = X(idx);

    % 调用你的函数f010_fourier
    [f, X_mag] = f010_fourier(time_seg, X_seg);

    f_cell{i} = f;
    X_mag_cell{i} = X_mag;
end


%% 绘制三段FFT结果
figure('Units','centimeters','Position',[2 2 20 5]);
hold on;

plot(f_cell{1}, X_mag_cell{1}, '-', 'LineWidth', 1.2);
plot(f_cell{2}, X_mag_cell{2}, '-', 'LineWidth', 1.2);
plot(f_cell{3}, X_mag_cell{3}, '-', 'LineWidth', 1.2);

% 手动明确设定坐标范围（推荐）
xlim([2 200]);
ylim([0 110]);

% 调用优化函数（替代原有手动优化）
f030_optimizeFig_Paper_02(gca, ...
    '频率 (Hz)', ...
    '幅值', ...
    '三段转速下的频谱变化', ...
    {'2500rpm', '3300rpm', '5000rpm'}, ...
    'northeast');

%% 保存图形为PNG文件（1500 DPI）
f040_saveFigPNG(mfilename('fullpath'));  % 默认1500 dpi，默认gcf

