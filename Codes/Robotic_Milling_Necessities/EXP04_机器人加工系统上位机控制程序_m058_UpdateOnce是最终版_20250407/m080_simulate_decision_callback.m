%% simulate_decision_callback.m
% 本脚本模拟实时数据更新：每 0.1 秒获取一段数据，并调用决策函数 m060_Decision_fft_filter_report.m
% 输出每次调用的处理时间、决策状态及突出频率，以验证决策函数能否跟上实时更新的节拍。

clear; clc; close all;

%% 仿真参数设置
Fs = 12800;              % 采样频率 (Hz)
dt = 1/Fs;               % 采样时间间隔
% 各段持续时间（秒）：段1: 1s, 段2: 0.5s, 段3: 1s, 段4: 1s, 段5: 1s, 段6: 1s，共6.5秒
durations = [1, 0.5, 1, 1, 1, 1];
n_segments = length(durations);
T_total = sum(durations);

%% 主轴与颤振参数
n_initial = 3000;            % 初始转速 3000 rpm
f_SP_initial = n_initial/60; % 主轴频率，3000/60 = 50 Hz
f_CH = 133;                  % 颤振频率固定为 133 Hz
% 调速后参数：根据公式计算得到
z = 4; % 刀具齿数
k_new = round((f_CH*60)/(z*n_initial));  % 例如 round((133*60)/(4*3000))
n_new = (60*f_CH)/(k_new*z);               % 得到调速后的 rpm
f_SP_new = n_new/60;                       % 对应的新主轴频率

noise_amp = 0.5;           % 高斯白噪声幅值

%% 仿真信号生成（与之前主仿真类似）
time_all = [];
accX_all = [];
spinSpeed_all = [];
segment_boundaries = zeros(n_segments,2);
t_offset = 0;

for i = 1:n_segments
    dur = durations(i);
    t_seg = (0:dt:dur-dt)' + t_offset;  % 保证时域连续
    N_seg = length(t_seg);
    t_local = t_seg - t_offset;         % 每段局部时间从0开始
    s = zeros(N_seg,1);
    % 默认采用初始转速
    current_n = n_initial;
    current_f_SP = f_SP_initial;
    
    if i == 1
        % 段1：稳定状态，仅 s₁（多阶刀齿周期分量）
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s = s1;
    elseif i == 2
        % 段2：过渡状态，s = s₁ + s₂，s₂ 采用指数函数实现平滑过渡
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s2 = (50./(1+exp(-15*(t_local)))-25) .* cos(2*pi*f_CH*t_local + 0.5*sin(2*pi*current_f_SP*t_local));
        s = s1 + s2;
    elseif i == 3
        % 段3：颤振状态，s = s₁ + s₃
        s1 = 2*sin(2*pi*current_f_SP*t_local) + ...
             3*sin(2*pi*2*current_f_SP*t_local) + ...
             5*sin(2*pi*3*current_f_SP*t_local) + ...
             2*sin(2*pi*4*current_f_SP*t_local) + ...
             1*sin(2*pi*5*current_f_SP*t_local);
        s3 = 25*cos(2*pi*f_CH*t_local + 0.5*sin(2*pi*current_f_SP*t_local));
        s = s1 + s3;
    elseif i == 4
        % 段4：调速后稳定，使用新转速 n_new
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
        % 段6：调速后稳定，使用新转速
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
    
    time_all = [time_all; t_seg];
    accX_all = [accX_all; s];
    spinSpeed_all = [spinSpeed_all; current_n * ones(N_seg,1)];
    
    segment_boundaries(i,:) = [t_offset, t_offset+dur];
    t_offset = t_offset + dur;
end

% 生成 dataLog 表
dataLog = table(time_all, accX_all, spinSpeed_all, 'VariableNames', {'time', 'accX', 'spinSpeed'});
fprintf('Simulated dataLog generated, total time = %.2f s, total samples = %d.\n', T_total, height(dataLog));

%% 模拟实时更新调用决策函数
% 每 0.1 秒更新一次（采样点数 = 0.1*Fs）
update_period = 0.1; 
samples_per_update = round(update_period * Fs);
total_samples = height(dataLog);
num_updates = floor(total_samples / samples_per_update);

% 预定义 report 结构数组，记录每次调用结果
report = struct('updateIndex', [], 'timestamp', [], 'decision', [], 'prominentFreq', [], 'processingTime', []);

% 设置检测阈值（可根据实际情况调节）
threshold = 10;

fprintf('\n开始模拟实时决策回调：每 %.2f s 更新一次，共 %d 次:\n', update_period, num_updates);
for i = 1:num_updates
    % 取当前 0.1 秒数据块（这里采用最近 0.1 秒数据，可替换为滑动窗口）
    idx_start = (i-1)*samples_per_update + 1;
    idx_end = i*samples_per_update;
    t_chunk = dataLog.time(idx_start:idx_end);
    acc_chunk = dataLog.accX(idx_start:idx_end);
    currentSpin = mean(dataLog.spinSpeed(idx_start:idx_end));
    
    % 测量决策函数调用时间
    tic;
    [isSafe, prominentFreq, f, X_f_filtered] = m060_Decision_fft_filter_report(t_chunk, acc_chunk, currentSpin, threshold);
    processingTime = toc;
    
    % 保存报告信息
    report(i).updateIndex = i;
    report(i).timestamp = t_chunk(end);
    report(i).decision = ternary(isSafe, '稳定', '颤振');
    report(i).prominentFreq = prominentFreq;
    report(i).processingTime = processingTime;
    
    % 输出当前更新报告
    fprintf('t = %.3f s: 决策 = %s, 突出频率 = %.2f Hz, 处理时间 = %.4f s\n', ...
            t_chunk(end), report(i).decision, prominentFreq, processingTime);
    
    % 模拟实时等待（实际环境下此等待为周期性回调定时器，此处可取消 pause 以加速仿真）
    pause(update_period);
end

% 将 report 转换为表格显示
reportTable = struct2table(report);
disp('总体实时决策回调报告:');
disp(reportTable);

%% 绘制决策进程报告
figure;
subplot(2,1,1);
% 这里用离散点展示决策状态：0 表示稳定，1 表示颤振
decision_numeric = double(strcmp(reportTable.decision, '颤振'));
plot(reportTable.timestamp, decision_numeric, 'o-','LineWidth',1.5);
xlabel('时间 (s)');
ylabel('决策状态 (0: 稳定, 1: 颤振)');
title('实时决策回调状态');
grid on;

subplot(2,1,2);
plot(reportTable.timestamp, reportTable.processingTime, 's-','LineWidth',1.5);
xlabel('时间 (s)');
ylabel('处理时间 (s)');
title('每次决策函数处理时间');
grid on;

%% 辅助函数：三元判断（inline function）
function out = ternary(cond, trueVal, falseVal)
    if cond
        out = trueVal;
    else
        out = falseVal;
    end
end
