clear; clc; close all; % 清理工作区
load("ap_cmm_05_row_flipud.mat"); % 加载数据

% 创建一个 2x3 的 subplot 布局
figure('Units','centimeters','Position',[5 1 1 20]); % 图形设置

% 定义转速数组
rpms = [3000, 4000, 5000, 6000, 7000, 8000];

ap = zeros(10, 20);

for i = 1:10
    ap(i,:) = 11-i;
end

% 使用tight_subplot创建紧凑的布局
% 这里gap表示子图之间的间距，marg_h和marg_w为上下和左右的边距
gap = [0.01, 0.1]; % 垂直和水平间隔
marg_h = [0.05, 0.05]; % 上下边距
marg_w = [0.05, 0.05]; % 左右边距

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

    % 设置标题
    title(sprintf('RPM %d', rpms(i)));
    zlim([0,0.34]);
    clim([0, 0.34]);
    ax1 = gca;
    % 设置 X 轴与 Y 轴刻度
    ax1.YTick = 1:2:10;           % Y 轴刻度：10个切深层次
    ax1.YTickLabel = 10:-2:1;     % Y 轴标签为1到10，倒序表示切深层次

end

% Create a new figure for the colorbar
figure('Units','centimeters','Position',[5 1 10 20]); % New figure for the colorbar

% Add the colorbar to the new figure
cbar1 = colorbar

% Customize the colorbar appearance
f034_colorbar_05(cbar1, 'Δ{\it a}_p (mm)', 10.5, 'Times New Roman', 1); % Customize colorbar

% Set the clim for the colorbar
caxis([cmin cmax]); % Ensure that color limits are applied globally
