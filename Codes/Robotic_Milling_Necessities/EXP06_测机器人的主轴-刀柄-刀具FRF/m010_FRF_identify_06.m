%% 使用modalfit精准辨识FRF模态参数

clear; close all; clc;

%% 加载数据
filename = 'ap8_FRF3y4y.txt';
[freq, FRF] = f100_read_frf_txt(filename);

fs = max(freq)*2;  % 假设采样频率为最大频率的两倍 (奈奎斯特准则)

%% 绘制FRF幅值
figure;
plot(freq, abs(FRF));
xlabel('Frequency (Hz)'); ylabel('Magnitude (g/N)');
title('FRF Magnitude');
grid on;

%% 使用modalfit识别模态
nmodes = 2; % 预期辨识的模态个数，可以自行调整
[fn,dr,ms] = modalfit(FRF, freq, fs, nmodes, 'FitMethod', 'lsce');

disp('识别的模态频率(Hz):');
disp(fn);

disp('阻尼比:');
disp(dr);

%% 计算模态刚度与模态质量（单位转换后）
FRF_SI = FRF * 9.81; % g/N → m/s²/N
modal_mass = zeros(nmodes,1);
modal_stiffness = zeros(nmodes,1);

for i = 1:nmodes
    wn = 2*pi*fn(i);
    [~,idx] = min(abs(freq-fn(i)));
    H_peak = abs(FRF_SI(idx));
    
    modal_mass(i) = 1 / (H_peak * wn^2);
    modal_stiffness(i) = modal_mass(i) * wn^2;
end

%% 显示最终结果
results = table((1:nmodes)', fn, dr, modal_mass, modal_stiffness,...
    'VariableNames', {'Mode', 'Freq_Hz', 'Damping_Ratio', 'Modal_Mass_kg', 'Modal_Stiffness_N_per_m'});

disp(results);
