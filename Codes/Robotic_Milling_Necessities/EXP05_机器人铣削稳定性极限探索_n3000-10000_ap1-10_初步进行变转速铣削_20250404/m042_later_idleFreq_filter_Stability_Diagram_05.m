clc;
clear;
close all;

% Step 1: Load the table using f040_load_table_05 function
% 步骤 1：使用 f040_load_table_05 函数加载表格
dataSheet = f040_load_table_05('EXP05'); % Ensure the table name is passed here
dataSheet_idle = f040_load_table_05('EXP05_idle'); % Ensure the table name is passed here

% Initialize parameters
nRows = 80;  % We are only processing the first 80 rows
topN = 1;     % We are interested in the top 1 frequency
tol = 10;     % Tolerance for harmonic matching
% fMax = 1000;  % Set maximum frequency range (adjust as necessary)

% Initialize the stability results vector
% 初始化稳定性结果列向量
stabilityResults = zeros(nRows, 1);  % 0 for stable, 1 for unstable

% Step 2: Create a new figure for stability map
% 步骤 2：为稳定性图创建一个新图形
figure('Units','centimeters','Position',[5 2 15 15]);

% Step 3: Loop through each row in the dataSheet
% 步骤 3：遍历 dataSheet 的每一行
for i = 1:nRows
    % Extract spindle speed (n) and depth of cut (ap)
    % 提取转速 n 和切深 ap
    n = dataSheet.n(i);    % 转速 n
    ap = dataSheet.ap(i);  % 切深 ap
    
    % Output current n and ap being processed
    % 输出当前处理的 n 和 ap
    disp(['Processing n = ', num2str(n), ', ap = ', num2str(ap)]);
    
    % Get the file path from the path column and load the corresponding data
    % 获取文件路径并加载对应的数据
    filePath = dataSheet.path{i};  % Assuming path is a cell array of strings
    data = load(filePath);  % Load the .txt file
    
    % Extract columns from the loaded data
    % 从加载的数据中提取列
    timestamps = data(:, 1);  % 第一列是时间戳
    accX = data(:, 2);        % 第二列是 accX
    spinSpeed = data(:, 3);   % 第三列是 spinSpeed
    
    % Calculate spin frequency (spinFreq)
    % 计算主轴频率 (spinFreq)
    spinFreq = n / 60; % Convert rpm to Hz (dividing by 60)
    
    % Step 4: Calculate the FFT of accX in the 8-9 second range
    % 步骤 4：计算 8-9 秒区间内 accX 的 FFT
    start_time = 8;  % 起始时间
    end_time = 9;    % 结束时间
    idx = timestamps >= start_time & timestamps <= end_time;
    t_selected = timestamps(idx);
    accX_selected = accX(idx);

    [f, X_f] = f010_fourier_05(t_selected, accX_selected, true);
    
    % Step 5: Process FFT and find top frequencies
    % 步骤 5：处理 FFT 幅值并查找前 N 个频率
    [topFreq, topAmp, matchResult] = f050_processFFTMagnitude_findTopFreq_filterfsp_findfchatter_05(f, X_f, topN, spinFreq, max(f), tol);

    % Step 6: Check if the top frequency matches spindle harmonics
    % 步骤 6：检查 top1 频率是否与主轴谐波匹配
    if matchResult(1)
        % Plot 'v' marker for match
        % 如果匹配，使用 'v' 标记
        marker = 'v';
        markerColor = 'b';  % Blue for stable (matches spindle harmonics)
        stabilityResults(i) = 0;  % Stable (matches spindle harmonics)
        disp('Result: Stable (matches spindle harmonics)');
    else
        % Step 7: If not matching, check against idle frequencies
        % 步骤 7：如果不匹配，检查是否与空闲频率匹配
        j = find(dataSheet_idle.n == n);  % Find correct index (no ap involved)
        if isempty(j)
            error('未找到转速为 %d 的空闲数据。', n);
        end

        % Extract the frequencies from the idle data (freq1 to freq5)
        freq1 = dataSheet_idle.freq1(j);
        freq2 = dataSheet_idle.freq2(j);
        freq3 = dataSheet_idle.freq3(j);
        freq4 = dataSheet_idle.freq4(j);
        freq5 = dataSheet_idle.freq5(j);
        idleFreqs = [freq1, freq2, freq3, freq4, freq5];  % All frequencies to check
        
        % Check if the top frequency matches any of the idle frequencies within tolerance
        % 检查 topFreq 是否在空闲频率范围内
        isMatch = false;
        for k = 1:length(idleFreqs)
            if abs(topFreq - idleFreqs(k)) < tol
                isMatch = true;
                break;
            end
        end
        
        % If matches idle frequencies within tolerance, mark it as stable with transparent marker
        if isMatch
            marker = 'v';  % Mark stable
            markerColor = 'c';
            stabilityResults(i) = 0;  % Stable (matches idle frequencies)
            disp('Result: Stable (matches idle frequencies)');
        else
            % If not matching, mark it as unstable
            marker = 'p';  % Mark unstable
            markerColor = 'r';  % Red for unstable (does not match)
            stabilityResults(i) = 1;  % Unstable (does not match spindle harmonics or idle frequencies)
            disp('Result: Unstable (does not match spindle harmonics or idle frequencies)');
        end
    end

    % Plot the marker in the stability map
    % 在稳定性图上绘制标记
    hold on;
    plot(n, ap, marker, 'MarkerEdgeColor', markerColor, 'MarkerFaceColor', 'none', 'MarkerSize', 8, 'LineWidth', 1.5);
end

% Apply the f030_optimizeFig_Paper_05 function to improve figure appearance
% 应用 f030_optimizeFig_Paper_05 函数来美化图形外观
f030_optimizeFig_Paper_05(gca, 'Spindle Speed (n)', 'Depth of Cut (ap)', 'Stability Map of Top1 Frequency', {}, 'northeast', [0.01, 0.01]);

% Process output (simple summary)
% 处理输出（简单的总结）
stableCount = sum(stabilityResults == 0);  % Count of stable points
unstableCount = sum(stabilityResults == 1);  % Count of unstable points

disp(['Total stable points: ', num2str(stableCount)]);
disp(['Total unstable points: ', num2str(unstableCount)]);
