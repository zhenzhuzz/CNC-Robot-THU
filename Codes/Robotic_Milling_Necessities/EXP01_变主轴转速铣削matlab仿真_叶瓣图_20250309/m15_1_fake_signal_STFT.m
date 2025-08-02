% Parameters
f_SP = 25;           % Spindle frequency (Hz)
f_CH = 133;          % Chatter frequency (Hz)
fs = 1000;           % Sampling frequency (Hz)
T = 3;               % Total simulation time (s)
t = 0:1/fs:T-1/fs;   % Time vector

% Signal s1 (Steady cutting state)
s1 = 2 * sin(2 * pi * f_SP * t) + ...
     3 * sin(2 * pi * 2 * f_SP * t) + ...
     5 * sin(2 * pi * 3 * f_SP * t);

% Signal s2 (Transition to chatter state with modulation)
s2 = (50 ./ (1 + exp(-15 * (t - 1))) - 25) .* ...
     cos(2 * pi * f_CH * t + 0.5 * sin(2 * pi * f_SP * t));

% Signal s3 (Full chatter state)
s3 = 25 * cos(2 * pi * f_CH * t + 0.5 * sin(2 * pi * f_SP * t));

% Signal s1 after 2.5 seconds (Return to steady state)
s4 = 2 * sin(2 * pi * f_SP * t) + ...
     3 * sin(2 * pi * 2 * f_SP * t) + ...
     5 * sin(2 * pi * 3 * f_SP * t);

% Gaussian white noise (with 15 dB power)
N = 10^(15/20) * randn(size(t));

% Final signal s(t) depending on time stages
s = zeros(size(t));
s(t <= 1) = s1(t <= 1) + N(t <= 1);  % Steady state
s((t > 1) & (t <= 1.5)) = s1((t > 1) & (t <= 1.5)) + s2((t > 1) & (t <= 1.5)) + N((t > 1) & (t <= 1.5));  % Transition
s((t > 1.5) & (t <= 2.5)) = s1((t > 1.5) & (t <= 2.5)) + s3((t > 1.5) & (t <= 2.5)) + N((t > 1.5) & (t <= 2.5));  % Full chatter
s((t > 2.5) & (t <= 3)) = s4((t > 2.5) & (t <= 3)) + N((t > 2.5) & (t <= 3));  % Return to steady state

% Parameters for STFT
windowLength = 0.01;  % 50 ms window
windowSamples = round(windowLength * fs);  % Convert to number of samples
n = length(s);  % Number of samples

% STFT calculation
[S, F, T_stft] = stft(s, fs, 'Window', hamming(windowSamples), 'OverlapLength', round(windowSamples / 2), 'FFTLength', 2^nextpow2(windowSamples));

% Panel 1: Plot the Displacement Signal (Original Signal)
figure;
subplot(3, 1, 1);
plot(t, s);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Displacement Signal');

% Panel 2: Energy Indicator (Sum of squared magnitudes of the STFT coefficients)
energyHistory = sum(abs(S).^2, 1);  % Sum the energy across frequencies (scales)
subplot(3, 1, 2);
plot(T_stft, energyHistory, 'LineWidth', 2);
ylabel('Energy');
title('Energy Indicator (Summed STFT Power)');

% Panel 3: Time-Frequency Plot (Display the STFT magnitude)
subplot(3, 1, 3);
imagesc(T_stft, F, abs(S));  % Display the STFT magnitude
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Time-Frequency Plot of the Signal');
colorbar;

