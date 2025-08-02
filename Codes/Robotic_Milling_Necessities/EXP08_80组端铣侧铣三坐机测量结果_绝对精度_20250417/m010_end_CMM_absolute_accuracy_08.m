%% plot_CMM_data_optimized_en_meanOnly.m
% 清理工作区 / Clear workspace
clear; clc; close all;

% 定义文件名及配色 / Define file name and color
file  = 'end.txt';            % 数据文件名 / data file name
color = [0 0.4470 0.7410];    % MATLAB 默认配色 / default MATLAB color

% 打开并读取文件 / Open and read file
fid = fopen(file, 'r');
if fid == -1
    error('Cannot open file: %s', file);
end

z_actual = [];  % 存储所有 Z 数据 / container for Z values
while ~feof(fid)
    line = fgetl(fid);
    if startsWith(strtrim(line), 'PT')        % 找到以 PT 开头的行 / lines starting with "PT"
        for k = 1:10
            subline = fgetl(fid);
            if startsWith(strtrim(subline), 'Z')  % 找到以 Z 开头的行 / lines starting with "Z"
                parts   = strsplit(strtrim(subline));
                z_value = str2double(parts{4});    % Z 值在第4列 / Z value in column 4
                z_actual(end+1) = z_value;         % 存入数组 / append to array
                break;
            end
        end
    end
end
fclose(fid);  % 关闭文件 / Close file

% 校验长度并重塑 / Verify length and reshape
if numel(z_actual) ~= 100
    error('z_actual length should be 100, but is %d.', numel(z_actual));
end
z_matrix = reshape(z_actual, 20, 5)';  % 先按列填充为20×5，再转置为5×20 / reshape to 5×20

% 计算每行的 Mean / Compute mean only
meanVal  = zeros(5,1);
for i = 1:5
    row = z_matrix(i,:);
    meanVal(i)  = mean(row);                 % 平均值 / mean
    fprintf('Row %d: Mean = %.4f\n', i, meanVal(i));
end

% 绘制 5 个子图并优化 / Plot 5 subplots and optimize
figure('Units','centimeters','Position',[2 2 16 20]);
for i = 1:5
    ax = subplot(5,1,i);  % 获取坐标轴句柄 / get axis handle
    plot(1:20, z_matrix(i,:), '-o', ...
         'Color',           color, ...
         'LineWidth',       1, ...
         'MarkerSize',      3, ...
         'MarkerFaceColor', color);
    grid(ax, 'on');       % 打开网格 / turn on grid

    % 英文标题：仅显示 Mean / English title showing only Mean
    titleText = sprintf('Row %d (Mean = %.3f mm)', i, meanVal(i));

    % 调用已保存的优化函数 / call your external optimization function
    f030_optimizeFig_Paper_08( ...
        ax, ...                                    % 坐标轴句柄 / axis handle
        'Measurement Point Index', ...             % x 轴标签 / x-label
        '\Delta{\it a}_p (mm)', ...                        % y 轴标签 / y-label
        titleText, ...                             % 子图标题 / title
        [1, 20], ...                                % x 轴范围 / x-limits
        [-0.35 -0.05], ...                             % y 轴范围 / y-limits
        [0.01, 0.01] ...                            % 刻度长度 / tick length
    );
end
set(gcf, 'Color', 'w');  % 白色背景 / white background


f060_saveFigPNG_asFileName_08(mfilename('fullpath'));