clc
clear
close all
% Script to load the data and plot the required figures
% 脚本用于加载数据并绘制所需的图形
load('n_new_1.mat');
[timestamps, accX, spinSpeed, isChatter, fc] = f020_read_timeStamps_accX_spinSpeed_from_txt_07('1.txt');

% Step 4: Create a figure with 3 subplots
% 步骤 4：创建一个包含 3 个子图的图形
figure('Units','centimeters','Position',[5 1 8.5 20]);

% Step 5: Plot timestamps vs accX in the first subplot
% 步骤 5：在第一个子图中绘制时间戳与 accX 的关系
ax1 = subplot(5, 1, 1);
plot(ax1, timestamps, accX,'LineWidth',1.3,'Color',[0.5 0.5 0.5]);
hold on;
xline([2.6 2.9 4.8 6.4 6.9],'r--','LineWidth',0.8);
f030_optimizeFig_Paper_07(ax1, '{\it t} (s)', '{\it a_x}(g)', '',[2 8],'tight');

ax2 = subplot(5, 1, 2);
plot(ax2, timestamps, isChatter,'LineWidth',1.3);
hold on;
xline([2.6 2.9 4.8 6.4 6.9],'r--','LineWidth',0.8);
f030_optimizeFig_Paper_07(ax2, '{\it t} (s)', '{\it C}', '',[2 8],[-0.5,1.5]);

ax3 = subplot(5, 1, 3);
plot(ax3, timestamps, fc,'LineWidth',1.3);
hold on;
xline([2.6 2.9 4.8 6.4 6.9],'r--','LineWidth',0.8);
f030_optimizeFig_Paper_07(ax3, '{\it t} (s)', '{\it f_c} (Hz)', '',[2 8],[150 850]);


% Step 6: Plot timestamps vs spinSpeed in the second subplot
% 步骤 6：在第二个子图中绘制时间戳与 spinSpeed 的关系
ax4 = subplot(5, 1, 4);
plot(ax4, timestamps, spinSpeed,'LineWidth',1.3);
hold on;
plot(ax4, timestamps, n_new_1,'LineWidth',1.3,'Color',[0.5 0.5 0.5]);
hold on;
xline([2.6 2.9 4.8 6.4 6.9],'r--','LineWidth',0.8);
f030_optimizeFig_Paper_07(ax4, '{\it t} (s)', '{\it n} (rpm)', '',[2 8],[4200 8300]);
f032_legend_07(ax4,'legendTexts', {'{\it n}_c', '{\it n}_s'}, 'legendLocation','southeast');


% Step 7: Create a spectrogram for accX in the third subplot
% 步骤 7：在第三个子图中绘制 accX 的时频图
ax4 = subplot(5, 1, 5);
% Create a spectrogram with a window length of 256 samples, 50% overlap
window_length = 256;  
overlap = 128;  
nfft = 512;  % Number of FFT points

% Spectrogram function returns the time, frequency, and magnitude of the spectrogram
[s, f, t_spec] = spectrogram(accX, window_length, overlap, nfft, 1 / (timestamps(2) - timestamps(1))); 

% Plot the spectrogram
imagesc(t_spec, f, 20*log10(abs(s)));  % Use log scale for better visualization
axis xy;
% colorbar;
hold on;
xline([2.6 2.9 4.8 6.4 6.9],'r--','LineWidth',0.8);
f030_optimizeFig_Paper_07(ax4, '{\it t} (s)', '{\it f} (Hz)', '', [2 8],[0 1000]);
f060_saveFigPNG_asFileName_05(mfilename('fullpath'));