%% 主函数：数据读取与调用
clc; clear; close all;

filepath = '0.txt';
samplingRate = 6600;    % 采样率 (Hz) 
windowSize = 5;       % 时间窗口长度(秒)
maxFreq = 500;         % FFT最大频率(Hz)
n=1800;

% 读取数据
data = f021_readAcc_WeiZhen(filepath, 'XYZ');
time = data.Time;
accX = data.X;


% 调用 GUI 创建函数
f050_createFFT_GUI(time, accX, samplingRate, windowSize, maxFreq);

fprintf('fsp = %.2f\n', n/60);


% 去除重复时间戳 (关键修正步骤)
[time_unique, ~, idx_unique] = unique(time);
accX_unique = accumarray(idx_unique, accX, [], @mean);

% 重新进行严格均匀插值（6600Hz）
t_uniform = (time_unique(1):1/samplingRate:time_unique(end))';
accX_uniform = interp1(time_unique, accX_unique, t_uniform, 'linear');
accX_uniform(isnan(accX_uniform)) = 0; % NaN处理

time = t_uniform;
accX = accX_uniform;

f050_createFFT_GUI(time, accX, samplingRate, windowSize, maxFreq);



% % 设置分析的时间范围：0-10秒
% t_start = 0;
% t_end = 10;
% 
% % 获取时间范围内的数据
% t_start_index = find(time >= t_start, 1, 'first');
% t_end_index = find(time >= t_end, 1, 'first');
% time = time(t_start_index:t_end_index);
% accX = accX(t_start_index:t_end_index);
% 
% % 将加速度从mg转换为m/s²
% accX = accX * 9.80665 * 1e-3;
% 
% % 去除加速度数据中的均值（即去除静态偏置）
% accX = accX - mean(accX);
% 
% % 绘制加速度图
% figure(1)
% plot(time, accX);
% xlabel('Time (s)');
% ylabel('Acceleration (m/s²)');
% title('Acceleration vs Time');
% grid on;
% 
% % 计算速度（通过积分加速度）
% v_t = cumtrapz(time, accX);  % 使用累积梯形法进行积分
% 
% % 设置初始速度为0（如果需要其他初始速度，可以修改）
% v0 = 0;  % 可以根据实际情况设定初始速度
% v_t = v_t + v0;  % 如果你有初始速度，可以加上v0
% 
% % 绘制速度图
% figure(2)
% plot(time, v_t);
% xlabel('Time (s)');
% ylabel('Velocity (m/s)');
% title('Velocity vs Time');
% grid on;
% 
% % 计算位移（通过积分速度）
% x_t = cumtrapz(time, v_t);  % 对速度进行积分得到位移
% x_t = detrend(x_t, 4);  % 去除任何趋势（如果需要）
% 
% % 绘制位移图
% figure(3)
% plot(time, x_t);
% xlabel('Time (s)');
% ylabel('Position (m)');
% title('Position vs Time');
% grid on;
% 
% % 输出数值结果（速度和位移的最大值）
% disp(['Maximum velocity: ', num2str(max(v_t)), ' m/s']);
% disp(['Maximum displacement: ', num2str(max(x_t)), ' m']);
