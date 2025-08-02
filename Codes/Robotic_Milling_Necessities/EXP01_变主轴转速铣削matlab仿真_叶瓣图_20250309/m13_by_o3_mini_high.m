%% 铣削过程时域仿真——基于延时微分方程的仿真
% 本脚本严格复现论文中的时域仿真过程，通过 MATLAB 的 dde23 求解器来求解
% 铣削过程中由于再生效应引起的刀具振动（ chatter ）的动力学响应。
% 采用状态空间形式描述系统（状态向量 y = [x; xdot; y; ydot]），并将切削力计算
% 与延时项结合。切削力的计算考虑了多刀齿同时切削、半浸入切削条件下的进给区间，
% 以及上一刀齿加工留下的工件表面影响（延时 T = 60/(N*Z)）。
% 注：部分参数取值可根据实际情况调整。

clc; clear; close all;

%% ===================== 参数设置 =====================
% 主轴转速（rpm）
params.N = 10000;    % 例如 3000 rpm

% 刀齿数
params.Z = 4;       

% 时间延迟 T = 60/(N*Z)（单位：秒）
params.T = 60/(params.N * params.Z);

% 切削参数
params.chip_load = 0.0001;   % 刀具进给量 (m)，例如 0.1 mm
params.a = 0.003;            % 轴向切深 (m)，例如 1 mm

% 切削系数（单位转换：600 MPa -> 600e6 Pa）
params.Kt = 600e6;   % 主切削系数
params.Kr = 0.07;    % 辅助切削系数

% 系统参数——X方向（构建 2DOF 模型的一部分）
params.k_x = 5.6e6;  % 刚度 (N/m)
f_nx = 600;          % 自然频率（Hz，论文中给定值）
omega_nx = 2*pi*f_nx; % 转换为弧度/秒
% 根据公式 m = k / (omega_n^2) 计算模态质量
params.m_x = params.k_x / (omega_nx^2);
zeta_x = 0.035;      % 阻尼比
params.c_x = 2 * zeta_x * omega_nx * params.m_x;

% 系统参数——Y方向（假设与 X 方向参数相近）
params.k_y = 5.6e6;  % 刚度 (N/m)
f_ny = 660;          % 自然频率（Hz）
omega_ny = 2*pi*f_ny; % 转换为弧度/秒
params.m_y = params.k_y / (omega_ny^2);
zeta_y = 0.035;      % 阻尼比
params.c_y = 2 * zeta_y * omega_ny * params.m_y;

% 半浸入切削条件下的刀具切削区间
% 论文中定义的单位阶跃函数 g(θ)：当 θ 在进入角与退出角之间时 g=1，否则为 0。
% 这里假设刀具进给区间为：进给起始角 entry = -pi/2，退出角 exit = pi/2。
% 为了便于与 [0,2pi] 区间匹配，将 entry 转换为 3pi/2。
params.entry = 3*pi/2; % 刀具进入切削区间
params.exit  = pi/2;   % 刀具退出切削区间

%% ===================== 时间范围与 dde23 选项 =====================
% 设置积分时间范围
tspan = [0, 0.1];  
% 注意：论文中积分时间可取 0~3 s，这里为了演示，取较短时间段，
% 可根据需要将 tspan 延长。

% 设置 dde23 求解器的选项
options = ddeset('RelTol',1e-6, 'AbsTol',1e-8);

%% ===================== 调用 dde23 求解延时微分方程 =====================
% 状态向量 y = [x; xdot; y; ydot]
% 调用 dde23，其中使用匿名函数传入参数结构体 params
sol = dde23(@(t,y,Z) ChtrDDEFunc(t,y,Z,params), params.T, @(t) ChtrHistory(t,params), tspan, options);

%% ===================== 绘图展示结果 =====================
% 绘制 X 方向位移响应
figure;
plot(sol.x, sol.y(1,:), 'b-', 'LineWidth', 1.5);
xlabel('时间 t (s)');
ylabel('X方向位移 (m)');
title('X方向位移时域响应');
grid on;

% 绘制 Y 方向位移响应
figure;
plot(sol.x, sol.y(3,:), 'r-', 'LineWidth', 1.5);
xlabel('时间 t (s)');
ylabel('Y方向位移 (m)');
title('Y方向位移时域响应');
grid on;

