clc;
clear;
close all;

% 定义n和对应的vc、fz值
n_values = [3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000];  % n的值
vc_values = [75, 101, 126, 151, 176, 201, 226, 251];  % vc的值
fz_values = [0.05, 0.0375, 0.03, 0.025, 0.02143, 0.01875, 0.01667, 0.015];  % fz的值

% 创建date、ap、其他固定值
date = repmat({'20250327'}, 80, 1);  % 80行，所有值都是20250327（字符串格式）

% 生成ap列，每个n值对应1到10的ap值，确保每个n的ap递增
ap = [];
for i = 1:length(n_values)
    ap = [ap; (1:10)'];  % 为每个n值创建从1到10的递增序列
end

f = repmat(450, 80, 1);  % f是450，80行
ae = repmat(8, 80, 1);  % ae是8，80行
D = repmat(8, 80, 1);  % D是8，80行
z = repmat(3, 80, 1);  % z是3，80行
aD = repmat(1, 80, 1);  % aD是1，80行
material = repmat({'ENAW7075'}, 80, 1);  % material是ENAW7075，80行
size = repmat({'150x150x15'}, 80, 1);  % size是150x150x15，80行

% 创建vc和fz列
vc = [];
fz = [];
for i = 1:length(n_values)
    vc = [vc; repmat(vc_values(i), 10, 1)];  % 每个n值对应10个vc
    fz = [fz; repmat(fz_values(i), 10, 1)];  % 每个n值对应10个fz
end

% 创建n列：每个n值对应10行
n_col = [];
for i = 1:length(n_values)
    n_col = [n_col; repmat(n_values(i), 10, 1)];  % 每个n值对应10行
end

% 创建文件路径列
file_names = {};  % 存储文件名
for i = 1:length(n_values)
    for j = 1:10
        % 文件名按照 n 和 ap 来排序，直接插入fz_values中的数值
        file_name = sprintf('n%d_f450_ap%d_ae8_vc%d_fz%g_D8_z3_Slot_ENAW7075_150x150x15_20250327.txt', ...
                            n_values(i), j, vc_values(i), fz_values(i));  % %g自动处理数值格式
        file_names{end+1} = fullfile('data\constant_spin_speed', file_name);  % 生成相对路径
    end
end

% 将文件路径列存入 path
path = file_names';

% 创建表格
EXP05 = table(date, n_col, f, ap, ae, vc, fz, D, z, aD, material, size, path, ...
    'VariableNames', {'date', 'n', 'f', 'ap', 'ae', 'vc', 'fz', 'D', 'z', 'aD', 'material', 'size', 'path'});

% 显示表格
disp(EXP05);




%%
% 假设你已经有一个名为 EXP05 的 table，包含 path 列
% 在此代码段中，我们将遍历 path 列并检查每个文件路径是否有效

% 遍历 path 列
for i = 1:height(EXP05)
    % 获取当前行的文件路径
    filePath = EXP05.path{i};
    
    % 检查文件是否存在
    if exist(filePath, 'file') ~= 2
        % 如果文件不存在，打印信息
        fprintf('File does not exist: %s\n', filePath);
    end
end

