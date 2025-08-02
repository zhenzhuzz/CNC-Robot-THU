function [magnitude_fft, magnitude_phase_fft, complex_fft, time, acceleration] = call_fft(t, f, lt, ut, fmax)
    %% Select Data within the Time Range
    selected_indices = t >= lt & t <= ut;
    time = t(selected_indices);
    acceleration = f(selected_indices);

    %% Recalculate Sampling Parameters
    dt = mean(diff(time));
    Fs = 1 / dt;  % Sampling frequency

    %% Plot Original Time History
    % plot_time_history(1, 'Acceleration (m/s^2)', 'Original Time History', [t, f], 0);

    %% FFT Analysis Setup
    mmm = length(acceleration);  % Number of samples
    df = Fs / mmm;  % Frequency resolution
    tmi = time(1);  % Initial time
    io = 1;  % Time array calculation preference

    % Get FFT Parameters
    [mk, freq, ~, ~, ~] = FFT_time_freq_set(mmm, 1, dt, df, tmi, io);

    % Adjust Maximum Frequency
    fmax = min(fmax, freq(mk));

    %% Perform FFT Analysis
    acc_info(dt, df, Fs);  % Display acceleration info
    [magnitude_fft, magnitude_phase_fft, complex_fft] = ...
        fft_function(1, 2, acceleration, dt, 'Acceleration (m/s^2)', fmax);
end
