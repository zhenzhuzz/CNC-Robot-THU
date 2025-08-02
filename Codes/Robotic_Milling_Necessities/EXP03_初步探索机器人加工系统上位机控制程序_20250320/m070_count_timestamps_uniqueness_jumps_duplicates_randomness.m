% 数据分析与统计程序（完整优化版）
clc;
clear;
close all;

format longG;

%% 读取数据
data = readmatrix('700.txt');

% 提取倒数第二列为时间戳
timestamps = data(:, end-1);
total_points = length(timestamps);

%% 计算统计量
unique_timestamps = unique(timestamps);
num_unique_timestamps = numel(unique_timestamps);

time_span_ms = max(timestamps) - min(timestamps); % 时间跨度(毫秒)

fprintf('\n=== 数据整体统计 ===\n');
disp(['数据总条数：', num2str(total_points)]);
disp(['时间跨度：', num2str(time_span_ms), ' 毫秒 (约 ', num2str(time_span_ms/1000), ' 秒)']);
disp(['唯一时间戳个数：', num2str(num_unique_timestamps)]);

%% 检查重复时间戳情况（以第一个重复时间戳为例）
counts_per_timestamp = histcounts(timestamps, [unique_timestamps; max(unique_timestamps)+1]);
repeated_timestamp_idx = find(counts_per_timestamp > 1, 1); % 找第一个重复的时间戳
repeated_timestamp = unique_timestamps(repeated_timestamp_idx);
repeated_count = counts_per_timestamp(repeated_timestamp_idx);

fprintf('\n=== 重复数据检查 ===\n');
if ~isempty(repeated_timestamp)
    disp(['发现重复时间戳：', num2str(repeated_timestamp)]);
    disp(['该时间戳下的数据点数量：', num2str(repeated_count)]);
else
    disp('未发现重复的时间戳。');
end

%% 检查时间戳跳跃情况
timestamp_diffs = diff(unique_timestamps);
jump_indices = find(timestamp_diffs > 1);
num_jumps = numel(jump_indices);

fprintf('\n=== 时间戳跳跃检查 ===\n');
disp(['时间戳跳跃次数：', num2str(num_jumps)]);

% 列举前5个具体跳跃的详情
disp('列举最多5个具体的跳跃情况 (序号 起始时间戳 终止时间戳 跳跃毫秒数)：');
disp('序号    起始时间戳         终止时间戳         跳跃毫秒数');
num_display = min(10, num_jumps);
for i = 1:num_display
    start_ts = unique_timestamps(jump_indices(i));
    end_ts = unique_timestamps(jump_indices(i)+1);
    jump_ms = timestamp_diffs(jump_indices(i)) - 1;
    fprintf('%-7d %-18d %-18d %-10d\n', i, start_ts, end_ts, jump_ms);
end

%% 证明数据随机采样、重复、缺失和乱序
fprintf('\n=== 数据随机采样情况分析 ===\n');

% 理论上应为 10444毫秒，如果每毫秒1个数据点，则应有10444个时间戳
expected_timestamps = time_span_ms + 1;
missing_timestamps = expected_timestamps - num_unique_timestamps;

disp(['理论上应有的毫秒数：', num2str(expected_timestamps)]);
disp(['实际记录毫秒数：', num2str(num_unique_timestamps)]);
disp(['缺失毫秒数：', num2str(missing_timestamps)]);

average_points_per_timestamp = total_points / num_unique_timestamps;
disp(['平均每个毫秒的数据点数：', num2str(average_points_per_timestamp)]);

% 验证乱序（原始timestamps是否严格递增）
is_strictly_increasing = all(diff(timestamps) >= 0);
if ~is_strictly_increasing
    disp('数据存在明显的乱序情况（时间戳非严格递增）。');
else
    disp('数据不存在乱序情况（时间戳严格递增）。');
end

%% 可视化跳跃情况（可选）
figure;
plot(timestamp_diffs);
title('时间戳差值分布图（验证跳跃与缺失情况）');
xlabel('时间戳索引');
ylabel('相邻时间戳差值 (毫秒)');
grid on;
