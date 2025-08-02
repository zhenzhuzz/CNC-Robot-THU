clc;
clear;
close all;

% Step 1: Load the table using f040_load_table_05 function
% 步骤 1：使用 f040_load_table_05 函数加载表格
dataSheet = f040_load_table_05('EXP05'); % Ensure the table name is passed here

%% Step 2: Load idle data
% 步骤 2：加载空闲数据表格
dataSheet_idle = f040_load_table_05('EXP05_idle'); % Load the idle data sheet

n = 6000;  % 设置目标转速为 9000
ap = 9;    % 设置目标 ap 为 8

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

% Step 4: Create a figure with 2 subplots (removing the ones for subplot2 and subplot4)
% 步骤 4：创建一个包含 2 个子图的图形
figure('Units','centimeters','Position',[5 2 7 6]);

% Step 5: Plot timestamps vs accX in the first subplot
% 步骤 5：在第一个子图中绘制时间戳与 accX 的关系
ax1 = subplot(2, 1, 1);
plot(ax1, timestamps, accX,'Color',[0.5 0.5 0.5]);
f030_optimizeFig_Paper_05(ax1, '{\it t} (s)', '{\it a_x} (g)','','tight',[-4 4]);

% Step 6: Calculate the FFT of accX in the 8-9 second range
% 步骤 6：计算 8-9 秒区间内 accX 的 FFT
start_time = 8;  % 起始时间
end_time = 9;    % 结束时间
idx = timestamps >= start_time & timestamps <= end_time;
t_selected = timestamps(idx);
accX_selected = accX(idx);

[f, X_f] = f010_fourier_05(t_selected, accX_selected, true);

% Step 7: Plot the FFT of accX in the third subplot
% 步骤 7：在第三个子图中绘制 accX 的 FFT
ax2 = subplot(2, 1, 2); % Adjusted to use only the first subplot
plot(ax2, f, X_f, 'HandleVisibility','off','LineWidth',1.2);
hold on;

% Step 8: Process FFT and find top frequencies
% 步骤 8：处理 FFT 幅值并查找前 N 个频率
topN = 3; % We want to find the top 1 frequency
fMax = max(f); % Maximum frequency in the FFT result
tol = 10; % Tolerance for harmonic matching

% Call the function to find top frequencies and match them with spindle harmonics
% 调用函数以查找前 N 个频率并将它们与主轴谐波匹配
[topFreq, topAmp, matchResult] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f, topN, spinFreq, fMax, tol);

% Step 9: Plot the top frequency markers
% 步骤 9：绘制前 N 个频率的标记
for i = 1:length(topFreq)
    if matchResult(i)
        % Plot top frequencies that match the spindle harmonics (e.g., as 'v' marker)
        % 绘制与主轴谐波匹配的频率（例如使用 'v' 标记）
        plot(topFreq(i), topAmp(i), 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'none', 'MarkerSize', 6, 'LineWidth', 1.3);
    else
        % Plot top frequencies that do not match the spindle harmonics (e.g., as 'p' marker)
        % 绘制不匹配主轴谐波的频率（例如使用 'p' 标记）
        plot(topFreq(i), topAmp(i), 'p', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'LineWidth', 1.3);
    end
end

f030_optimizeFig_Paper_05(ax2, '{\it f} (Hz)', '|X(\it f)|', '',[0 2000],[0 1.5]);
f032_legend_05(ax2,{'{\it f}_C'},'FontName','Times New Roman')

f060_saveFigPNG_asFileName_05(mfilename("fullpath"))