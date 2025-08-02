clear; clc; close all; % 清理工作区

% 加载数据
load('ap_cmm_05.mat');
%%
% 定义转速数组
rpms = [3000, 4000, 5000, 6000, 7000, 8000];

% 对每个转速的数据进行列翻转
for i = 1:length(rpms)
    % 获取当前转速的对应字段
    field_name = sprintf('n%d', rpms(i));
    
    % 对每个转速的10x20矩阵进行列翻转
    ap_cmm_05.(field_name) = fliplr(ap_cmm_05.(field_name));
end
