clc;
clear;
close;

% 数据
machineRa = [
    1.535, 1.492, 0.837, 1.245;
    1.585, 1.553, 1.313, 1.311;
    1.375, 1.174, 1.045, 1.001;
    1.819, 1.885, 1.044, 0.802;
    1.495, 1.405, 1.649, 1.884;
    1.487, 1.575, 1.533, 1.678
];

robotRa = [
    1.161, 1.622, 1.612, 1.784;
    2.017, 1.971, 1.765, 2.251;
    1.854, 1.453, 1.479, 1.491;
    1.548, 1.515, 1.937, 3.075;
    1.799, 1.919, 2.012, 3.193;
    1.822, 1.978, 3.395, 3.061
];

% 计算均值
machineRa_mean = mean(machineRa, 2); % 机床Ra每行的均值
robotRa_mean = mean(robotRa, 2);    % 机器人Ra每行的均值

% x轴为铣削表面序号
milling_surfaces = 1:6;

% 颜色
robot_color = [0.8500 0.3250 0.0980]; % 机器人颜色 (橙色)
machine_color = [0 0.4470 0.7410]; % 机床颜色 (蓝色)

% 绘制图形
figure('Units','centimeters','Position',[2 2 15 9]); % 宽15cm，适合论文
hold on;

% 绘制机器人Ra均值数据
plot(milling_surfaces, robotRa_mean, '-o', 'LineWidth', 2, 'Color', robot_color, 'MarkerSize', 8, 'MarkerFaceColor', robot_color);

% 绘制机床Ra均值数据
plot(milling_surfaces, machineRa_mean, '-s', 'LineWidth', 2, 'Color', machine_color, 'MarkerSize', 8, 'MarkerFaceColor', machine_color);

% 在每个标记上显示均值
for i = 1:length(milling_surfaces)
    % 显示机器人均值，调整文本位置
    text(milling_surfaces(i), robotRa_mean(i) + 0.05, sprintf('%.3f', robotRa_mean(i)), 'Color', robot_color, 'FontSize', 10, ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center'); % 上移文本

    % 显示机床均值，调整文本位置
    text(milling_surfaces(i), machineRa_mean(i) + 0.05, sprintf('%.3f', machineRa_mean(i)), 'Color', machine_color, 'FontSize', 10, ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center'); % 上移文本
end

% 优化Figure
set(gca, 'FontSize', 11, 'FontName', '宋体', 'LineWidth', 1, 'Box', 'on');
grid on;
xlabel('切深(mm)', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
ylabel('{\itRa}(\mum)', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
title('机器人与机床6道铣削表面{\itRa}均值对比', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', '宋体');
legend({'机器人{\itRa}均值', '机床{\itRa}均值'}, 'Location', 'northwest', 'FontSize', 11, 'FontName', '宋体');
set(gcf, 'Color', 'w'); % 白色背景，便于论文插图

% 去掉上、右侧tick并设置tick为'in'
set(gca, 'TickDir', 'in');
set(gca, 'Box', 'off'); % 去掉右侧和上方框线

% 设置tick长度为0.01
set(gca, 'TickLength', [0.01, 0.01]);

% 设置x轴的余量
xlim([0.5, 6.5]);  % 前后留一点余量

% 设置ylim为1-3
ylim([1, 3]);

xticks([1, 2, 3, 4, 5, 6]); % 原始刻度位置
xticklabels([1, 2, 2.5, 3, 3.5, 4]); % 显示的标签值


% 重新绘制加粗外框，不将其加入legend
xl = xlim;
yl = ylim;
plot([xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], 'k-', 'LineWidth', 1, 'HandleVisibility', 'off'); % 隐藏外框在legend中的显示

% 保存图形为PNG文件，分辨率为1000 DPI
fileName = 'Ra_mean_comparison.png'; % 输出文件名
print(gcf, fileName, '-dpng', '-r1000'); % 高分辨率保存图形为PNG
