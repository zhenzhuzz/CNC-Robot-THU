%% main_simulation.m
% 清空工作区和命令窗口
clear; clc; close all;

%% 仿真参数设置
Fs = 12800;              % 采样频率 (Hz)
dt = 1/Fs;               % 采样时间间隔
% 各段持续时间（秒）：段1: 1s, 段2: 0.5s, 段3: 1s, 段4: 1s, 段5: 1s, 段6: 1s，共6.5秒
durations = [1, 0.5, 1, 1, 1, 1];
n_segments = length(durations);

% 用于生成噪声的幅值（此处设为 0.5，可根据需要调整）
noise_amp = 0.5;

%% 主轴转速和频率参数
% 初始状态
n_initial = 3000;            % 初始转速 3000 rpm
f_SP_initial = n_initial/60; % 主轴频率，3000/60 = 50 Hz
% 颤振频率（固定）
f_CH = 133;  

% 调速后参数：根据公式
%   k_new = round( (f_CH*60)/(z*n_initial) )
%   n_new = 60*f_CH/(k_new*z)
z = 4; % 刀具齿数
k_new = round((f_CH*60)/(z*n_initial));  % 此处 round((133*60)/(4*3000)) ≈ 1
n_new = (60*f_CH)/(k_new*z);               % n_new ≈ 1995 rpm
f_SP_new = n_new/60;                       % 新主轴频率 ≈ 33.25 Hz

%% 信号构造说明
% 稳定状态分量 s₁（含多阶谐波）：
%   s₁ = 2*sin(2π f_SP t) + 3*sin(2π*2f_SP t) + 5*sin(2π*3f_SP t) + 2*sin(2π*4f_SP t) + 1*sin(2π*5f_SP t)
%
% 过渡状态分量 s₂：
%   s₂ = (50/(1+exp(-15*t_local))-25) * cos(2π f_CH t_local + 0.5*sin(2π f_SP t_local))
%
% 颤振状态分量 s₃：
%   s₃ = 25*cos(2π f_CH t_local + 0.5*sin(2π f_SP t_local))
%
% 分段构造：
%   段1（稳定）：s = s₁, 使用 n = 3000 (f_SP_initial)
%   段2（过渡）：s = s₁ + s₂, 使用 n = 3000
%   段3（颤振）：s = s₁ + s₃, 使用 n = 3000
%   段4（稳定）：s = s₁, 使用调速后 n = n_new (f_SP_new)
%   段5（颤振）：s = s₁ + s₃, 使用 n = 3000
%   段6（稳定）：s = s₁, 使用调速后 n = n_new

%% 生成各段信号并拼接
time_all = [];
accX_all = [];
spinSpeed_all = [];
segment_boundaries = zeros(n_segments,2);
t_offset = 0;

for i = 1:n_segments
    dur = durations(i);
    % 构造当前段时间向量（保证全段连续）
    t_seg = (0:dt:dur-dt)' + t_offset;
    N_seg = length(t_seg);
    % 各段以局部时间 t_local 从 0 开始构造
    t_local = t_seg - t_offset;
    s = zeros(N_seg,1);
    % 默认使用初始转速
    current_n = n_initial;
    current_f_SP = f_SP_initial;
    
    if i == 1
        % 段1：稳定状态，s = s₁
        seg_type = 'stable';
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s = s1;
    elseif i == 2
        % 段2：过渡状态，s = s₁ + s₂
        seg_type = 'transition';
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        % 采用指数函数构造调幅－调频过渡
        s2 = (50./(1+exp(-15*(t_local)))-25) .* cos(2*pi*f_CH*t_local + 0.5*sin(2*pi*current_f_SP*t_local));
        s = s1 + s2;
    elseif i == 3
        % 段3：颤振状态，s = s₁ + s₃
        seg_type = 'chatter';
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s3 = 25*cos(2*pi*f_CH*t_local + 0.5*sin(2*pi*current_f_SP*t_local));
        s = s1 + s3;
    elseif i == 4
        % 段4：调速后稳定，使用新转速 n_new
        seg_type = 'stable';
        current_n = n_new;
        current_f_SP = f_SP_new;
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s = s1;
    elseif i == 5
        % 段5：颤振状态，回到初始转速
        seg_type = 'chatter';
        current_n = n_initial;
        current_f_SP = f_SP_initial;
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s3 = 25*cos(2*pi*f_CH*t_local + 0.5*sin(2*pi*current_f_SP*t_local));
        s = s1 + s3;
    elseif i == 6
        % 段6：调速后稳定，使用 n_new
        seg_type = 'stable';
        current_n = n_new;
        current_f_SP = f_SP_new;
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s = s1;
    end
    
    % 加入高斯白噪声
    s = s + noise_amp * randn(size(s));
    
    % 将当前段数据拼接到总数据中
    time_all = [time_all; t_seg];
    accX_all = [accX_all; s];
    spinSpeed_all = [spinSpeed_all; current_n * ones(N_seg,1)];
    
    segment_boundaries(i,:) = [t_offset, t_offset+dur];
    t_offset = t_offset + dur;
end

% 生成 dataLog 表（包含 time、accX、spinSpeed 三列）
dataLog = table(time_all, accX_all, spinSpeed_all, 'VariableNames', {'time', 'accX', 'spinSpeed'});
assignin('base', 'dataLog', dataLog);
disp('Simulated dataLog 已生成，并赋值到工作区变量 "dataLog".');

%% 绘制整体时域信号
figure;
subplot(2,1,1);
plot(dataLog.time, dataLog.accX, 'b-');
xlabel('时间 (s)'); ylabel('加速度');
title('模拟加速度信号');
grid on;

subplot(2,1,2);
plot(dataLog.time, dataLog.spinSpeed, 'r-');
xlabel('时间 (s)'); ylabel('主轴转速 (rpm)');
title('模拟主轴转速');
grid on;

%% 调用决策函数 m060_Decision_fft_filter_report 进行各段检测
% 请确保 f010_fourier.m 与 m060_Decision_fft_filter_report.m 均在当前路径下
% 设置检测阈值（根据经验调节，使颤振状态能触发检测，此处设 threshold = 10）
threshold = 10;

disp('各段决策函数测试结果:');
% 为了在同一 figure 中显示所有 FFT 谱，采用 2×3 的 subplot 布局
figure;
for i = 1:n_segments
    idx = dataLog.time >= segment_boundaries(i,1) & dataLog.time < segment_boundaries(i,2);
    t_seg = dataLog.time(idx);
    acc_seg = dataLog.accX(idx);
    currentSpin = mean(dataLog.spinSpeed(idx));
    
    % 调用决策函数 m060_Decision_fft_filter_report（检测输出：isSafe 为 true 表示状态“稳定”，false 表示“颤振”）
    [isSafe, prominentFreq, f, X_f_filtered] = m060_Decision_fft_filter_report(t_seg, acc_seg, currentSpin, threshold);
    if isSafe
        status_text = '稳定';
    else
        status_text = '颤振';
    end
    fprintf('段 %d: 平均转速 = %.1f rpm, 检测状态 = %s, 突出频率 = %.2f Hz\n', ...
        i, currentSpin, status_text, prominentFreq);
    
    subplot(2,3,i);
    plot(f, X_f_filtered, 'b-', 'LineWidth',1.5);
    xlabel('频率 (Hz)');
    ylabel('幅值');
    title(sprintf('段 %d (%s)', i, status_text));
    xlim([0 500]);
    grid on;
end
