clc
clear
close all


% 数据输入

ap = [8, 9, 10];    % 切削深度
% endRa 和 sideRa 数据
Ra1 = [
        2.478, 1.558;   % ap=8, n=5000
        2.738, 2.176;  % ap=9, n=5000
        3.288, 1.865;  % ap=10, n=5000
];

Ra2 = [
        2.026, 0.5;   % ap=8, n=7000
        2.652, 0.518;  % ap=9, n=7000
        3.162, 0.547;  % ap=10, n=7000
];

endRa = [
        2.478, 2.026, 1.558, 0.5;   % ap=8, n=5000 & n=7000
        2.738, 2.652, 2.176, 0.518;  % ap=9, n=5000 & n=7000
        3.288, 3.162, 1.865, 0.547;  % ap=10, n=5000 & n=7000
];

sideRa = [
    1.558, 0.5;     % ap=8, n=5000 & n=7000
    2.176, 0.518;  % ap=9, n=5000 & n=7000
    1.865, 0.547;  % ap=10, n=5000 & n=7000
];


n = [5000, 7000];  % 转速

% 画图
figure('Units','centimeters','Position',[2 5 13 6]);

% 每个 ap 对应一个组，包含两个子bar：endRa 和 sideRa
barWidth = 0.7;  % 设置每个条形的宽度
colors = [
    0.6 0.6 1;  % 自定义颜色 1 (柔和深蓝)
    1 0.6 0.6;  % 自定义颜色 2 (柔和浅蓝)
    0.8 0.8 1;  % 自定义颜色 3 (柔和橙色)
    1 0.8 0.8;  % 自定义颜色 4 (柔和红色)
];

b1=barh(ap, Ra1, barWidth);
hold on;
b2=barh(ap, Ra2, barWidth);



b1(1).FaceColor = [1 0.8 0.8];

b1(2).FaceColor = [0.8 0.8 1];
b1(1).DisplayName='5000en';
b1(2).DisplayName='5000si';

b2(1).FaceColor = [1 0.4 0.4];
b2(2).FaceColor = [0.4 0.4 1];
b2(1).DisplayName='7000en';
b2(2).DisplayName='7000si';
% 
% % 绘制第一个 ap 的 endRa 和 sideRa
% for i = 1:length(ap)
%     % 当前切削深度对应的endRa和sideRa数据
%     endRaData = endRa(i, :);
%     sideRaData = sideRa(i, :);
% 
%     % 对于5000rpm，画深色的bar
%     barh(i - barWidth / 2, endRaData(1), barWidth, 'FaceColor', colors(1,:)); % endRa 5000rpm
%     hold on;
%     barh(i + barWidth / 2, sideRaData(1), barWidth, 'FaceColor', colors(2,:)); % sideRa 5000rpm
% 
%     % 对于7000rpm，画浅色的bar
%     barh(i - barWidth / 2, endRaData(2), barWidth, 'FaceColor', colors(3,:)); % endRa 7000rpm
%     barh(i + barWidth / 2, sideRaData(2), barWidth, 'FaceColor', colors(4,:)); % sideRa 7000rpm
% end

% % 设置标签和标题
% xlabel('Ra Value');
% ylabel('Cutting Depth (ap)');
% title('End Face and Side Ra Values at Different Speeds');
% 
% % 设置y轴为切削深度 ap 的标签
% yticks(1:length(ap));
% yticklabels(ap);
% 
% % 添加图例
% legend('endRa (5000rpm)', 'sideRa (5000rpm)', 'endRa (7000rpm)', 'sideRa (7000rpm)', 'Location', 'northeast');

% 美化图形
lgd=legend([b1(2),b2(2),b1(1),b2(1)]);
f034_exist_legend_05(lgd,'southeast')
f030_optimizeFig_Paper_05(gca, '{\it Ra} (μm)', '{\it a}_p (mm)');

f060_saveFigPNG_asFileName_05(mfilename('fullpath'));