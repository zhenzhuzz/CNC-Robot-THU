clear; close all; clc;

% 假设已经加载了FRF数据：frf, f, fs
filename = 'ap8_FRF3y4y.txt';  % 文件名（根据实际数据文件修改）
[freq, FRF] = f100_read_frf_txt(filename);

fs = max(freq) * 2;  % 采样频率假设为最大频率的两倍

% 绘制稳态响应图
figure;
plot(freq, abs(FRF), 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (g/N)');
title('FRF Magnitude (Steady-State Response)');
grid on;

% 使用modalsd生成稳定性图，最多识别20个模态
figure;
modalsd(FRF, freq, fs, 'MaxModes', 20);

% % 使用更严格的稳定性标准（例如：频率稳定性和阻尼比稳定性更严格）
% figure;
% modalsd(FRF, freq, fs, 'MaxModes', 20, 'SCriteria', [1e-4 0.002]);

% 只限制频率范围到0到500Hz
% figure;
% modalsd(FRF, freq, fs, 'MaxModes', 20, 'FreqRange', [0 500]);

% % 使用最小二乘有理函数法（lsrf）进行拟合
% figure;
% modalsd(FRF, freq, fs, 'MaxModes', 10, 'FreqRange', [100 350], 'FitMethod', 'lsrf');
