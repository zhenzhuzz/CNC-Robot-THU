%% 主脚本
clear; clc;
clear f040_saveFigPNG_asFileName_01  % 重置 persistent 变量

% ---------------------------
% 参数设置
% ---------------------------
filepath = 'MillingData_n4520_8200_10000_ap222_fr4.5e+02_z4_t1.txt';
samplingRate = 25600;   % 采样率 (Hz)
windowSize    = 0.2;    % 时间窗口 (秒)
windowSamples = round(windowSize * samplingRate);
figReset = 1;

% ---------------------------
% 读取数据 (只读取 X 方向)
% ---------------------------
dataMatrix = f020_readAcc(filepath, 'X');  % f020_readAcc 返回 [time, Acc_X]
time   = dataMatrix(:, 1);
accData = dataMatrix(:, 2);

% ---------------------------
% 对数据进行均匀化插值
% ---------------------------
uniformTime = (time(1):1/samplingRate:time(end))';
uniformAcc = interp1(time, accData, uniformTime, 'linear', 'extrap');
time   = uniformTime;
accData = uniformAcc * 1e3;  % 单位转换：m/s^2 -> mm/s^2

% ---------------------------
% 主轴转速及其对应频率（Hz）
% ---------------------------
spindleSpeed1 = 4520; % rpm
spindleSpeed2 = 8200; % rpm
spindleSpeed3 = 10000; % rpm
f_sp1 = spindleSpeed1 / 60;
f_sp2 = spindleSpeed2 / 60;
f_sp3 = spindleSpeed3 / 60;
tolMarker = 5;  % Hz，用于匹配主轴及谐波时的容差

%% Figure 1: 时域图（灰色曲线, tickLength [0.01, 0.01]）
fig1 = figure(1);
if figReset
    set(fig1, 'Units', 'centimeters', 'Position', [10 5 15 4]);
end
clf(fig1);
plot(time, accData, 'Color', [0.5, 0.5, 0.5]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.01, 0.01]);
f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);

%% Figure 2: 分窗时域图 (tickLength [0.03, 0.03])
fig2 = figure(2);
if figReset
    set(fig2, 'Units', 'centimeters', 'Position', [10 5 15 4]);
end
clf(fig2);

subplot(1, 3, 1);
plot(time(time>=0.1 & time<=0.3), accData(time>=0.1 & time<=0.3), 'r');
ylim([-2,2]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.03, 0.03]);

subplot(1, 3, 2);
plot(time(time>=0.4 & time<=0.6), accData(time>=0.4 & time<=0.6), 'g');
ylim([-2,2]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.03, 0.03]);

subplot(1, 3, 3);
plot(time(time>=0.8 & time<=1.0), accData(time>=0.8 & time<=1.0), 'b');
ylim([-2,2]);
f030_optimizeFig_Paper_01(gca, '{\it t} (s)', '{\it v_x} (mm)', '', {}, 'northeast', [0.03, 0.03]);

f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);

%% Figure 3: FFT 分析及峰值标记 (tickLength [0.03, 0.03])
fig3 = figure(3);
if figReset
    set(fig3, 'Units', 'centimeters', 'Position', [10 5 15 4]);
end
clf(fig3);

%% Subplot 1: 时间段 0.1-0.3 s, 红色, 提取 top3
subplot(1,3,1);
[f, X_f] = f011_fourier_01(time(time>=0.1 & time<=0.3), accData(time>=0.1 & time<=0.3), true);
plot(f, X_f, 'r', 'LineWidth', 1.3, 'HandleVisibility','off');
xlim([0,1000]); ylim([0,1]);
hold on;
[topFreq, topAmp] = findTopNFreq(f, X_f, 3);
matchResult = TopMatchedSpin(topFreq, f_sp1, tolMarker, max(f));
for i = 1:length(topFreq)
    if matchResult(i)
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'none', 'MarkerSize', 4, 'LineWidth', 1);
    else
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'cyan', 'MarkerFaceColor', 'none', 'MarkerSize', 5, 'LineWidth', 1);
    end
