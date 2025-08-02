%% m010_plot_XYZ_Acc_Weizhen_timeDomain
clc;
clear;
close all;

%% 数据加载
filepath = '10.txt';
data = f021_readAcc_WeiZhen(filepath, 'XYZ');

time = data.Time;
X = data.X;

if isempty(time) || isempty(X)
    error('数据为空，请检查文件和读取函数！');
end

%% 绘图
figure('Units','centimeters','Position',[2 2 20 5]);
hold on;

plot(time, X*1e-3, 'HandleVisibility', 'off');

xlim([0, 25]);
ylim([0, 0.8]);

% 调用美化函数
f030_optimizeFig_Paper_02(gca, ...
    '时间(s)', ...
    '进给方向加速度(g)', ...
    '进给方向（X）加速度时域数据', ...
    {}, ...  % 无图例文本
    'northeast');

%% 保存图形为PNG文件（1500 DPI）
fileName = 'p031_Time_ap3ae4_Half_10_txt_Weizhen_02.png';
print(gcf, fileName, '-dpng', '-r1500');
