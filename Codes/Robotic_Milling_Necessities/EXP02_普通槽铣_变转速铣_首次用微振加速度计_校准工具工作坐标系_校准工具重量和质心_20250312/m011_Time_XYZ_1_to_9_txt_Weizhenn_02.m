%% 数据导入部分
clc;
clear;
close all;

% 预先加载 1.txt 到 9.txt 的数据，存入 cell 数组中
numFiles = 9;
data_all = cell(numFiles, 1);
% for i = 1:numFiles
for i = 1:numFiles
    filename = sprintf('%d.txt', i);
    % 假设 f021_readAcc_WeiZhen 返回一个包含 Time, X, Y, Z 字段的 table
    data_all{i} = f021_readAcc_WeiZhen(filename, 'XYZ');
end

%% 绘图部分
figure;

% 创建三个 subplot 分别用于 X, Y, Z 方向加速度数据
% X 方向 subplot
subplot(3, 1, 1);
hold on;
xlabel('Time');
ylabel('X Acceleration');
title('X加速度时域数据');
xlim([0 30]);

% Y 方向 subplot
subplot(3, 1, 2);
hold on;
xlabel('Time');
ylabel('Y Acceleration');
title('Y加速度时域数据');
xlim([0 30]);

% Z 方向 subplot
subplot(3, 1, 3);
hold on;
xlabel('Time');
ylabel('Z Acceleration');
title('Z加速度时域数据');
xlim([0 30]);

% 遍历所有数据，将每个文件的数据绘制到相应的 subplot 上
for i = 1:numFiles
    data = data_all{i};
    
    % 在 X 方向 subplot 绘制
    subplot(3, 1, 1);
    plot(data.Time, data.X, 'DisplayName', sprintf('%d.txt', i));
    
    % 在 Y 方向 subplot 绘制
    subplot(3, 1, 2);
    plot(data.Time, data.Y, 'DisplayName', sprintf('%d.txt', i));
    
    % 在 Z 方向 subplot 绘制
    subplot(3, 1, 3);
    plot(data.Time, data.Z, 'DisplayName', sprintf('%d.txt', i));
end

% 为每个 subplot 添加图例以区分不同文件的数据
subplot(3, 1, 1); legend show;
subplot(3, 1, 2); legend show;
subplot(3, 1, 3); legend show;
