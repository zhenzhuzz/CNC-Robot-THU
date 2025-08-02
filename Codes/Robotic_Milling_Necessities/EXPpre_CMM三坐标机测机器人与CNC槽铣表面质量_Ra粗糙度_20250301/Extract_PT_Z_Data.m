clear; clc; close all; % 清理工作区

% 定义文件名
files = {'Robot_PT.txt', 'CNC_PT.txt'};
labels = {'机器人切深', '机床切深'};
colors = [0.8500 0.3250 0.0980; 0 0.4470 0.7410]; % MATLAB默认配色

figure('Units','centimeters','Position',[2 2 15 9]); % 宽13cm，适合论文
hold on;

for idx = 1:length(files)
    fid = fopen(files{idx}, 'r');
    z_actual = []; % 存放实际的Z数据

    while ~feof(fid)
        line = fgetl(fid);
        if startsWith(strtrim(line), 'PT')
            for k = 1:10
                subline = fgetl(fid);
                if startsWith(strtrim(subline), 'Z')
                    parts = strsplit(strtrim(subline));
                    z_value = str2double(parts{3});
                    z_actual(end+1) = z_value;
                    break;
                end
            end
        end
    end

    fclose(fid);

    % 绘图
    plot(1:length(z_actual), z_actual, '-o', 'Color', colors(idx,:),...
        'LineWidth', 1, 'MarkerSize', 3, 'MarkerFaceColor', colors(idx,:),...
        'DisplayName', labels{idx});
end
absolute
% 设置Y轴范围为[-5, -0.5]
ylim([-5, -0.5]);

% 优化Figure
set(gca, 'FontSize', 11, 'FontName', '宋体', 'LineWidth', 1, 'Box', 'on');
grid on;
xlabel('测量点序号', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
ylabel('实际切深', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
title('机器人与机床各测量点的实际切深对比', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', '宋体');
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
fileName = 'PT_depth_comparison.png'; % 输出文件名
print(gcf, fileName, '-dpng', '-r1000'); % 高分辨率保存图形为PNG

hold off;
