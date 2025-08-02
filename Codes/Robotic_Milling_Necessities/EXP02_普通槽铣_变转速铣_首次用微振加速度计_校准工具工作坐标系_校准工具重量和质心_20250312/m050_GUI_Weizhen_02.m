%% 主函数：数据读取与调用
clc; clear; close all;

filepath = '10.txt';
samplingRate = 6600;    % 采样率 (Hz) 
windowSize = 1;       % 时间窗口长度(秒)
maxFreq = 500;         % FFT最大频率(Hz)

% 读取数据
data = f021_readAcc_WeiZhen(filepath, 'XYZ');
time = data.Time;
accX = data.X;

% 调用 GUI 创建函数
f050_createFFT_GUI(time, accX, samplingRate, windowSize, maxFreq);