% 计算并绘制 X 方向的 FFT 谱（以分析频谱特性）
x_disp = sol.y(1,:);
N_fft = length(x_disp);
Fs = 1/mean(diff(sol.x)); % 采样频率
X_fft = fft(x_disp);
f = (0:N_fft-1) * (Fs/N_fft);
figure;
plot(f, abs(X_fft));
xlabel('频率 (Hz)');
ylabel('幅值');
title('X方向位移 FFT 谱');
grid on;

%% ===================== 局部函数 =====================
%% 延时微分方程函数
function dydt = ChtrDDEFunc(t, y, Z, params)
    % 输入参数：
    %   t      - 当前时间
    %   y      - 当前状态向量 [x; xdot; y; ydot]
    %   Z      - 延时状态 y(t-T)，其中 T = 60/(N*Z)
    %   params - 参数结构体
    %
    % 输出：
    %   dydt - 状态导数向量
    
    % 提取当前状态
    x = y(1);
    xdot = y(2);
    y_disp = y(3);
    ydot = y(4);
    
    % 提取延时状态（这里只用到位移信息）
    x_delay = Z(1);
    y_delay = Z(3);
    
    % 初始化总切削力
    Fx_total = 0;
    Fy_total = 0;
    
    % 遍历每个刀齿（j = 1 到 Z）
    for j = 1:params.Z
        % 每个刀齿的初始角度（均匀分布）
        theta0 = 2*pi*(j-1)/params.Z;
        % 当前刀齿的瞬时角度 = 主轴转角 + 初始角度
        theta = 2*pi*params.N*t/60 + theta0;
        theta = mod(theta, 2*pi);
        
        % 判断刀齿是否处于切削区间
        % 对于半浸入切削，假设切削区间为：[entry, 2pi] U [0, exit]
        if (theta >= params.entry) || (theta <= params.exit)
            engaged = 1;
        else
            engaged = 0;
        end
        
        if engaged
            % 计算光滑表面的芯片厚度： h_s = chip_load * sin(theta)
            h_s = params.chip_load * sin(theta);
            % 计算局部坐标下的位移： u(t) = - x*sin(theta) - y*cos(theta)
            u_t = - x*sin(theta) - y_disp*cos(theta);
            % 同理，延时状态下 u(t-T)
            u_delay = - x_delay*sin(theta) - y_delay*cos(theta);
            % 根据再生效应计算实际芯片厚度：
            % h_d = h_s + [x(t)-x(t-T)]*sin(theta) + [y(t)-y(t-T)]*cos(theta)
            h_d = h_s + (x - x_delay)*sin(theta) + (y_disp - y_delay)*cos(theta);
            
            % 计算局部切削力：
            % 切削力 Ft = Kt * h_d * a，径向分量 Fr = Kt * Kr * h_d * a
            Ft = params.Kt * h_d * params.a;
            Fr = params.Kt * params.Kr * h_d * params.a;
            
            % 将局部力转换到全局坐标系：
            % [Fx; Fy] = [ -sin(theta)   -cos(theta); -cos(theta)   sin(theta) ] * [Fr; Ft]
            Fx = - sin(theta)*Fr - cos(theta)*Ft;
            Fy = - cos(theta)*Fr + sin(theta)*Ft;
            
            % 累加所有刀齿产生的切削力
            Fx_total = Fx_total + Fx;
            Fy_total = Fy_total + Fy;
        end
    end
    
    % 根据系统动力学方程计算加速度
    % X方向： m_x*x'' + c_x*xdot + k_x*x = Fx_total  -->  x'' = (Fx_total - c_x*xdot - k_x*x) / m_x
    xddot = (Fx_total - params.c_x * xdot - params.k_x * x) / params.m_x;
    % Y方向： m_y*y'' + c_y*ydot + k_y*y = Fy_total  -->  y'' = (Fy_total - c_y*ydot - k_y*y) / m_y
    yddot = (Fy_total - params.c_y * ydot - params.k_y * y_disp) / params.m_y;
    
    % 组装状态导数向量
    dydt = [xdot; xddot; ydot; yddot];
end

%% 历史函数（初始条件）
function s = ChtrHistory(t, params)
    % 对于 t <= 0，假设系统处于静止状态（位移和速度均为零）
    s = [0; 0; 0; 0];
end
