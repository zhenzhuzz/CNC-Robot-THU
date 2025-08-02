%% m010_plot_XYZ_Acc_Weizhen_2Segments_FFT.m
clc;
clear;
close all;

%% 数据读取
filepath = '11.txt';
data = f021_readAcc_WeiZhen(filepath, 'XYZ');
time = data.Time;
X = data.X;

%% FFT分析（两段）
segments = [17 18; 27 28];
f_cell = cell(1,2);
X_mag_cell = cell(1,2);

for i = 1:size(segments,1)
    idx = (time >= segments(i,1)) & (time <= segments(i,2));
    time_seg = time(idx);
    X_seg = X(idx);

    % 调用你自己的函数进行FFT计算
    [f, X_mag] = f010_fourier(time_seg, X_seg);
    
    f_cell{i} = f;
    X_mag_cell{i} = X_mag;
end

%% FFT 绘图
figure('Units','centimeters','Position',[2 2 20 5]);
hold on;

plot(f_cell{1}, X_mag_cell{1}, '-', 'LineWidth', 1.2);
plot(f_cell{2}, X_mag_cell{2}, '-', 'LineWidth', 1.2);

xlim([2 200]); % 根据需求手动指定范围
ylim auto;     % 自动适应幅值范围

% 调用你的论文优化函数
f030_optimizeFig_Paper_02(gca, ...
    '频率 (Hz)', ...
    '幅值', ...
    'X方向加速度频谱图 (两段时间对比)', ...
    {'17-18 s', '27-28 s'}, ...
    'northeast');

% 保存FFT图为高分辨率PNG文件
[filepath,name,~] = fileparts(mfilename('fullpath'));
fileName = ['p', name(2:end), '.png']; % 把开头的m替换成p
print(gcf, fileName, '-dpng', '-r1500');