end
f030_optimizeFig_Paper_01(gca, '{\it f} (Hz)', '|{\it X}({\it f})|', '', {'{\it f}_{chat}','{\it f}_{TPE}'}, 'northwest', [0.03, 0.03]);
% legend({'f_{chat}','f_{sp}'},'FontName','Times New Roman');
%% Subplot 2: 时间段 0.4-0.6 s, 绿色, 提取 top3
subplot(1,3,2);
[f, X_f] = f011_fourier_01(time(time>=0.4 & time<=0.6), accData(time>=0.4 & time<=0.6), true);
plot(f, X_f, 'g', 'LineWidth', 1.3, 'HandleVisibility','off');
xlim([0,1000]); ylim([0,1]);
hold on;
[topFreq, topAmp] = findTopNFreq(f, X_f, 3);
matchResult = TopMatchedSpin(topFreq, f_sp2, tolMarker, max(f));
for i = 1:length(topFreq)
    if matchResult(i)
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'none', 'MarkerSize', 4, 'LineWidth', 1);
    else
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'cyan', 'MarkerFaceColor', 'none', 'MarkerSize', 5, 'LineWidth', 1);
    end
end

f030_optimizeFig_Paper_01(gca, '{\it f} (Hz)', '|{\it X}({\it f})|', '', {'{\it f}_{chat}','{\it f}_{TPE}'}, 'northwest', [0.03, 0.03]);

%% Subplot 3: 时间段 0.8-1.0 s, 蓝色, 提取 top1
subplot(1,3,3);
[f, X_f] = f011_fourier_01(time(time>=0.8 & time<=1.0), accData(time>=0.8 & time<=1.0), true);
plot(f, X_f, 'b', 'LineWidth', 1.3, 'HandleVisibility','off');
xlim([0,1000]); ylim([0,0.05]);
hold on;
[topFreq, topAmp] = findTopNFreq(f, X_f, 1);
matchResult = TopMatchedSpin(topFreq, f_sp3, tolMarker, max(f));
for i = 1:length(topFreq)
    if 1
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 4, 'LineWidth', 1);
    else
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'cyan', 'MarkerFaceColor', 'none', 'MarkerSize', 5, 'LineWidth', 1);
    end
end

f030_optimizeFig_Paper_01(gca, '{\it f} (Hz)', '|{\it X}({\it f})|', '', {}, 'northeast', [0.03, 0.03]);

f040_saveFigPNG_asFileName_01(mfilename('fullpath'), 1500);

%% ---------------------------
%% Local Functions
%% ---------------------------


function [topNFreq, topNAmp] = findTopNFreq(f, X_f, topN)
    % 查找 FFT 幅值中最大 topN 个峰值对应的频率，要求每个峰值之间至少相差 20Hz
    tol = 20;  % Hz
    [sortedAmp, sortedIdx] = sort(X_f, 'descend');
    topNFreq = [];
    topNAmp = [];
    for i = 1:length(sortedAmp)
        candidateFreq = f(sortedIdx(i));
        candidateAmp = sortedAmp(i);
        if isempty(topNFreq) || all(abs(candidateFreq - topNFreq) >= tol)
            topNFreq(end+1) = candidateFreq;
            topNAmp(end+1) = candidateAmp;
        end
        if length(topNFreq) >= topN
            break;
        end
    end
end

function harmVec = computeSpindleHarmonics(spindleFreq, fMax)
    % 计算主轴旋转频率及其整数倍谐波（在 fMax 范围内）
    harmVec = [];
    k = 1;
    while k * spindleFreq <= fMax
        harmVec(end+1) = k * spindleFreq; %#ok<AGROW>
        k = k + 1;
    end
end

function matchResult = TopMatchedSpin(topFreq, spindleFreq, tol, fMax)
    % 对 topFreq 中的每个频率，判断是否在主轴旋转频率及其谐波附近（tol 内）
    harmVec = computeSpindleHarmonics(spindleFreq, fMax);
    matchResult = false(size(topFreq));
    for i = 1:length(topFreq)
        if any(abs(topFreq(i) - harmVec) < tol)
            matchResult(i) = true;
        end
    end
end
