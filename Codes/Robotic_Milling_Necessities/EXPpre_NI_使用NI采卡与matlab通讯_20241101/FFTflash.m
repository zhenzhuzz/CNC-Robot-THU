%============================================================
% Script Name:  FFTflash.m
% Author:       Zhu Zhen
% Date:         2024.12.3
% Description:  
%   This script visualizes the evolution of FFT (Fast Fourier 
%   Transform) magnitude over time from the data stored in 
%   a variable called FFTLog. The script iteratively plots 
%   the FFT data for each timestamp to show changes over time.
%
% Prerequisites:
%   - Load the `FFTLog.mat` file, which should contain a cell 
%     array named FFTLog with the following structure:
%       FFTLog{i, 1}: Timestamp (scalar)
%       FFTLog{i, 2}: Struct with the fields:
%                     - Frequencies: Column vector of frequencies (Hz)
%                     - FFT_mag: Column vector of FFT magnitudes
%   - Ensure the sampling rate is 12800 samples/s.
%
% Instructions:
%   1. Load the `FFTLog.mat` file into the MATLAB workspace.
%   2. Run this script.
%============================================================

% Adjustable parameter: Maximum frequency (Hz) for x-axis visualization
fmax = 1000;  % Set the x-axis upper limit (up to 6400 Hz)

% Create a figure
figure;
xlabel('Frequency (Hz)');
ylabel('FFT Magnitude');
title('FFT Evolution Over Time');

% Loop through each entry in FFTLog
for i = 1:length(FFTLog)
    % Clear the previous frame
    cla;

    % Extract the timestamp and the corresponding FFT data
    timestamp = FFTLog{i, 1}; % Timestamp for the frame
    fftStruct = FFTLog{i, 2}; % Struct containing Frequencies and FFTData
    frequencies = fftStruct.Frequencies; % Frequencies as a column vector
    fftMagnitude = fftStruct.FFT_mag;   % FFT magnitudes as a column vector

    % Plot the FFT data for this frame
    plot(frequencies, fftMagnitude, 'LineWidth', 1);
    
    % Update the title with the current timestamp
    title(['Time: ' num2str(timestamp, '%.2f') ' s']);
    
    % Set x-axis limits based on frequency range and fmax from metadata
    xlim([min(frequencies), min(fmax, max(frequencies))]); % Use fmax as upper limit
    
    % Pause briefly for visualization (adjust for time lapse speed)
    pause(0.1); % Pause for 0.1 seconds before the next frame
end

disp('FFT Evolution visualization complete.');
