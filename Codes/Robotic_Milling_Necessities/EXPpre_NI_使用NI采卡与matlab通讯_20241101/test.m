% Load the data
% timestamps = your_timestamps_variable; % Replace with actual variable name
% data = your_data_variable; % Replace with actual variable name
sampling_rate = 12800;


% Call the FFT function
[frequencies, amplitudes] = compute_fft(data, timestamps, []); % Use timestamps

% Plot the results
figure;
plot(frequencies, amplitudes);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('FFT of the Signal');
grid on;
%%
% clc;
% clear all;
% Define system parameters
mass = 1.0;        % Mass (kg)
stiffness = 1000;  % Spring constant (N/m)
damping = 10;      % Damping coefficient (N·s/m)
force_amp = 100;   % Amplitude of cutting force (N)
force_freq = 50;   % Frequency of cutting force (Hz)

% Open a new Simulink model
modelName = 'MillingVibrationModel';
open_system(new_system(modelName));

% Add blocks to the model
add_block('simulink/Sources/Sine Wave', [modelName, '/Cutting Force']);
add_block('fl_lib/Mechanical/Translational Elements/Mass', [modelName, '/Mass']);
add_block('fl_lib/Mechanical/Translational Elements/Translational Spring', [modelName, '/Spring']);
add_block('fl_lib/Mechanical/Translational Elements/Translational Damper', [modelName, '/Damper']);
add_block('fl_lib/Mechanical/Translational Elements/Mechanical Translational Reference', [modelName, '/Reference']);
add_block('fl_lib/Mechanical/Mechanical Sensors/Ideal Translational Motion Sensor', [modelName, '/Motion Sensor']);
add_block('simulink/Commonly Used Blocks/Scope', [modelName, '/Scope']);

% Set block parameters
set_param([modelName, '/Cutting Force'], 'Amplitude', num2str(force_amp), 'Frequency', num2str(force_freq));
set_param([modelName, '/Mass'], 'Mass', num2str(mass));
set_param([modelName, '/Spring'], 'Spring Rate', num2str(stiffness));
set_param([modelName, '/Damper'], 'Damping Coefficient', num2str(damping));

% Connect blocks
add_line(modelName, 'Cutting Force/1', 'Mass/1');
add_line(modelName, 'Mass/R', 'Spring/R');
add_line(modelName, 'Spring/C', 'Reference/R');
add_line(modelName, 'Mass/R', 'Damper/R');
add_line(modelName, 'Damper/C', 'Reference/R');
add_line(modelName, 'Mass/R', 'Motion Sensor/R');
add_line(modelName, 'Motion Sensor/V', 'Scope/1');

% Save and open the model
save_system(modelName);
open_system(modelName);

%%
N = 1024;                 % Number of samples
f_s = 12800;              % Sampling rate
t = (0:N-1) / f_s;        % Time vector
signal = sin(2*pi*1000*t) + 0.5*sin(2*pi*2000*t); % Example signal

% Compute FFT
fft_result = fft(signal);

% Two-Sided Spectrum
two_sided_amplitude = abs(fft_result);

% Single-Sided Spectrum
single_sided_amplitude = two_sided_amplitude(1:ceil(N/2));
single_sided_amplitude(2:end-1) = 2 * single_sided_amplitude(2:end-1);

% Frequency Axis
frequencies = (0:ceil(N/2)-1) * (f_s / N);

% Plot
figure;
subplot(2,1,1);
plot((0:N-1)*(f_s/N), two_sided_amplitude);
title('Two-Sided Spectrum');
xlabel('Frequency (Hz)');
ylabel('Amplitude');

subplot(2,1,2);
plot(frequencies, single_sided_amplitude);
title('Single-Sided Spectrum');
xlabel('Frequency (Hz)');
ylabel('Amplitude');
%%
function [frequencies, amplitudes] = compute_fft(signal, timestamps, sampling_rate)
    % compute_fft - Computes the FFT of a signal with optional timestamps
    %
    % Inputs:
    %   signal         - The input signal as a column vector
    %   timestamps     - (Optional) Time values corresponding to the signal
    %   sampling_rate  - The sampling rate of the signal in Hz (required if timestamps are not given)
    %
    % Outputs:
    %   frequencies     - Frequency bins (Hz)
    %   amplitudes      - Amplitude spectrum of the signal
    
    % Check for timestamps
    if nargin > 1 && ~isempty(timestamps)
        % Compute the sampling rate from timestamps if provided
        time_differences = diff(timestamps);
        if any(abs(diff(time_differences)) > 1e-6)
            error('Timestamps are non-uniform. Use interpolation or advanced DFT.');
        end
        sampling_rate = 1 / mean(time_differences);
    elseif nargin < 3 || isempty(sampling_rate)
        error('Either timestamps or sampling rate must be provided.');
    end
    
    % Number of samples
    N = length(signal);
    
    % Compute the FFT
    fft_result = fft(signal);
    
    % Compute the two-sided spectrum and then the single-sided spectrum
    two_sided_amplitude = abs(fft_result / N);
    single_sided_amplitude = two_sided_amplitude(1:ceil(N/2));
    single_sided_amplitude(2:end-1) = 2 * single_sided_amplitude(2:end-1);
    
    % Frequency bins
    frequencies = (0:ceil(N/2)-1) * (sampling_rate / N);
    
    % Output amplitudes and frequencies
    amplitudes = single_sided_amplitude;
end

