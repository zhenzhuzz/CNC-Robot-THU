clc;
clear;
close all;

% Step 1: Load the table using f040_load_table_05 function
% 步骤 1：使用 f040_load_table_05 函数加载表格
dataSheet = f040_load_table_05('EXP05_variable'); % 确保传递正确的表格名称

% Step 2: Load idle data
% 步骤 2：加载空闲数据表格
dataSheet_idle = f040_load_table_05('EXP05_idle'); % Load the idle data sheet
%%
n = 5000;  % 目标转速设置为 5000
n1 = 7000;
ap = 10;    % 目标 ap 设置为 8

topN = 3;  % 设置要查找的最高频率数目为 3
tol = 10;  % 设定用于谐波匹配的容差

% 查找转速为 n 且 ap 为 8 的行索引
i = find(dataSheet.n == n & dataSheet.ap == ap);  % 查找转速为 n 且 ap 为 8 的行索引

if isempty(i)
    error('未找到转速为 %d 且 ap 为 %d 的数据。', n, ap);  % 如果未找到数据，报错
end

% 获取对应文件的路径并加载数据
filePath = dataSheet.path{i}; 
data = load(filePath);  % 加载文件数据

%% Step 3: Extract columns from the loaded data
% 步骤 3：从加载的数据中提取列
timestamps = data(:, 1);  % 第一列是时间戳
accX = data(:, 2);        % 第二列是 accX 加速度数据
spinSpeed = data(:, 3);   % 第三列是旋转速度（转速）

% 计算主轴频率 (spinFreq)
% 计算旋转频率 (spinFreq)
spinFreq5000 = n / 60; % 将转速从 rpm 转换为 Hz（除以 60）
spinFreq7000 = n1 / 60;
%% Step 4: Create a figure with 2 subplots
% 步骤 4：创建一个包含 2 个子图的图形
figure('Units', 'centimeters', 'Position', [5 15 13 7]);

% Step 6: Plot timestamps vs spinSpeed in the second subplot
% 步骤 6：在第二个子图中绘制时间戳与 spinSpeed 的关系
subplot(2, 1, 1);
plot(timestamps, spinSpeed,'LineWidth',1.2);
f030_optimizeFig_Paper_05(gca, '{\it t} (s)', '{\it n} (rpm)', '', 'tight',[4500 7500]);

% Step 5: Plot timestamps vs accX in the first subplot
% 步骤 5：在第一个子图中绘制时间戳与 accX 的关系
subplot(2,1,2);
plot(timestamps, accX, 'Color',[0.5 0.5 0.5]);  % 绘制 accX 随时间变化的图
f030_optimizeFig_Paper_05(gca, '{\it t} (s)', '{\it a_x} (g)', '', 'tight','tight');

f060_saveFigPNG_asFileName_05(mfilename("fullpath"),true);
%% Step 6: Plot data in a different time range (8-9 seconds)
% 步骤 6：在 8-9 秒时间区间内绘制 accX 数据
figure('Units', 'centimeters', 'Position', [5 8 13 3]);
subplot(1, 2, 1);  % 创建第二个子图
plot(timestamps(timestamps >= 8 & timestamps <= 9), accX(timestamps >= 8 & timestamps <= 9), 'r');
f030_optimizeFig_Paper_05(gca, '{\it t} (s)', '{\it a_x} (g)', '', 'tight', [-1.3 1.3]);

subplot(1, 2, 2);  % 创建第二个子图
plot(timestamps(timestamps >= 18 & timestamps <= 19), accX(timestamps >= 18 & timestamps <= 19), 'b');
f030_optimizeFig_Paper_05(gca, '{\it t} (s)', '{\it a_x} (g)', '', 'tight', [-1.3 1.3]);

f060_saveFigPNG_asFileName_05(mfilename("fullpath"),false);

%% Step 7: Calculate the FFT of accX in the 8-9 second range
% 步骤 7：计算 8-9 秒区间内 accX 的 FFT
figure('Units', 'centimeters', 'Position', [5 2 13 3]);
subplot(1, 2, 1);
[f, X_f] = f010_fourier_05(timestamps(timestamps >= 8 & timestamps <= 9), accX(timestamps >= 8 & timestamps <= 9), true);

