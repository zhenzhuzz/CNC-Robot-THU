function [f, X_f] = fourier(t, x_t)
    % FOURIER Compute the FFT of a signal and return frequency and magnitude
    %
    % Inputs:
    %   t   - Time vector (s)
    %   x_t - Signal vector
    %
    % Outputs:
    %   f   - Frequency vector (Hz)
    %   X_f - Magnitude of FFT

    N = length(t);
    if N < 2
        error('Time vector must have at least two elements.');
    end

    t_step = t(2) - t(1);  % Time step
    f_max = 0.5 / t_step;  % Nyquist frequency

    % Compute FFT
    XX = fft(x_t);

    % Compute frequency vector
    if mod(N, 2) == 0
        % Even number of points
        X_f = XX(1:N/2+1);
        f = linspace(0, f_max, N/2+1);
    else
        % Odd number of points
        X_f = XX(1:(N+1)/2);
        f = linspace(0, f_max*(N-1)/N, (N+1)/2);
    end

    % Normalize FFT output
    X_f = abs(X_f) / N;
end


% Note: A multiple transformation using fourier and invfourier is 
% not reversible. In such a case it is better to transform directly 
% by means of fft and ifft and to keep the time or frequency vector.
