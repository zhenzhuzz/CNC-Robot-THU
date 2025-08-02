clc; clear; close all;

%% 参数设定
m = 0.1;          % 橡皮质量 (kg)
k = 100;          % 弹簧刚度 (N/m)
F0 = 1.0;         % 恒定驱动力 (N)

Fs = 1.2;         % 最大静摩擦力 (N)
Fd_min = 0.4;     % 最小动摩擦力 (N)
v_s = 0.005;      % 速度阈值 (m/s)，滑动状态下低速则重新粘着
v_driver = 0.01;  % 驱动器前进速度 (m/s)
dt = 0.0005;      % 时间步长 (s)
t_end = 100;      % 仿真总时间 (s)
margin = 0.03;    % 动态x轴窗口边界

%% 初始条件
x = 0;            % 橡皮块初始位移
v = 0;            % 初始速度
a = 0;            % 初始加速度
state = "stick";  % 初始状态为“粘着”

%% 结果储存
time = 0:dt:t_end;
N = length(time);
x_save = zeros(size(time));
v_save = zeros(size(time));
state_save = strings(size(time));

%% 动摩擦力特性（负斜率非线性模型）
% 当 |v| 增大时，摩擦力从 Fs 逐渐降至 Fd_min
Fd_fun = @(v) Fs - (Fs - Fd_min)*tanh(100*abs(v));

%% 数值积分求解运动方程
% 模型：
%   驱动器位移: x_driver = v_driver * t
%   弹簧力: F_spring = k*(x_driver - x)
% 在 stick 状态下，橡皮块保持静止（v=0），但弹簧被拉伸，
% 此时静摩擦力自动调整以平衡弹簧力（即 friction_force = -F_spring)。
% 当 |F_spring| 超过静摩擦极限 Fs 时，系统转为 slip 状态，
% 滑动状态下利用牛顿第二定律更新运动，摩擦力采用动摩擦模型。
for i = 1:N
    t = time(i);
    % 驱动器位移
    x_driver = v_driver * t;
    % 计算弹簧力（正表示拉伸，负表示压缩）
    F_spring = k*(x_driver - x);
    
    if state == "stick"
        % 在粘着状态下，橡皮块不动
        v = 0; a = 0;
        % 静摩擦力自动平衡弹簧力，方向相反
        friction_force = -F_spring;
        % 当弹簧力超出静摩擦极限时，触发滑动
        if abs(F_spring) > Fs
            state = "slip";
        end
    else  % slip 状态
        % 计算动摩擦力，采用非线性模型
        Fd = Fd_fun(v);
        % 动摩擦力方向与运动方向相反
        friction_force = - Fd * sign(v);
        % 总作用力 = 弹簧力 + 摩擦力（注意两者方向相反）
        F_net = F_spring + friction_force;
        a = F_net / m;
        v = v + a * dt;
        x = x + v * dt;
        
        % 当滑动速度低且弹簧力不足以超过静摩擦时，恢复 stick 状态
        if abs(v) < v_s && abs(F_spring) < Fs
            state = "stick";
            v = 0; a = 0;
            % 静摩擦力此时自动平衡弹簧力
            friction_force = -F_spring;
        end
    end
    
    x_save(i) = x;
    v_save(i) = v;
    state_save(i) = state;
end

%% 动画展示

% 创建图形窗口
figure('Position',[200,200,900,400]);
hold on; grid on; axis equal
xlabel('位移 (m)'); ylabel('高度 (m)');
title('橡皮 Stick-Slip 周期振动演示');

% 初始动态x轴窗口设置：以驱动器位置为中心
x_driver0 = v_driver * time(1);
xlim([x_driver0 - margin, x_driver0 + margin]);
ylim([-0.02, 0.04]);

% 绘制桌面（地板）：用一条横线表示，动画中随驱动器移动更新
h_floor = plot([x_driver0 - margin, x_driver0 + margin], [-0.005, -0.005], 'k', 'LineWidth', 2);

% 绘制驱动器（蓝色实心圆点）：表示能量输入端
driver_plot = plot(0,0,'bo','MarkerSize',8,'MarkerFaceColor','b');

% 绘制橡皮块（长方形）
rubber_width = 0.005; rubber_height = 0.003;
rubber = rectangle('Position',[x_save(1), -0.005, rubber_width, rubber_height],...
    'FaceColor',[0.85 0.33 0.1]);

% 绘制弹簧（锯齿线条）：初始从驱动器到橡皮块中心
[spring_x, spring_y] = getSpringPoints(0, x_save(1)+rubber_width/2, 0.005, 4, 0.001, 50);
spring_line = plot(spring_x, spring_y, 'm', 'LineWidth', 2);

% 固定显示框：利用 annotation 固定在图形左上角显示力值
spring_text = annotation('textbox',[0.05, 0.85, 0.15, 0.05],'String','弹簧力: 0 N',...
    'EdgeColor','none','FontSize',10);
