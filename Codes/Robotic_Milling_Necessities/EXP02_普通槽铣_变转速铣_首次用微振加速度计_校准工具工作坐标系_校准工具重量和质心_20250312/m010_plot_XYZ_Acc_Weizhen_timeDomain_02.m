%% m010_plot_XYZ_Acc_Weizhen_timeDomain.m
% 脚本示例：调用 f021_readAcc_WeiZhen 函数绘制加速度的时间域数据以及
% 6-7秒区间内的 FFT 频谱图
%
% 注意：请根据实际文件路径修改 filepath

%% 时间域数据绘制
filepath = 'n5000ap0-30ae8f750.txt';
data = f021_readAcc_WeiZhen(filepath, 'XYZ');

% data 是一个 table，包含字段 Time, X, Y, Z
time = data.Time;
X = data.X;
Y = data.Y;
Z = data.Z;

figure(1);
subplot(3,1,1);
plot(time, X, '-');
xlabel('Time');
ylabel('X Acceleration');
title('X加速度时域数据');

subplot(3,1,2);
plot(time, Y, '-');
xlabel('Time');
ylabel('Y Acceleration');
title('Y加速度时域数据');

subplot(3,1,3);
plot(time, Z, '-');
xlabel('Time');
ylabel('Z Acceleration');
title('Z加速度时域数据');

%% FFT分析：取7-8秒区间
% 将 datetime 类型的时间转换为相对于起始时间的秒数
% time = seconds(time - time(1));

% 提取7-8秒内的数据
idx = time >= 7 & time <= 10;
time_segment = time(idx);
X_segment = X(idx);
Y_segment = Y(idx);
Z_segment = Z(idx);

% 根据时间数据计算采样频率
Fs = 1/mean(diff(time_segment));
N = length(time_segment);

% 对每个信号进行FFT变换
X_fft = fft(X_segment);
Y_fft = fft(Y_segment);
Z_fft = fft(Z_segment);

% 生成对应的正频率向量（只取一半）
f = Fs*(0:floor(N/2))/N;

% 计算FFT的幅值（只取正频率部分）
X_mag = abs(X_fft(1:floor(N/2)+1));
Y_mag = abs(Y_fft(1:floor(N/2)+1));
Z_mag = abs(Z_fft(1:floor(N/2)+1));

% 新建figure，并用三个subplot画出FFT结果
figure;
subplot(3,1,1);
plot(f, X_mag, '-');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('X加速度 FFT (7-8秒)');
xlim([0 500]);
ylim([0 2.5e5]);

subplot(3,1,2);
plot(f, Y_mag, '-');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Y加速度 FFT (7-8秒)');
xlim([0 500]);
ylim([0 2.5e5]);

subplot(3,1,3);
plot(f, Z_mag, '-');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Z加速度 FFT (7-8秒)');
xlim([0 500]);
ylim([0 2.5e5]);

