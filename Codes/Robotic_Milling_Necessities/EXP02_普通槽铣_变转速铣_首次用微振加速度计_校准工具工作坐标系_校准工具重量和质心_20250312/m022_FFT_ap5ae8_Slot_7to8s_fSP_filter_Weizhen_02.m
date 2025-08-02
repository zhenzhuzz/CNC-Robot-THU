%% m010_plot_XYZ_Acc_Weizhen_timeDomain.m
% 脚本示例：读取加速度数据并绘制时间域信号以及
% 7-8秒区间内 X 方向 FFT 频谱图，同时增加滤波后的 FFT 频谱图
%
% 注意：请根据实际文件路径修改 filepath

clc;
clear;
close all;
%% 时间域数据绘制
filepath = '9.txt';
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

%% FFT 分析：取7-8秒区间
% 提取7-8秒内的数据
idx = (time >= 7) & (time <= 8);
time_segment = time(idx);
X_segment = X(idx);

% 根据时间数据计算采样频率（假设时间间隔均匀）
Fs = 1/mean(diff(time_segment));
N = length(time_segment);

% 对 X 信号进行 FFT 变换
X_fft = fft(X_segment);

% 生成对应的正频率向量（只取一半）
f = Fs*(0:floor(N/2))/N;

% 计算 FFT 的幅值（只取正频率部分）
X_mag = abs(X_fft(1:floor(N/2)+1));


% 定义主轴转速频率（单位 Hz），例如 5000 rpm 转换为 Hz
mainRotFreq = 5000/60;  

% 对 X_fft 进行滤波：滤除主轴转速、mainRotFreq/2和mainRotFreq/4及其整数倍谐波，
% 滤波范围设定为目标频率前后各 5%
X_fft_filtered = notchFilterFFT(X_fft, Fs, mainRotFreq);

% 提取滤波后正频率部分的幅值
X_mag_filtered = abs(X_fft_filtered(1:floor(N/2)+1));

figure('Units','centimeters','Position',[2 2 20 4]); % 宽15cm，高5cm，适合论文
plot(f, X_mag, '--', 'LineWidth', 1.5, 'DisplayName', '原始 FFT');
hold on;
plot(f, X_mag_filtered, '-', 'LineWidth', 1.5, 'DisplayName', '滤波后 FFT');
xlabel('频率 (Hz)');
ylabel('幅值');
title('5mm切深 进给方向 加速度 FFT (7-8秒)');
legend('show');
xlim([2 500]);
ylim([0 3e5]);
optimizeFigure();
hold off;

% 保存图形为PNG文件，分辨率为1000 DPI
fileName = 'p022_FFT_ap5ae8_Slot_7to8s_fSP_filter_Weizhen_02.png'; % 输出文件名
print(gcf, fileName, '-dpng', '-r1500'); % 高分辨率保存图形为PNG


%% -------------------- Local Functions --------------------
function X_fft_filtered = notchFilterFFT(X_fft, Fs, mainRotFreq)
    N = length(X_fft);
    % 构造完整频率向量（考虑正负频率）
    f_full = (0:N-1)*(Fs/N);
    f_full(f_full >= Fs/2) = f_full(f_full >= Fs/2) - Fs;
    
    X_fft_filtered = X_fft;
    
    % 1. 滤除主轴转速及其整数倍频
    n = 1;
    while n * mainRotFreq <= max(abs(f_full))
        f_low = n * mainRotFreq * 0.95;
        f_high = n * mainRotFreq * 1.05;
        idx = find(abs(f_full) >= f_low & abs(f_full) <= f_high);
        X_fft_filtered(idx) = 0;
        n = n + 1;
    end
    
    % 2. 滤除1/2和1/4频率（仅n=1，不滤除它们的倍频）
    extraFreqs = [mainRotFreq/2, mainRotFreq/4];
    for i = 1:length(extraFreqs)
        f_low = extraFreqs(i) * 0.95;
        f_high = extraFreqs(i) * 1.05;
        idx = find(abs(f_full) >= f_low & abs(f_full) <= f_high);
        X_fft_filtered(idx) = 0;
    end
end

%% 本地函数：优化 Figure 设置
function optimizeFigure()
    % 优化当前图形的各项设置
    % 注意：以下设置会覆盖原有的标签、图例文字，可根据实际情况调整

    % 设置坐标区字体、线宽等属性
    set(gca, 'FontSize', 11, 'FontName', '宋体', 'LineWidth', 1, 'Box', 'on');
    grid on;
    
    % 修改坐标轴标签
    xlabel('频率(Hz)', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
    ylabel('幅值', 'FontSize', 13, 'FontWeight', 'bold', 'FontName', '宋体');
    % 若需要修改标题可取消注释下行
    % title('n4520-8300-10000_ap2_f450', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', '宋体');
    
    % 设置图例（这里的文字为示例，实际使用时请根据数据调整）
    lgd = legend({'原始 FFT', '滤波后 FFT'}, 'Location', 'northeast', 'FontSize', 12, 'FontName', '宋体');
    set(gcf, 'Color', 'w'); % 设置白色背景，便于论文插图
    % lgd.ItemTokenSize = [14, 14];  % 缩短图例中线条的长度

    % 设置刻度方向为内，并去掉上、右侧框线
    set(gca, 'TickDir', 'in');
    set(gca, 'Box', 'off');
    set(gca, 'TickLength', [0.01, 0.01]);

    % 设置 y 轴显示范围为 [-2, 2]
    % ylim([-2, 2]);

    % 绘制加粗的外框（不加入图例）
    xl = xlim;
    yl = ylim;
    plot([xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], ...
         'k-', 'LineWidth', 1, 'HandleVisibility', 'off');
end