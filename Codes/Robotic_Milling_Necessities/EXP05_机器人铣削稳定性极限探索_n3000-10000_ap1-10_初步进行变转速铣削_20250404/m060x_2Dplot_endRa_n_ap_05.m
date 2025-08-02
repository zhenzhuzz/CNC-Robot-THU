clc;
clear;
close all;

% Step 1: Load the table using f040_load_table_05 function
% Step 1: 使用f040_load_table_05函数加载数据表
data = f040_load_table_05('EXP05'); % 确保传入正确的表名

% 提取相关数据
% Extract relevant data
n_values = unique(data.n);  % 获取唯一的主轴转速 (n)
ap_values = unique(data.ap);  % 获取唯一的轴向切削深度 (ap)

% 将endRa和sideRa重塑为适合折线图的格式
% Reshape endRa and sideRa to fit the line plot format
endRa_matrix = reshape(data.endRa, [length(n_values), length(ap_values)]);  
sideRa_matrix = reshape(data.sideRa, [length(n_values), length(ap_values)]);  

% 创建端面Ra的折线图
% Create a line plot for endRa
figure;
ax1 = axes;
hold on;

% 绘制每个主轴转速下的轴向深度与端面Ra的折线图
% Plot the line graph for each spindle speed (n) against axial depth (ap) and endRa
for i = 1:length(n_values)
    % 提取当前主轴转速下的端面Ra值
    % Extract the endRa values for the current spindle speed (n)
    endRa_line = endRa_matrix(i, :);
    % 绘制每个主轴转速下的折线图，使用颜色表示深浅
    % Plot the line for each spindle speed with color representing endRa
    plot(ap_values, endRa_line, 'LineWidth', 2, 'DisplayName', sprintf('n = %d', n_values(i)));
end

% 设置颜色条，基于端面Ra的最大值和最小值
% Set the colorbar based on the maximum and minimum values of endRa
colormap jet;  % 使用 jet 颜色映射
colorbar;

% 设置坐标轴标签和标题
% Set axis labels and title
xlabel('Axial Depth (ap)');
ylabel('End Face Ra');
title('End Face Ra vs. Axial Depth and Spindle Speed');

% 优化图形，设置坐标轴字体和外观
% Optimize the figure, setting axis fonts and appearance
f030_optimizeFig_Paper_05(ax1, 'Axial Depth (ap)', 'End Face Ra', 'End Face Ra vs. Axial Depth and Speed', {}, 'northeast', [0.01, 0.01], [], []);
hold off;

% 创建侧面Ra的折线图
% Create a line plot for sideRa
figure;
ax2 = axes;
hold on;

% 绘制每个主轴转速下的轴向深度与侧面Ra的折线图
% Plot the line graph for each spindle speed (n) against axial depth (ap) and sideRa
for i = 1:length(n_values)
    % 提取当前主轴转速下的侧面Ra值
    % Extract the sideRa values for the current spindle speed (n)
    sideRa_line = sideRa_matrix(i, :);
    % 绘制每个主轴转速下的折线图，使用颜色表示深浅
    % Plot the line for each spindle speed with color representing sideRa
    plot(ap_values, sideRa_line, 'LineWidth', 2, 'DisplayName', sprintf('n = %d', n_values(i)));
end

% 设置颜色条，基于侧面Ra的最大值和最小值
% Set the colorbar based on the maximum and minimum values of sideRa
colormap jet;  % 使用 jet 颜色映射
colorbar;

% 设置坐标轴标签和标题
% Set axis labels and title
xlabel('Axial Depth (ap)');
ylabel('Side Ra');
title('Side Ra vs. Axial Depth and Spindle Speed');

% 优化图形，设置坐标轴字体和外观
% Optimize the figure, setting axis fonts and appearance
f030_optimizeFig_Paper_05(ax2, 'Axial Depth (ap)', 'Side Ra', 'Side Ra vs. Axial Depth and Speed', {}, 'northeast', [0.01, 0.01], [], []);
hold off;
