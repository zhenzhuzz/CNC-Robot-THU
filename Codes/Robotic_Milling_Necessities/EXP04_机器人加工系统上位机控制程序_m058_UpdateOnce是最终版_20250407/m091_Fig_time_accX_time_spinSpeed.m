% clc
% clear
% close all
% Script to load the data and plot the required figures
% 脚本用于加载数据并绘制所需的图形
[timestamps, accX, spinSpeed] = f020_read_timeStamps_accX_spinSpeed_from_txt_04('1.txt');

% Step 4: Create a figure with 3 subplots
% 步骤 4：创建一个包含 3 个子图的图形
figure('Units','centimeters','Position',[5 1 15 20]);

% Step 5: Plot timestamps vs accX in the first subplot
% 步骤 5：在第一个子图中绘制时间戳与 accX 的关系
ax1 = subplot(3, 1, 1);
plot(ax1, timestamps, accX,'LineWidth',1.3);
f030_optimizeFig_Paper_04(ax1, 'Timestamps (s)', 'Acceleration (g)', 'Acceleration vs Timestamps','tight','tight');

% Step 6: Plot timestamps vs spinSpeed in the second subplot
% 步骤 6：在第二个子图中绘制时间戳与 spinSpeed 的关系
ax2 = subplot(3, 1, 2);
plot(ax2, timestamps, spinSpeed,'LineWidth',1.3);
f030_optimizeFig_Paper_04(ax2, 'Timestamps (s)', 'Spin Speed (rpm)', 'Spin Speed vs Timestamps','tight',[4500 8000]);

% Step 7: Create a spectrogram for accX in the third subplot
% 步骤 7：在第三个子图中绘制 accX 的时频图
ax3 = subplot(3, 1, 3);
% Create a spectrogram with a window length of 256 samples, 50% overlap
window_length = 256;  
overlap = 128;  
nfft = 512;  % Number of FFT points

% Spectrogram function returns the time, frequency, and magnitude of the spectrogram
[s, f, t_spec] = spectrogram(accX, window_length, overlap, nfft, 1 / (timestamps(2) - timestamps(1))); 

% Plot the spectrogram
imagesc(t_spec, f, 20*log10(abs(s)));  % Use log scale for better visualization
axis xy;
colorbar;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Spectrogram of Acceleration (accX)');

f030_optimizeFig_Paper_04(ax3, 'Time (s)', 'Frequency (Hz)', 'Spectrogram of Acceleration', 'tight',[0 1000]);
