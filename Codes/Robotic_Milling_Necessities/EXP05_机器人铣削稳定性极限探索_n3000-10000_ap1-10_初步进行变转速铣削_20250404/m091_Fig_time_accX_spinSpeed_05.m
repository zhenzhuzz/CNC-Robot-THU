% MATLAB Script to plot timestamps vs accX, timestamps vs spinSpeed and FFT of accX (5-7 seconds)

% 1. 读取数据
data = load('37.txt');  % 假设数据文件存储在当前工作目录

timestamps = data(:, 1);  % 第一列是时间戳
accX = data(:, 2);       % 第二列是 accX
spinSpeed = data(:, 3);  % 第三列是 spinSpeed

% 2. 创建一个 3 行 1 列的 subplot
figure;

% 3. 绘制第一个 subplot (timestamps vs accX)
ax1 = subplot(3, 1, 1);
plot(ax1, timestamps, accX);
f030_optimizeFig_Paper_05(ax1, 'Timestamps (s)', 'Acceleration (g)', 'Acceleration vs Timestamps', {}, 'northeast', [0.01, 0.01]);

% 4. 绘制第二个 subplot (timestamps vs spinSpeed)
ax2 = subplot(3, 1, 2);
plot(ax2, timestamps, spinSpeed);
f030_optimizeFig_Paper_05(ax2, 'Timestamps (s)', 'Spin Speed (rpm)', 'Spin Speed vs Timestamps', {}, 'northeast', [0.01, 0.01]);

% 5. 计算 5-7秒区间内的 accX 信号的 FFT
start_time = 8;  % 起始时间
end_time = 9;    % 结束时间

% 从原始数据中提取 5-7 秒区间的数据
idx = timestamps >= start_time & timestamps <= end_time;
t_selected = timestamps(idx);
accX_selected = accX(idx);

% 使用 f001_fourier_04 函数计算 FFT
[f, X_f] = f001_fourier_04(t_selected, accX_selected, true);

% 6. 绘制第三个 subplot (5-7秒 accX 的 FFT)
ax3 = subplot(3, 1, 3);
plot(ax3, f, X_f);
f030_optimizeFig_Paper_05(ax3, 'Frequency (Hz)', 'Magnitude', 'FFT of Acceleration (5-7 seconds)', {}, 'northeast', [0.01, 0.01]);