plot(f, X_f, 'HandleVisibility', 'off','LineWidth',1.2);  % 绘制 FFT 结果
hold on;

% Step 11: Apply frequency filtering
% 步骤 11：应用频率滤波
% Get the frequencies from the idle dataSheet for n = 9000
j = find(dataSheet_idle.n == n);  % Find correct index
if isempty(j)
    error('未找到转速为 %d 且 ap 为 %d 的空闲数据。', n);
end

% Extract the frequencies and set the tolerance
freq1 = dataSheet_idle.freq1(j);
freq2 = dataSheet_idle.freq2(j);
freq3 = dataSheet_idle.freq3(j);
freq4 = dataSheet_idle.freq4(j);
freq5 = dataSheet_idle.freq5(j);
frequencies = [freq1, freq2, freq3, freq4, freq5];

% Call function to filter the FFT magnitudes
% 调用函数滤波 FFT 幅度
[X_f] = f070_filterFreqs_05(f, X_f, frequencies, tol);



% 调用函数以查找前 N 个频率并将它们与主轴谐波匹配
[topFreq, topAmp, matchResult] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f, topN, spinFreq5000, max(f), tol);

% 步骤 9：绘制前 N 个频率的标记
for i = 1:length(topFreq)
    if matchResult(i)
        % 如果频率匹配主轴谐波，绘制 'v' 标记
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.3);
    else
        % 如果频率不匹配主轴谐波，绘制 'p' 标记
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'LineWidth', 1.3);
    end
end

f030_optimizeFig_Paper_05(gca, '{\it f} (Hz)', '|X(\it f)|','',[0 2000],[0 0.5]);
f032_legend_05(gca, {'{\it f}_{C}'}, 'FontName', 'Times New Roman');

% Step 10: Plot FFT for a different time range (18-19 seconds)
% 步骤 10：在 18-19 秒区间内绘制 accX 的 FFT
subplot(1, 2, 2);  % 创建第二个子图
[f, X_f] = f010_fourier_05(timestamps(timestamps >= 18 & timestamps <= 19), accX(timestamps >= 18 & timestamps <= 19), true);

% Step 11: Apply frequency filtering
% 步骤 11：应用频率滤波
% Get the frequencies from the idle dataSheet for n = 9000
j = find(dataSheet_idle.n == n1);  % Find correct index
if isempty(j)
    error('未找到转速为 %d 且 ap 为 %d 的空闲数据。', n1);
end

% Extract the frequencies and set the tolerance
freq1 = dataSheet_idle.freq1(j);
freq2 = dataSheet_idle.freq2(j);
freq3 = dataSheet_idle.freq3(j);
freq4 = dataSheet_idle.freq4(j);
freq5 = dataSheet_idle.freq5(j);
frequencies = [freq1, freq2, freq3, freq4, freq5];

% Call function to filter the FFT magnitudes
% 调用函数滤波 FFT 幅度
[X_f] = f070_filterFreqs_05(f, X_f, frequencies, tol);

plot(f, X_f, 'HandleVisibility', 'off','LineWidth',1.2);  % 绘制 FFT 结果
hold on;

% 再次处理 FFT 并查找前 N 个频率
[topFreq, topAmp, matchResult] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f, topN, spinFreq7000, max(f), tol);

% 绘制前 N 个频率的标记
for i = 1:length(topFreq)
    if matchResult(i)
        % 如果频率匹配主轴谐波，绘制 'v' 标记
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.3);
    else
        % 如果频率不匹配主轴谐波，绘制 'p' 标记
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'LineWidth', 1.3);
    end
end

f030_optimizeFig_Paper_05(gca, '{\it f} (Hz)', '|X(\it f)|','',[0 2000],[0 0.5]);
f032_legend_05(gca, {'{\it f}_{SP}'}, 'FontName', 'Times New Roman');

f060_saveFigPNG_asFileName_05(mfilename("fullpath"),false);