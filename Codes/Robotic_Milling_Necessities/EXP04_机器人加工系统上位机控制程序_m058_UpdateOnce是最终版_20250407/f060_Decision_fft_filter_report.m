function [isChatter, prominentFreq, f, X_f_filtered, max_amp] = f060_Decision_fft_filter_report(t, x_t, currentSpindleSpeed, threshold)
% f060_Decision_fft_filter_report - 通过FFT和滤波判断加速度信号中是否存在异常振动
%
% 说明：
%   此函数先调用已有的 f001_fourier_04 函数计算加速度信号的单边FFT谱，
%   然后滤除主轴相关的谐波（包括主轴基本频率的整数倍以及1/2和1/4倍谐波），
%   最后通过阈值判断剩余谱中是否存在突出峰值（即异常振动）。
%
% 输入参数：
%   t                   - 时间向量 (秒)
%   x_t                 - 加速度信号向量
%   currentSpindleSpeed - 当前主轴转速 (RPM)
%   threshold           - 判定阈值：若滤波后峰值大于此阈值，则认为存在异常振动
%
% 输出参数：
%   isChatter      - 布尔值，true 表示检测到颤振（异常振动），false 表示无异常（稳定）
%   prominentFreq  - 如果检测到异常振动，则返回突出峰值频率 (Hz)；否则返回 NaN
%   f              - FFT 计算得到的频率向量 (Hz)
%   X_f_filtered   - 经过滤波（移除主轴谐波）后的幅值谱
%   max_amp        - 滤波后的最大幅值
%
% 调用示例：
%   [isChatter, f_peak, f, X_f_filtered, max_amp] = f020_decision(t, x_t, currentSpindleSpeed, threshold);
%
% 注意：
%   此函数依赖于当前目录下的 f001_fourier_04 函数，请确保 f001_fourier_04.m 文件可用。

    % 1. 使用 f001_fourier_04 计算FFT谱，去除直流分量有助于更准确检测频谱特性
    [f, X_f] = f001_fourier_04(t, x_t, true);
    
    % 2. 计算主轴的基本频率（单位：Hz）
    f0 = currentSpindleSpeed / 60;
    
    % 3. 设置一个容差，用于匹配待滤除的频率范围
    %    这里选择 5% 的 f0 或至少 0.5 Hz
    if f0 > 0
        tol = max(0.5, 0.05 * f0);
    else
        tol = 0;
    end
    
    % 4. 对FFT幅值谱进行滤波：滤除主轴谐波
    X_f_filtered = X_f;  % 复制一份用于滤波
    if f0 > 0
        % 需要滤除的频率包括：主轴整数倍谐波以及 f0/2 与 f0/4
        harmonics = [f0/4, f0/2];
        max_n = floor(max(f) / f0);
        integer_harmonics = f0 * (1:max_n);
        harmonics = unique([harmonics, integer_harmonics]);
        
        % 对于每个待滤除的谐波频率，将其附近的谱值置零
        for k = 1:length(harmonics)
            idx = find(abs(f - harmonics(k)) < tol);
            X_f_filtered(idx) = 0;
        end
    end
    
    % 5. 在滤波后的谱中找到最大幅值及其对应频率
    [max_amp, idx_max] = max(X_f_filtered);
    if isempty(idx_max)
        prominentFreq = NaN;
    else
        prominentFreq = f(idx_max);
    end
    
    % 6. 判断：如果滤波后峰值大于设定阈值，则认为存在异常振动（颤振）
    if max_amp > threshold
        isChatter = true;  % 异常振动（颤振）
    else
        isChatter = false; % 正常
        prominentFreq = NaN;
    end
end
