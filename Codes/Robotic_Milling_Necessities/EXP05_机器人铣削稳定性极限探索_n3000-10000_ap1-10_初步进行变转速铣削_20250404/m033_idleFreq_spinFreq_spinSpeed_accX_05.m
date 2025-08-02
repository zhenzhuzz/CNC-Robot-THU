clc;
clear;
% close all;

% Step 1: Load the table using f040_load_table_05 function
% 步骤 1：使用 f040_load_table_05 函数加载表格
dataSheet = f040_load_table_05('EXP05'); % Ensure the table name is passed here

%% Step 2: Load idle data
% 步骤 2：加载空闲数据表格
dataSheet_idle = f040_load_table_05('EXP05_idle'); % Load the idle data sheet

n = 5000;  % 设置目标转速为 9000
ap = 8;    % 设置目标 ap 为 8

% 查找转速为 n 且 ap 为 10 的行索引
i = find(dataSheet.n == n & dataSheet.ap == ap);  % 查找转速为 n 且 ap 为 10 的行索引

if isempty(i)
    error('未找到转速为 %d 且 ap 为 %d 的数据。', n, ap);
end

% 获取对应文件的路径并加载数据
filePath = dataSheet.path{i}; 
data = load(filePath);  % 加载文件

% Step 3: Extract columns from the loaded data
% 步骤 3：从加载的数据中提取列
timestamps = data(:, 1);  % 第一列是时间戳
accX = data(:, 2);        % 第二列是 accX
spinSpeed = data(:, 3);   % 第三列是 spinSpeed

% Calculate spin frequency (spinFreq)
% 计算主轴频率 (spinFreq)
spinFreq = n / 60; % Convert rpm to Hz (dividing by 60)

% Step 4: Create a figure with 4 subplots
% 步骤 4：创建一个包含 4 个子图的图形
figure('Units','centimeters','Position',[5 2 15 20]);

% Step 5: Plot timestamps vs accX in the first subplot
% 步骤 5：在第一个子图中绘制时间戳与 accX 的关系
ax1 = subplot(4, 1, 1);
plot(ax1, timestamps, accX);
f030_optimizeFig_Paper_05(ax1, 'Timestamps (s)', 'Acceleration (g)', 'Acceleration vs Timestamps');

% Step 6: Plot timestamps vs spinSpeed in the second subplot
% 步骤 6：在第二个子图中绘制时间戳与 spinSpeed 的关系
ax2 = subplot(4, 1, 2);
plot(ax2, timestamps, spinSpeed);
f030_optimizeFig_Paper_05(ax2, 'Timestamps (s)', 'Spin Speed (rpm)', 'Spin Speed vs Timestamps');

% Step 7: Calculate the FFT of accX in the 8-9 second range
% 步骤 7：计算 8-9 秒区间内 accX 的 FFT
start_time = 8;  % 起始时间
end_time = 9;    % 结束时间
idx = timestamps >= start_time & timestamps <= end_time;
t_selected = timestamps(idx);
accX_selected = accX(idx);

[f, X_f] = f010_fourier_05(t_selected, accX_selected, true);

% Step 8: Plot the FFT of accX in the third subplot
% 步骤 8：在第三个子图中绘制 accX 的 FFT
ax3 = subplot(4, 1, 3);
plot(ax3, f, X_f);
hold on;

% Step 9: Process FFT and find top frequencies
% 步骤 9：处理 FFT 幅值并查找前 N 个频率
topN = 1; % We want to find the top 1 frequency
fMax = max(f); % Maximum frequency in the FFT result
tol = 10; % Tolerance for harmonic matching

% Call the function to find top frequencies and match them with spindle harmonics
% 调用函数以查找前 N 个频率并将它们与主轴谐波匹配
[topFreq, topAmp, matchResult] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f, topN, spinFreq, fMax, tol);

% Step 10: Plot the top frequency markers
% 步骤 10：绘制前 N 个频率的标记
for i = 1:length(topFreq)
    if matchResult(i)
        % Plot top frequencies that match the spindle harmonics (e.g., as 'v' marker)
        % 绘制与主轴谐波匹配的频率（例如使用 'v' 标记）
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5);
    else
        % Plot top frequencies that do not match the spindle harmonics (e.g., as 'p' marker)
        % 绘制不匹配主轴谐波的频率（例如使用 'p' 标记）
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'c', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5);
    end
end

f030_optimizeFig_Paper_05(ax3, 'Frequency (Hz)', 'Magnitude', 'FFT of Acceleration (8-9 seconds)');

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
[X_f_filtered] = filterFFT(f, X_f, frequencies, tol);

% Step 12: Plot the filtered FFT in the fourth subplot
% 步骤 12：在第四个子图中绘制滤波后的 FFT
ax4 = subplot(4, 1, 4);
plot(ax4, f, X_f_filtered);
hold on;

% Step 13: Find and plot the top frequencies in the filtered FFT plot
% 步骤 13：在滤波后的 FFT 图中查找并绘制前 N 个频率
[topFreq_filtered, topAmp_filtered, matchResult_filtered] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f_filtered, topN, spinFreq, fMax, tol);

for i = 1:length(topFreq_filtered)
    if matchResult_filtered(i)
        % Plot top frequencies that match the spindle harmonics (e.g., as 'v' marker)
        % 绘制与主轴谐波匹配的频率（例如使用 'v' 标记）
        plot(topFreq_filtered(i), topAmp_filtered(i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5);
    else
        % Plot top frequencies that do not match the spindle harmonics (e.g., as 'p' marker)
        % 绘制不匹配主轴谐波的频率（例如使用 'p' 标记）
        plot(topFreq_filtered(i), topAmp_filtered(i), 'p', 'MarkerEdgeColor', 'c', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.5);
    end
end

f030_optimizeFig_Paper_05(ax4, 'Frequency (Hz)', 'Magnitude', 'Filtered FFT of Acceleration');

% ------------------------------- Helper function to filter the FFT -------------------------------
function [X_f_filtered] = filterFFT(f, X_f, frequencies, tol)
    % 过滤掉与频率相差 ±tol 的频率
    % Function to remove frequencies within the tolerance of given frequencies
    X_f_filtered = X_f;  % Initialize the filtered FFT to the original
    for i = 1:length(frequencies)
        % Remove frequencies within the tolerance range
        freq_mask = abs(f - frequencies(i)) < tol;
        X_f_filtered(freq_mask) = 0;  % Set corresponding FFT magnitudes to zero
    end
end
