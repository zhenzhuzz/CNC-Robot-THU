%% Plotting Script for dataLog
% 本脚本用于绘制 dataLog 数据，其中 dataLog 为 16640×3 double，
% 三列分别对应 'time', 'accX', 'spinSpeed'。
% 脚本生成一个 figure，包含两个 subplot：
%   - 上面：time 与 accX 的关系图
%   - 下面：time 与 spinSpeed 的关系图
% 同时调用 f002_optimizeFig_Paper_04 对图进行美化

% close all; clc;

% 如果 workspace 中不存在 dataLog，则生成示例数据
% if ~exist('dataLog', 'var')
%     % 生成示例数据
%     time = linspace(0, 10, 16640)';           % 时间，从0到10秒
%     accX = sin(2*pi*0.5*time);                 % 示例加速度数据：正弦波
%     spinSpeed = cos(2*pi*0.5*time);            % 示例旋转速度数据：余弦波
%     dataLog = [time, accX, spinSpeed];
% end

% 创建 figure
figure;

% ---------------------- 第一个 subplot ----------------------
ax1 = subplot(2,1,1);  
plot(timestamps, accX, 'b-', 'LineWidth', 1);
% 类比：就像先搭建房屋框架，再进行装修，美化函数在这里充当装修工
f002_optimizeFig_Paper_04(ax1, '时间(s)', '加速度(g)', 'Time vs. Acceleration');
% xlim([3,5]);
% ---------------------- 第二个 subplot ----------------------
ax2 = subplot(2,1,2);  
plot(timestamps, spindleSpeed, 'r-', 'LineWidth', 1);
% 类比：就像为第二间房间安装精美灯具，这里同样调用美化函数
f002_optimizeFig_Paper_04(ax2, '时间(s)', '旋转速度', 'Time vs. Spin Speed');


