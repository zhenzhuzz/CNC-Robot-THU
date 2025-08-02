function [f, X_f] = f001_fourier_04(t, x_t, remove_mean)
    % FFT频谱计算(单边归一化频谱，推荐用于论文和工程)
    %
    % Inputs:
    %   t            - 时间向量(s)
    %   x_t          - 信号向量
    %   remove_mean  - 是否去除信号平均值(true/false, 默认false)
    %
    % Outputs:
    %   f            - 频率向量(Hz)
    %   X_f          - FFT单边幅值谱

    arguments
        t (:,1) double
        x_t (:,1) double
        remove_mean (1,1) logical = false
    end

    N = length(t);
    if N < 2
        error('时间向量长度必须大于1.');
    end

    Fs = 1/mean(diff(t));
    
    if remove_mean
        x_t = x_t - mean(x_t); % 去除直流分量
    end
    
    % FFT计算
    X_fft = fft(x_t);

    % 单边频谱计算(严谨处理奇偶)
    if mod(N,2) == 0
        f = Fs*(0:(N/2))/N;
        X_f = abs(X_fft(1:N/2+1))/N;
        X_f(2:end-1) = 2*X_f(2:end-1);
    else
        f = Fs*(0:((N-1)/2))/N;
        X_f = abs(X_fft(1:(N+1)/2))/N;
        X_f(2:end) = 2*X_f(2:end);
    end
end
