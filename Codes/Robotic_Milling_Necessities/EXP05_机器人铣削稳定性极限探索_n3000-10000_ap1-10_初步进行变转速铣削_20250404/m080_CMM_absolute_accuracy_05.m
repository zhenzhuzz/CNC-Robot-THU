clear; clc; close all; % 清理工作区

% 定义文件名和标签
file = 'cmm/n6000.txt';
label = 'CMM 测量数据';
color = [0 0.4470 0.7410]; % MATLAB 默认配色


% 打开文件
fid = fopen(file, 'r');
z_actual = []; % 存放实际的Z数据

% 读取文件并提取Z数据
while ~feof(fid)
    line = fgetl(fid);
    if startsWith(strtrim(line), 'PT') % 查找每行开始为"PT"的行
        for k = 1:10
            subline = fgetl(fid);
            if startsWith(strtrim(subline), 'Z') % 查找每行开始为"Z"的行
                parts = strsplit(strtrim(subline));
                z_value = str2double(parts{3}); % 获取Z值
                z_actual(end+1) = z_value; % 存储Z值
                break;
            end
        end
    end
end

% 关闭文件
fclose(fid);

% 重新排列z_actual数据
n = 20; % 每组包含20个数据
z_new = [];

for i = 1:n:length(z_actual)
    % 获取当前20个元素
    group = z_actual(i:min(i+n-1, end));
    % 对当前20个元素倒序
    z_new = [z_new, flip(group)];
end

% 绘制新的数据
figure('Units','centimeters','Position',[2 2 15 9]); % 图形设置
hold on;

plot(1:length(z_new), z_new, '-o', 'Color', color, ...
    'LineWidth', 1, 'MarkerSize', 3, 'MarkerFaceColor', color, ...
    'DisplayName', label);

% 设置Y轴范围为[-5, -0.5]
ylim([-11, -0.5]);
xlim([0, 210]);

% 优化Figure
set(gca, 'FontSize', 11, 'FontName', '宋体', 'LineWidth', 1, 'Box', 'on');
grid on;
xlabel('测量点序号', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
ylabel('实际切深', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
title('CMM测量数据切深', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', '宋体');
legend('Location', 'northeast', 'FontSize', 11, 'FontName', '宋体');
set(gcf, 'Color', 'w'); % 白色背景，便于论文插图

% 去掉上、右侧tick并设置tick为'in'
set(gca, 'TickDir', 'in');
set(gca, 'Box', 'off'); % 去掉右侧和上方框线

% 设置tick长度为0.25
set(gca, 'TickLength', [0.01, 0.01]);

% 重新绘制加粗外框，不将其加入legend
xl = xlim;
yl = ylim;
plot([xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], 'k-', 'LineWidth', 1, 'HandleVisibility', 'off'); % 隐藏外框在legend中的显示

% 保存图形为PNG文件，分辨率为1000 DPI
fileName = 'PT_depth_cmm_comparison_reversed.png'; % 输出文件名
print(gcf, fileName, '-dpng', '-r1000'); % 高分辨率保存图形为PNG

hold off;
