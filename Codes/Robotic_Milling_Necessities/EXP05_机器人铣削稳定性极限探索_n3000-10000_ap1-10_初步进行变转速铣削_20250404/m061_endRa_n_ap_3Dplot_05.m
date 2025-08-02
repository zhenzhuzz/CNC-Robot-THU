clc;
clear;
close all;

% Step 1: 使用 f040_load_table_05 函数加载数据表
data = f040_load_table_05('EXP05'); % 确保传入正确的表名

% 提取相关数据
n = unique(data.n);  % 获取主轴转速 (n)，例如：3000, 4000, ...
ap = unique(data.ap);  % 获取轴向切削深度 (ap)

% 重塑数据，使其适应 bar3
endRa = reshape(data.endRa, [length(ap), length(n)]);

endRa = flipud(endRa);  % 将行倒过来


sideRa = reshape(data.sideRa, [length(ap), length(n)]);
sideRa = flipud(sideRa);  % 将行倒过来
sideRa = sideRa(1:8,:);

% 创建端面 Ra 的柱状图
figure('Units','centimeters','Position',[1 5 9 9]);
ax1 = axes;
b1 = bar3(ax1, endRa);
view(-35,45);
% 为每个柱子设置颜色渐变
for k = 1:length(b1)
    zdata = b1(k).ZData;                 % 获取柱状图的Z数据（高度）
    b1(k).CData = zdata;                 % 将CData设置为ZData
    b1(k).FaceColor = 'interp';          % 启用颜色渐变
end

% 添加颜色条并设置标签
cbar1 = colorbar; % 获取colorbar对象
f034_colorbar_05(cbar1, '{\it Ra} (μm)', 10.5, 'Times New Roman', 1);
clim([0 3.5]);
% 设置 X 轴与 Y 轴刻度
ax1.XTick = 1:length(n);        % X 轴刻度：n的长度
ax1.XTickLabel = n;             % X 轴标签为 n（主轴转速）
ax1.YTick = 1:length(ap);       % Y 轴刻度：ap的长度
ax1.YTickLabel = flipud(ap);    % Y 轴标签为倒序后的 ap（轴向切削深度）

% 优化图形（调用优化函数，自行调整标签、标题等）
f031_3DFigOptimized_05(ax1, '{\it n} (rpm)', '{\it a}_p (mm)', '{\it Ra} (μm)','',[0.01,0.01],'tight','tight');
f060_saveFigPNG_asFileName_05(mfilename('fullpath'),true);

% 创建侧面 Ra 的柱状图
figure('Units','centimeters','Position',[20 5 9 9]);
ax2 = axes;
b2 = bar3(ax2, sideRa);
view(-35,45);
% 为每个柱子设置颜色渐变
for k = 1:length(b2)
    zdata = b2(k).ZData;                 % 获取柱状图的Z数据（高度）
    b2(k).CData = zdata;                 % 将CData设置为ZData
    b2(k).FaceColor = 'interp';          % 启用颜色渐变
end
% 添加颜色条并设置标签

cbar2 = colorbar; % 获取colorbar对象
f034_colorbar_05(cbar2, '{\it Ra} (μm)', 10.5, 'Times New Roman', 1);
clim([0 3.5]);

% 设置 X 轴与 Y 轴刻度
ax2.XTick = 1:length(n);        % X 轴刻度：n的长度
ax2.XTickLabel = n;             % X 轴标签为 n（主轴转速）
ax2.YTick = 1:length(ap);       % Y 轴刻度：ap的长度
ax2.YTickLabel = flipud(ap);    % Y 轴标签为倒序后的 ap（轴向切削深度）

% 优化图形（调用优化函数，自行调整标签、标题等）
f031_3DFigOptimized_05(ax2, '{\it n} (rpm)', '{\it a}_p (mm)', '{\it Ra} (μm)','',[0.01,0.01],'tight','tight');
f060_saveFigPNG_asFileName_05(mfilename('fullpath'),false);
