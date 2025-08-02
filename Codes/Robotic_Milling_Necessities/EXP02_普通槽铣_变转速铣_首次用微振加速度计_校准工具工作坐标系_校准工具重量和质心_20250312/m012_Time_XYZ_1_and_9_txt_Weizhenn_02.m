%% 数据导入部分
clc;
clear;
close all;

% 指定要加载的文件：只读取 9.txt 和 1.txt
files = {'9.txt', '1.txt'};
numFiles = numel(files);
data_all = cell(numFiles, 1);

for i = 1:numFiles
    filename = files{i};
    % 假设 f021_readAcc_WeiZhen 返回一个包含 Time, X, Y, Z 字段的 table
    data_all{i} = f021_readAcc_WeiZhen(filename, 'X');
end

%% 绘图部分（只保留X加速度时域数据）
figure('Units','centimeters','Position',[2 2 20 6]); % 宽15cm，高5cm，适合论文
hold on;
% xlabel('Time');
% ylabel('X Acceleration');
% title('X加速度时域数据');
xlim([0 25]);

% 遍历每个文件的数据，仅绘制 X 方向加速度数据
for i = 1:numFiles
    data = data_all{i};
    plot(data.Time, data.X*1e-3, 'DisplayName', files{i});
end

legend show;

% 调用优化图形设置的函数，对当前图形进行美化
optimizeFigure();

% 保存图形为PNG文件，分辨率为1500 DPI 
fileName = 'p010_Slotmilling_X_Acc_02.png'; % 输出文件名
print(gcf, fileName, '-dpng', '-r1500'); % 高分辨率保存图形为PNG

%% 本地函数：优化 Figure 设置
function optimizeFigure()
    % 优化当前图形的各项设置
    % 注意：以下设置会覆盖原有的标签、图例文字，可根据实际情况调整

    % 设置坐标区字体、线宽等属性
    set(gca, 'FontSize', 11, 'FontName', '宋体', 'LineWidth', 1, 'Box', 'on');
    grid on;
    
    % 修改坐标轴标签
    xlabel('时间(s)', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
    ylabel('进给方向加速度(g)', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
    % 若需要修改标题可取消注释下行
    title('进给方向（X）加速度时域数据', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', '宋体');
    
    % 设置图例（这里的文字为示例，实际使用时请根据数据调整）
    lgd = legend({'5mm切深', '1mm切深'}, 'Location', 'northeast', 'FontSize', 12, 'FontName', '宋体');
    set(gcf, 'Color', 'w'); % 设置白色背景，便于论文插图
    lgd.ItemTokenSize = [14, 14];  % 缩短图例中线条的长度

    % 设置刻度方向为内，并去掉上、右侧框线
    set(gca, 'TickDir', 'in');
    set(gca, 'Box', 'off');
    set(gca, 'TickLength', [0.01, 0.01]);

    % 设置 y 轴显示范围为 [-2, 2]
    % ylim([-2, 2]);

    % 绘制加粗的外框（不加入图例）
    xl = xlim;
    yl = ylim;
    plot([xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], ...
         'k-', 'LineWidth', 1, 'HandleVisibility', 'off');
end
