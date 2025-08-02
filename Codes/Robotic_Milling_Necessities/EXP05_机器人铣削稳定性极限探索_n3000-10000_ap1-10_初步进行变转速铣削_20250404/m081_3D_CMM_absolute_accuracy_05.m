clear; clc; close all; % 清理工作区
load("ap_cmm_05.mat");
% 定义文件名和标签
file = 'cmm/n6000.txt';
label = 'CMM 测量数据';
color = [0 0.4470 0.7410]; % MATLAB 默认配色

% 打开文件
fid = fopen(file, 'r');
z = []; % 存放实际的Z数据

% 读取文件并提取Z数据
while ~feof(fid)
    line = fgetl(fid);
    if startsWith(strtrim(line), 'PT') % 查找每行开始为"PT"的行
        for k = 1:10
            subline = fgetl(fid);
            if startsWith(strtrim(subline), 'Z') % 查找每行开始为"Z"的行
                parts = strsplit(strtrim(subline));
                z_value = str2double(parts{3}); % 获取Z值
                z(end+1) = z_value; % 存储Z值
                break;
            end
        end
    end
end

% 关闭文件
fclose(fid);

% 重新排列z数据
n = 20; % 每组包含20个数据
z_new = [];

for i = 1:n:length(z)
    % 获取当前20个元素
    group = z(i:min(i+n-1, end));
    % 对当前20个元素倒序
    z_new = [z_new, flip(group)];
end

% 现在，z_new是一个1*200的向量，接下来将其重塑为10*20矩阵
z_reshaped = reshape(z_new, 20, 10)'; % 重新排列为10行20列的矩阵

ap = zeros(10, 20);

for i = 1:10
    ap(i,:) = i;
end


% 绘制3D柱状图
figure('Units','centimeters','Position',[2 2 15 9]); % 图形设置
ax1 = axes; % 创建坐标轴
b1 = bar3(ax1, -(z_reshaped+ap)); % 使用bar3绘制3D柱状图

% 设置视角
view(-35, 45);

% 为每个柱子设置颜色渐变
for k = 1:length(b1)
    zdata = b1(k).ZData;                 % 获取柱状图的Z数据（高度）
    b1(k).CData = zdata;                 % 将CData设置为ZData
    b1(k).FaceColor = 'interp';          % 启用颜色渐变
end

% 添加颜色条并设置标签
colorbar; % 显示颜色条

% 设置 X 轴与 Y 轴刻度
ax1.XTick = 1:20;           % X 轴刻度：20个测量点
ax1.XTickLabel = 1:20;      % X 轴标签为1到20的点序号
ax1.YTick = 1:10;           % Y 轴刻度：10个切深层次
ax1.YTickLabel = flipud(1:10); % Y 轴标签为1到10，倒序表示切深层次

% 设置标签和标题
xlabel('测量点序号', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
ylabel('切深 1-10', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
zlabel('偏差 (mm)', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
title('CMM 测量数据三维柱状图', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', '宋体');

% 优化图形
set(gca, 'FontSize', 11, 'FontName', '宋体', 'LineWidth', 1, 'Box', 'on');
grid on;

% 保存图形为PNG文件，分辨率为1000 DPI
% fileName = 'CMM_3D_depth_bar3.png'; % 输出文件名
% print(gcf, fileName, '-dpng', '-r1000'); % 高分辨率保存图形为PNG