friction_text = annotation('textbox',[0.05, 0.80, 0.15, 0.05],'String','摩擦力: 0 N',...
    'EdgeColor','none','FontSize',10);
drive_text = annotation('textbox',[0.05, 0.75, 0.15, 0.05],'String','驱动力: 1.00 N',...
    'EdgeColor','none','FontSize',10);

% 绘制动态力矢量箭头
% 弹簧力箭头（绿色）：起点设置在橡皮块中心上方
spring_arrow = quiver(0,0,0.01,0,'LineWidth',2,'Color','g','MaxHeadSize',2);
% 摩擦力箭头（红色）：起点设置在橡皮块中心下方
friction_arrow = quiver(0,0,0.01,0,'LineWidth',2,'Color','r','MaxHeadSize',2);
% 驱动力箭头（蓝色）：为了反映恒定驱动力，设定为固定长度
fixed_drive_length = 0.01;  % 固定蓝色箭头长度
drive_arrow = quiver(0,0,fixed_drive_length,0,'LineWidth',2,'Color','b','MaxHeadSize',2);

% 动画循环
for i = 1:10:N
    t = time(i);
    % 当前驱动器位置
    x_driver = v_driver * t;
    
    % 更新x轴窗口和地板线条：使画面始终以驱动器为中心
    xlim([x_driver - margin, x_driver + margin]);
    set(h_floor, 'XData', [x_driver - margin, x_driver + margin]);
    
    % 更新驱动器位置（蓝色实心圆点）
    driver_plot.XData = x_driver;
    driver_plot.YData = 0.005;
    
    % 更新橡皮块位置
    rubber.Position = [x_save(i), -0.005, rubber_width, rubber_height];
    
    % 更新弹簧图像：从驱动器位置到橡皮块中心
    spring_start = x_driver;
    spring_end = x_save(i) + rubber_width/2;
    % 根据状态调整弹簧图像的振幅：stick 状态时振幅小（表示极致压缩或拉伸），
    % slip 状态时振幅大（能量释放过程）
    if state_save(i) == "stick"
        spring_amplitude = 0.001;
    else
        spring_amplitude = 0.003;
    end
    [spring_x, spring_y] = getSpringPoints(spring_start, spring_end, 0.005, 4, spring_amplitude, 50);
    set(spring_line, 'XData', spring_x, 'YData', spring_y);
    
    % 计算弹簧力
    F_spring = k*(x_driver - x_save(i));
    
    % 在 stick 状态下，静摩擦力平衡弹簧力，方向相反
    % 在 slip 状态下，动摩擦力 = - Fd_fun(v)*sign(v)
    if state_save(i) == "stick"
        friction_force = -F_spring;
    else
        Fd_current = Fd_fun(v_save(i));
        friction_force = - Fd_current * sign(v_save(i));
    end
    
    % 更新弹簧力箭头（绿色）：起点在橡皮块中心上方
    spring_scale = 0.01;  % 缩放因子
    spring_arrow.XData = x_save(i) + rubber_width/2;
    spring_arrow.YData = 0;
    spring_arrow.UData = spring_scale * F_spring; % 正值表示箭头向右，负则向左
    spring_arrow.VData = 0;
    spring_text.String = sprintf('弹簧力: %.2f N', F_spring);
    
    % 更新摩擦力箭头（红色）
    friction_scale = 0.01;  % 根据需要调整缩放因子
    friction_arrow.XData = x_save(i) + rubber_width/2;
    friction_arrow.YData = -rubber_height - 0.007;  % 稍微下移
    friction_arrow.UData = friction_scale * friction_force;
    friction_arrow.VData = 0;
    friction_text.String = sprintf('摩擦力: %.2f N', friction_force);
    
    % 更新驱动力箭头（蓝色）：固定长度，不随位置变化
    drive_arrow.XData = x_driver;
    drive_arrow.YData = 0.005;
    drive_arrow.UData = fixed_drive_length;  % 固定显示
    drive_arrow.VData = 0;
    drive_text.String = sprintf('驱动力: %.2f N', F0);
    
    drawnow;
    pause(0.01);
end

figure;
plot(time, x_save, 'LineWidth', 1.5);
grid on;
xlabel('时间 (s)');
ylabel('橡皮块位移 (m)');
title('橡皮块位移随时间变化曲线');


%% --- 局部函数: 生成弹簧的点坐标 ---
function [xs, ys] = getSpringPoints(x_start, x_end, y0, N_coils, amplitude, numPoints)
    % x_start: 起点横坐标（驱动器位置）
    % x_end: 终点横坐标（橡皮块中心位置）
    % y0: 弹簧基线高度
    % N_coils: 线圈数
    % amplitude: 线圈振幅（上下摆动幅度）
    % numPoints: 用于生成平滑曲线的点数
    xs = linspace(x_start, x_end, numPoints);
    t = linspace(0, 1, numPoints);
    ys = y0 + amplitude * sin(2*pi*N_coils*t);
end
