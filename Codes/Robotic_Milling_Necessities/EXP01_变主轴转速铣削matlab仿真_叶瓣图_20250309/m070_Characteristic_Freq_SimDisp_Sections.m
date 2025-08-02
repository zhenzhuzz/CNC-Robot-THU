% 清除环境变量
clear; clc;
clear f040_saveFigPNG_asFileName_01

% ---------------------------
% 参数设置
% ---------------------------
filepath = 'MillingData_n4520_8200_10000_ap222_fr4.5e+02_z4_t1.txt';

%% （在 script 开头加入转速参数）
spindleSpeed1 = 4520; % rpm
spindleSpeed2 = 8200; % rpm
spindleSpeed3 = 10000; % rpm

% 计算主轴旋转频率（Hz）
f_sp1 = spindleSpeed1 / 60;
f_sp2 = spindleSpeed2 / 60;
f_sp3 = spindleSpeed3 / 60;


samplingRate = 25600;   % 采样率 (Hz)
windowSize    = 0.2;    % 时间窗口 (秒)
windowSamples = round(windowSize * samplingRate);
figReset = 0;

% ---------------------------
% 读取数据 (只读取 X 方向)
% ---------------------------
dataMatrix = f020_readAcc(filepath, 'X');  % f020_readAcc 只返回 [time, Acc_X]
time   = dataMatrix(:, 1);
accData = dataMatrix(:, 2);

% ---------------------------
% 对数据进行均匀化插值
% ---------------------------
uniformTime = (time(1) : 1/samplingRate : time(end))';
uniformAcc = interp1(time, accData, uniformTime, 'linear', 'extrap');
time   = uniformTime;
accData = uniformAcc * 1e3;  % 单位换算

% ---------------------------
% 创建第一个 figure: 时域呈现（灰色线，tickLength [0.01 0.01]）
% ---------------------------
fig1 = figure(1);
if figReset
    set(fig1, 'Units', 'centimeters', 'Position', [10 5 15 4]);
end
clf(fig1);  % 清除旧内容

% 用灰色绘制
plot(time, accData, 'Color', [0.5, 0.5, 0.5]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.01, 0.01]);

% 保存第一个图
f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);

% ---------------------------
% 创建第二个 figure: 分三个子图显示不同时间段的数据 (tickLength [0.03 0.03])
% ---------------------------
fig2 = figure(2);
if figReset
    set(fig2, 'Units', 'centimeters', 'Position', [10 5 15 4]);
end
clf(fig2);  % 清除旧内容

subplot(1, 3, 1);
plot(time(time >= 0.1 & time <= 0.3), accData(time >= 0.1 & time <= 0.3), 'r');
ylim([-2, 2]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.03, 0.03]);

subplot(1, 3, 2);
plot(time(time >= 0.4 & time <= 0.6), accData(time >= 0.4 & time <= 0.6), 'g');
ylim([-2, 2]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.03, 0.03]);

subplot(1, 3, 3);
plot(time(time >= 0.8 & time <= 1.0), accData(time >= 0.8 & time <= 1.0), 'b');
ylim([-2, 2]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.03, 0.03]);

% 保存第二个图
f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);

% ---------------------------
% 创建第三个 figure: 分三个子图显示 FFT 归一化后的幅值 (tickLength [0.03 0.03])
% 并在每个子图中标记幅值最高的3个频率点
% ---------------------------
fig3 = figure(3);
if figReset
    set(fig3, 'Units', 'centimeters', 'Position', [10 5 15 4]);
end
clf(fig3);  % 清除旧内容

% Subplot1: 时间段 0.1-0.3 s，找 top 3
subplot(1, 3, 1);
[f, X_f] = f011_fourier_01(time(time >= 0.1 & time <= 0.3), accData(time >= 0.1 & time <= 0.3), true);
plot(f, X_f, 'r','LineWidth',1.3);
xlim([0 1000]);
ylim([0 1]);
[topFreq, topAmp] = f050_findTopNFreq_01(f, X_f, 3);
hold on;
plot(topFreq, topAmp, 'rv', 'MarkerFaceColor', 'none', 'MarkerSize', 4,'LineWidth',1);
f030_optimizeFig_Paper_01(gca, '{\it f} (Hz)', '|{\it X}({\it f})|', '', {}, 'northeast', [0.03, 0.03]);

% Subplot2: 时间段 0.4-0.6 s，找 top 3
subplot(1, 3, 2);
[f, X_f] = f011_fourier_01(time(time >= 0.4 & time <= 0.6), accData(time >= 0.4 & time <= 0.6), true);
plot(f, X_f, 'g','LineWidth',1.3);
xlim([0 1000]);
ylim([0 1]);
[topFreq, topAmp] = f050_findTopNFreq_01(f, X_f, 3);
hold on;
plot(topFreq, topAmp, 'gv', 'MarkerFaceColor', 'none', 'MarkerSize', 4,'LineWidth',1);
f030_optimizeFig_Paper_01(gca, '{\it f} (Hz)', '|{\it X}({\it f})|', '', {}, 'northeast', [0.03, 0.03]);

% Subplot3: 时间段 0.8-1.0 s，找 top 1
subplot(1, 3, 3);
[f, X_f] = f011_fourier_01(time(time >= 0.8 & time <= 1.0), accData(time >= 0.8 & time <= 1.0), true);
plot(f, X_f, 'b','LineWidth',1.3);
xlim([0 1000]);
ylim([0 0.05]);
[topFreq, topAmp] = f050_findTopNFreq_01(f, X_f, 1);
hold on;
plot(topFreq, topAmp, 'bv', 'MarkerFaceColor', 'none', 'MarkerSize', 4,'LineWidth',1);
f030_optimizeFig_Paper_01(gca, '{\it f} (Hz)', '|{\it X}({\it f})|', '', {}, 'northeast', [0.03, 0.03]);

% 保存第三个图
f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);


