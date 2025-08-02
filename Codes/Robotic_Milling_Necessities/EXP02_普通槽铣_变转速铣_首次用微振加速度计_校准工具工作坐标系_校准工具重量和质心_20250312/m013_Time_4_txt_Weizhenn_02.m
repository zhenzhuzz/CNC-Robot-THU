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
fig = figure('Units','centimeters','Position',[2 2 20 6]); % 适合论文
ax = axes(fig);
hold(ax, 'on');

% 绘制X方向加速度数据
plot(ax, data_all{1}.Time, data_all{1}.X*1e-3, 'HandleVisibility','off'); % 第一个数据不显示在图例中
plot(ax, data_all{2}.Time, data_all{2}.X*1e-3, 'DisplayName','1mm切深'); % 第二个数据显示在图例中

% 调用你定制好的函数（自动设置xlim, ylim并优化显示）
f030_optimizeFig_Paper_02(ax, ...
    '时间(s)', ...                      % xlabel
    '进给方向加速度(g)', ...            % ylabel
    '进给方向（X）加速度时域数据', ...  % title
    {'1mm切深'}, ...                   % 图例文本（仅显示第二个数据）
    'northeast');                      % 图例位置

% 根据需求，手动限制x轴范围
xlim(ax,[0 25]);

% 保存图形为高分辨率PNG文件（1500 DPI）
fileName = 'p1010_Slotmilling_X_Acc.png';
print(gcf, fileName, '-dpng', '-r1500');
