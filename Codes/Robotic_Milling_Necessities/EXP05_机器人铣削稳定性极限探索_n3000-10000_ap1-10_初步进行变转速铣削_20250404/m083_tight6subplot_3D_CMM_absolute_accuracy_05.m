clear; clc; close all; % 清理工作区
load("ap_cmm_05_row_flipud.mat"); % 加载数据

% 创建一个 2x3 的 subplot 布局
figure('Units','centimeters','Position',[5 1 14 18]); % 图形设置

% 定义转速数组
rpms = [3000, 4000, 5000, 6000, 7000, 8000];

ap = zeros(10, 20);

for i = 1:10
    ap(i,:) = 11-i;
end

% 使用tight_subplot创建紧凑的布局
% 这里gap表示子图之间的间距，marg_h和marg_w为上下和左右的边距
gap = [0, 0.14]; % 垂直和水平间隔
marg_h = [0, 0]; % 上下边距
marg_w = [0.09, 0.04]; % 左右边距

[ha, pos] = tight_subplot(3, 2, gap, marg_h, marg_w);

% Initialize the color data limits
cmin = 0;   % Minimum color limit
cmax = 0.3; % Maximum color limit

% 遍历每个转速并绘制相应的3D柱状图
for i = 1:length(rpms)
    % 为每个 subplot 创建一个子图
    axes(ha(i)); % 设置当前坐标轴为 tight_subplot 中的一个

    % 获取当前转速的对应数据（假设已存储为结构体字段）
    data = ap_cmm_05_row_flipud.(sprintf('n%d', rpms(i))); % 取对应转速的矩阵
    
    % 绘制3D柱状图
    b1 = bar3(-data-ap); % 使用 bar3 绘制 3D 柱状图
    
    % 设置视角
    view(-35, 45); 
    
    % 为每个柱子设置颜色渐变
    for k = 1:length(b1)
        zdata = b1(k).ZData;               % 获取柱状图的 Z 数据（高度）
        b1(k).CData = zdata;               % 将 CData 设置为 ZData
        b1(k).FaceColor = 'interp';        % 启用颜色渐变
    end

    clim([0, 0.3]);

    ax1 = gca;
    % 设置 X 轴与 Y 轴刻度
    ax1.XTick = 0:4:20;           % Y 轴刻度：10个切深层次
    ax1.XTickLabel = 0:30:150;     % Y 轴标签为1到10，倒序表示切深层次
    ax1.YTick = 1:2:10;           % Y 轴刻度：10个切深层次
    ax1.YTickLabel = 10:-2:1;     % Y 轴标签为1到10，倒序表示切深层次

    % 优化图形（调用优化函数，自行调整标签、标题等）
    f031_3DFigOptimized_05(ax1, '{\it l} (mm)', '{\it a}_p (mm)', 'Δ{\it a}_p (mm)','',[0.01,0.01],'tight','tight',[0, 0.34]);

end

f060_saveFigPNG_asFileName_05(mfilename('fullpath'),true);


% Create a new figure for the colorbar
figure('Units','centimeters','Position',[25 1 7 20]); % New figure for the colorbar
% Hide the axis for the colorbar
axis off;
% Add the colorbar to the new figure
cbar1 = colorbar;
clim([0 0.3]);
% Customize the colorbar appearance
f034_colorbar_05(cbar1, '', 10.5, 'Times New Roman', 1); % Customize colorbar
f060_saveFigPNG_asFileName_05(mfilename('fullpath'),false);

% Add the colorbar to the right of the figure
% cbar1 = colorbar('Position', [0.92 0.1 0.02 0.8]); % Adjust colorbar position
% f034_colorbar_05(cbar1, '{\it dev} (mm)', 10.5, 'Times New Roman', 1); % Customize colorbar

