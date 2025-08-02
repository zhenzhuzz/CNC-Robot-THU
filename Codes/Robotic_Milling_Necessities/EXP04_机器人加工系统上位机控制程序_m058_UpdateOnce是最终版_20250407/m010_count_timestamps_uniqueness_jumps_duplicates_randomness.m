clc;
% clear;  % 注释掉 clear 以保留工作区中已有的 data 和 timestamps
close all;

format longG;

%% 数据已经加载在工作区，变量 data 和 timestamps 已存在
% timestamps 已经以秒为单位，例如最后显示 14.599921875000001 秒
total_points = length(timestamps);

%% 计算统计量
unique_timestamps = unique(timestamps);
num_unique_timestamps = numel(unique_timestamps);
time_span_sec = max(timestamps) - min(timestamps);  % 时间跨度（秒）

fprintf('\n=== 数据整体统计 ===\n');
disp(['数据总条数：', num2str(total_points)]);
disp(['时间跨度：', num2str(time_span_sec), ' 秒']);
disp(['唯一时间戳个数：', num2str(num_unique_timestamps)]);

%% 检查重复时间戳情况（以第一个重复时间戳为例）
% 这里采用极小的偏移量 epsilon 来设置直方图边界，避免浮点数问题
epsilon = 1e-12;
counts_per_timestamp = histcounts(timestamps, [unique_timestamps; max(unique_timestamps)+epsilon]);
repeated_timestamp_idx = find(counts_per_timestamp > 1, 1);

fprintf('\n=== 重复数据检查 ===\n');
if ~isempty(repeated_timestamp_idx)
    repeated_timestamp = unique_timestamps(repeated_timestamp_idx);
    repeated_count = counts_per_timestamp(repeated_timestamp_idx);
    disp(['发现重复时间戳：', num2str(repeated_timestamp), ' 秒']);
    disp(['该时间戳下的数据点数量：', num2str(repeated_count)]);
else
    disp('未发现重复的时间戳。');
end

%% 检查时间戳跳跃情况
timestamp_diffs = diff(unique_timestamps);
expected_interval = 1/12800;  % 理论上每个采样时刻间隔为 1/12800 秒
jump_indices = find(timestamp_diffs > expected_interval);
num_jumps = numel(jump_indices);

fprintf('\n=== 时间戳跳跃检查 ===\n');
disp(['时间戳跳跃次数：', num2str(num_jumps)]);

disp('列举最多5个具体的跳跃情况 (序号 起始时间戳(秒) 终止时间戳(秒) 跳跃秒数)：');
disp('序号    起始时间戳(秒)           终止时间戳(秒)           跳跃秒数');
num_display = min(5, num_jumps);
for i = 1:num_display
    start_ts = unique_timestamps(jump_indices(i));
    end_ts = unique_timestamps(jump_indices(i)+1);
    jump_sec = timestamp_diffs(jump_indices(i)) - expected_interval;
    fprintf('%-7d %-22.15f %-22.15f %-15.15f\n', i, start_ts, end_ts, jump_sec);
end

%% 数据随机采样情况分析
fprintf('\n=== 数据随机采样情况分析 ===\n');

% 理论上应有的采样点数 = 时间跨度/采样间隔 + 1
expected_samples = time_span_sec / expected_interval + 1;
missing_samples = expected_samples - num_unique_timestamps;

disp(['理论上应有的采样点数：', num2str(expected_samples)]);
disp(['实际记录采样点数：', num2str(num_unique_timestamps)]);
disp(['缺失采样点数：', num2str(missing_samples)]);

average_points_per_timestamp = total_points / num_unique_timestamps;
disp(['平均每个采样时刻的数据点数：', num2str(average_points_per_timestamp)]);

% 验证乱序情况（检查时间戳是否严格递增）
is_strictly_increasing = all(diff(timestamps) >= 0);
if ~is_strictly_increasing
    disp('数据存在明显的乱序情况（时间戳非严格递增）。');
else
    disp('数据不存在乱序情况（时间戳严格递增）。');
end

%% 可视化时间戳跳跃情况（可选）
figure;
plot(timestamp_diffs);
title('时间戳差值分布图（验证跳跃与缺失情况）');
xlabel('时间戳索引');
ylabel('相邻时间戳差值 (秒)');
grid on;
