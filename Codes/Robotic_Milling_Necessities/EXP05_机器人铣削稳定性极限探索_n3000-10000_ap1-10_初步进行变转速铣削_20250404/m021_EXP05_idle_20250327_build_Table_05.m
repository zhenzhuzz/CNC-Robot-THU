clc;
clear;
close all;

% 创建日期、转速和文件路径的数据
date = repmat({'20250327'}, 8, 1);  % 所有日期都是 '20250327'
n = [3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]';  % 转速列表
path = cell(8, 1);  % 初始化路径列

% 生成文件路径
for i = 1:8
    path{i} = fullfile('data', 'idle', sprintf('n%d_idle_20250327.txt', n(i)));  % 根据转速生成文件路径
end

% 创建表格
EXP05_idle = table(date, n, path);

% 显示表格
disp(EXP05_idle);

%%
% 假设你已经有一个名为 EXP05_20250327 的 table，包含 path 列
% 在此代码段中，我们将遍历 path 列并检查每个文件路径是否有效

% 遍历 path 列
for i = 1:height(EXP05_idle)
    % 获取当前行的文件路径
    filePath = EXP05_idle.path{i};
    
    % 检查文件是否存在
    if exist(filePath, 'file') ~= 2
        % 如果文件不存在，打印信息
        fprintf('File does not exist: %s\n', filePath);
    end
end