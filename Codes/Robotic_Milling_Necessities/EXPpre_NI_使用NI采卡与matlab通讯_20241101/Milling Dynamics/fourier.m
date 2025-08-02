% Fourier transform via FFT
% Copyright
% Zhen Zhu
% January 5, 2025
%
% Input:
% t     - time domain (in s) -> vector of length N
%           - the first time is 0
%           - equidistant time steps
% x_t   - time function -> vector of length N
% modus - mode -> String
%   'pulse' -> transform of a pulse
%   'sinus' -> transform of a continuous signal
%   Background: The mode solely influences the normalization of the amplitude 
%   of the spectrum.
%
% Output:
% f   - frequency domain (in Hz) -> row vector
%       - length is N/2+1, if N is even
%       - length is (N+1)/2, if N is odd
%       - first frequency is 0
%       - equidistant frequency steps
% X_f - spectrum -> row vector
%       - length is N/2+1, if N even
%       - length is (N+1)/2, if N odd
%
% Remark:
% - both row and column vectors are allowed for the input
% - the length of the vectors should be a power of 2 for faster operation

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
