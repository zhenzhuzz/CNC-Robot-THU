clc;
clear;
close all;
clear f040_saveFigPNG_asFileName_01

%% 参数设置
samplingRate = 25600;   % 采样率 (Hz)
windowSize    = 0.3;    % 时间窗口 (秒)
windowSamples = round(windowSize * samplingRate);

%% 文件路径设置
filepath1 = 'MillingData_n4520_ap2_fr4.5e+02_z4_t1.txt';
filepath2 = 'MillingData_n4520_8200_10000_ap222_fr4.5e+02_z4_t1.txt';

%% 读取并处理第一个文件
dataMatrix1 = f020_readAcc(filepath1, 'Y');  % 返回 [time, Acc_X]
time1   = dataMatrix1(:, 1);
accData1 = dataMatrix1(:, 2);

% 均匀化插值
uniformTime1 = (time1(1) : 1/samplingRate : time1(end))';
uniformAcc1  = interp1(time1, accData1, uniformTime1, 'linear', 'extrap');
time1   = uniformTime1;
accData1 = uniformAcc1;

%% 读取并处理第二个文件
dataMatrix2 = f020_readAcc(filepath2, 'Y');  
time2   = dataMatrix2(:, 1);
accData2 = dataMatrix2(:, 2);

% 均匀化插值
uniformTime2 = (time2(1) : 1/samplingRate : time2(end))';
uniformAcc2  = interp1(time2, accData2, uniformTime2, 'linear', 'extrap');
time2   = uniformTime2;
accData2 = uniformAcc2;

%% 绘图（扁平的 Figure 尺寸）
figure('Units','centimeters','Position',[2 2 15 4]); % 宽15cm，高4.5cm，适合论文
hold on;

% 定义偏青且明亮的颜色（亮青）及透明度
brightCyan = [0, 0.9, 0.9];  
plot(time1, accData1*1e3, 'Color', [brightCyan, 0.3], 'LineWidth', 1);

% 绘制第二个数据集，使用蓝色
plot(time2, accData2*1e3, 'b', 'LineWidth', 1);

%% 设置坐标轴范围
ylim([-2, 2]);

%% 调用外置函数优化Figure
% 此函数会设置坐标轴字体、网格、标签、图例以及外框
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', ...
    {'4520 rpm', '4520-8200-1000 rpm'}, 'northeast', [0.01, 0.01]);

%% 调用外置函数保存图形为PNG（高分辨率1500 DPI）
f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);
