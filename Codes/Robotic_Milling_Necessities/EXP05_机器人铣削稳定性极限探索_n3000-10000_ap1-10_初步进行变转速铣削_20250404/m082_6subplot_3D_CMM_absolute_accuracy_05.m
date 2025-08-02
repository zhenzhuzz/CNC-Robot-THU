clear; clc; close all; % 清理工作区
load("ap_cmm_05_1.mat"); % 加载数据
%%
% 创建一个 2x3 的 subplot 布局
figure('Units','centimeters','Position',[5 2 15 20]); % 图形设置

% 定义转速数组
rpms = [3000, 4000, 5000, 6000, 7000, 8000];

ap = zeros(10, 20);

for i = 1:10
    ap(i,:) = i;
end

% 遍历每个转速并绘制相应的3D柱状图
for i = 1:length(rpms)
    % 为每个 subplot 创建一个子图
    subplot(3, 2, i);
    
    % 获取当前转速的对应数据（假设已存储为结构体字段）
    data = ap_cmm_05_1.(sprintf('n%d', rpms(i))); % 取对应转速的矩阵
    
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
    
    
    % 添加颜色条并设置标签
    % colorbar; % 显示颜色条
    
end

% f060_saveFigPNG_asFileName_05(mfilename("fullpath"));