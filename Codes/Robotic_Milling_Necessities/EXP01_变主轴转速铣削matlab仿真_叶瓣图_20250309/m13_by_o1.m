%% chatter_simulation.m
% 通过时域数值仿真来复现论文中关于高转速铣削过程的颤振分析。
% 使用 dde23 求解时滞微分方程，方程形式以及力模型严格参考论文内容。
%
% 运行环境：
%  - MATLAB (R2016及以上版本均可)
% 注意：
%  - 在同一个脚本中，所有function定义必须放在脚本末尾。
%
% 作者：某某（示例代码示意）
% -----------------------------------------------

clear; clc; close all;

%% ============= 参数设置（与论文示例一致或相近） =============
% 1. 动力学参数（X/Y 两方向的模态假设）
f_nx = 600;              % X方向主振频率(Hz) —— 文中表格给出的数值
f_ny = 660;              % Y方向主振频率(Hz)
zeta_x = 0.035;          % X方向阻尼比
zeta_y = 0.035;          % Y方向阻尼比
k_x = 5.6e6;             % X方向刚度 (N/m)
k_y = 5.6e6;             % Y方向刚度 (N/m)

% 将频率(Hz)转换为角频率(rad/s)
omega_nx = 2*pi*f_nx;
omega_ny = 2*pi*f_ny;

% 由  k = m * omega_n^2  --> m = k / (omega_n^2)
m_x = k_x / (omega_nx^2);
m_y = k_y / (omega_ny^2);

% 阻尼 (c = 2 * zeta * omega_n * m)
c_x = 2 * zeta_x * omega_nx * m_x;
c_y = 2 * zeta_y * omega_ny * m_y;

% 2. 铣削力相关参数
K_t = 600e6;             % 切削力系数 (N/m^2), 论文中提到 "600 MPa"
k_r = 0.07;              % 切向与径向力系数比
Z   = 4;                 % 刀具齿数
feed_per_tooth = 0.05e-3;% 每齿进给，0.05 mm/齿(单位 m/齿)
a_depth = 3e-3;          % 轴向切深 a = 1 mm (单位 m)

% 3. 铣削几何及切削范围
%   这里示例：半径方向半切 (Half Immersion)
%   假设刀齿在θ=0~π之间与工件啮合
theta_entry = 0;
theta_exit  = pi;

% 4. 主轴转速及时滞
N_rpm = 10000;                      % 主轴转速 (rpm)
T_tooth = 60/(N_rpm * Z);          % 单个齿通过的时间 (s)，即时滞

% 5. 时间积分区间
t_start = 0;
t_end   = 0.2;                    % 可以根据需求调整模拟时长

% 将以上参数打包到一个结构体中，方便在函数中调用
param.m_x = m_x;       param.m_y = m_y;
param.c_x = c_x;       param.c_y = c_y;
param.k_x = k_x;       param.k_y = k_y;
param.omega_nx = omega_nx;
param.omega_ny = omega_ny;
param.zeta_x = zeta_x; param.zeta_y = zeta_y;
param.K_t   = K_t;     param.k_r   = k_r;
param.Z     = Z;
param.feed  = feed_per_tooth;
param.a     = a_depth;
param.N     = N_rpm;
param.theta_entry = theta_entry;
param.theta_exit  = theta_exit;

% 时滞(可为向量，如多齿刀具有同样时滞，这里只传递一个)
lags = T_tooth;

% ============= 定义 dde23 选项 =============
% 可以设定相对/绝对误差等
options = ddeset('RelTol',1e-6,'AbsTol',1e-8);

% ============= 调用 dde23 求解 =============
sol = dde23(@(t,y,Zlag)chatterDDE(t,y,Zlag,param), ...
            lags, ...
            @chatterHistory, ...
            [t_start, t_end], ...
            options);

%% ============= 后处理及结果绘图 =============
% 状态量 y 的顺序约定：
%   y(1) = x(t), y(2) = x_dot(t),
%   y(3) = y(t), y(4) = y_dot(t).

% 时间序列
t_span = sol.x;
% 解的序列
x_val = sol.y(1,:);
xd_val = sol.y(2,:);
y_val = sol.y(3,:);
yd_val = sol.y(4,:);

% 1) 绘制位移随时间的演变
figure;
plot(t_span, x_val, 'LineWidth',1.2); hold on;
plot(t_span, y_val, 'LineWidth',1.2); 
xlabel('时间 t (s)');
ylabel('位移 (m)');
title('X/Y 方向位移时域响应');
legend('x(t)','y(t)','Location','best');
grid on;

% 2) 看看 X方向位移的频谱 (简易 FFT)
%   注意：本处仅做示意，若要更精细的频谱分析可自行加窗或零填充
dt = mean(diff(t_span));
Fs = 1/dt;  % 采样频率
Xfft = abs(fft(x_val - mean(x_val))); 
Nfft = length(Xfft);
freqAxis = (0:Nfft-1)*(Fs/Nfft);

figure;
plot(freqAxis, Xfft, 'LineWidth',1.2);
xlim([0, 5000]);  % 根据情况截取到合适频率上限
xlabel('频率 (Hz)');
ylabel('幅值');
title('X方向位移信号的 FFT 频谱');
grid on;

disp('=== 铣削时域仿真完成！请查看绘图结果。 ===');



%% ========== 以下为本地函数定义，必须放在脚本最后面 ==========

% ---------------------------------------------------
function dydt = chatterDDE(t, y, Zlag, param)
% chatterDDE:
%  输入:
%   - t: 当前时间
%   - y: 当前状态 [ x, x_dot, y, y_dot ]
%   - Zlag: 时滞状态 [ x(t-T), x_dot(t-T), y(t-T), y_dot(t-T) ]
%   - param: 参数结构体
%
%  输出:
%   - dydt: 微分方程右端项 [ x_dot, x_ddot, y_dot, y_ddot ]

    % 从状态变量中解析
    x     = y(1);
    x_dot = y(2);
    yPos  = y(3);
    y_dot = y(4);

    % 时滞量
    x_delayed = Zlag(1);
    y_delayed = Zlag(3);

    % 读取结构体内参数
    m_x = param.m_x;  c_x = param.c_x;  k_x = param.k_x;
    m_y = param.m_y;  c_y = param.c_y;  k_y = param.k_y;

    K_t = param.K_t;  k_r = param.k_r; 
    feed= param.feed; a   = param.a;
    Z   = param.Z;    N   = param.N;

    theta_entry = param.theta_entry;
    theta_exit  = param.theta_exit;

    % 计算总切削力 (Fx, Fy)
    Fx_total = 0.0;
    Fy_total = 0.0;

    % 对每一齿进行叠加
    % 参考论文中的做法：theta(t) = 2*pi*N/60 * t + j*(2*pi/Z)
    for j = 0:Z-1
        % 计算第 j 齿瞬时角度(简单假设相邻齿等分分布)
        theta_j = 2*pi*(N/60)*t + j*(2*pi/Z);

        % 取 0~2*pi 模
        theta_mod = mod(theta_j, 2*pi);

        % 判断该齿是否在啮合区间 [theta_entry, theta_exit]
        if (theta_mod >= theta_entry) && (theta_mod <= theta_exit)
            % 1) 基本厚度 h_s
            h_s = feed * sin(theta_mod);  % sin(θ) => 论文中 Eq.(5)

            % 2) 延迟引起的厚度增量
            %    根据论文：u(t) = -x(t)*sin(θ) - y(t)*cos(θ)
            u_now   = - x    * sin(theta_mod) - yPos   * cos(theta_mod);
            u_delay = - x_delayed*sin(theta_mod) - y_delayed*cos(theta_mod);

            h_d = h_s + (u_now - u_delay);  % 论文 Eq.(10) 的简化实现
            if h_d < 0
                % 若出现负厚度则视为没有切屑
                h_d = 0;
            end

            % 3) 计算局部切向力 Ft 与径向力 Fr
            Ft = K_t * h_d * a;       % Ft = Kt * (chip_thickness) * (axial_depth)
            Fr = Ft * k_r;            % Fr = k_r * Ft

            % 4) 将 (Ft, Fr) 转换到全局坐标(Fx, Fy)
            %    参考论文 Eq.(2):
            %    Fx = -sin(θ)*Fr  - cos(θ)*Ft
            %    Fy = -cos(θ)*Fr  + sin(θ)*Ft
            Fx_j = - sin(theta_mod)*Fr - cos(theta_mod)*Ft;
            Fy_j = - cos(theta_mod)*Fr + sin(theta_mod)*Ft;

            % 5) 累加到总力
            Fx_total = Fx_total + Fx_j;
            Fy_total = Fy_total + Fy_j;
        end
    end

    % 现在可以写出微分方程:
    %
    %   m_x * x_ddot + c_x * x_dot + k_x * x = Fx_total
    %   => x_ddot = (Fx_total - c_x*x_dot - k_x*x)/m_x
    %
    %   m_y * y_ddot + c_y * y_dot + k_y * y = Fy_total
    %   => y_ddot = (Fy_total - c_y*y_dot - k_y*y)/m_y

    x_ddot = (Fx_total - c_x*x_dot - k_x*x) / m_x;
    y_ddot = (Fy_total - c_y*y_dot - k_y*yPos)/ m_y;

    % 把结果拼成 dydt
    dydt = [ x_dot; x_ddot; y_dot; y_ddot ];
end

% ---------------------------------------------------
function v = chatterHistory(t, param)
% chatterHistory:
%   定义时滞微分方程的初始历史
%   论文一般假设起始时刻之前位移和速度都为0
%
%   输入:
%    - t: 历史区间 [t_start - T, t_start], 对dde23自动调用
%    - param: 这里也可用来传参，但本例子不用
%   输出:
%    - v: [ x, x_dot, y, y_dot ] 在该 t 时刻的值

    v = [0; 0; 0; 0];  % 假设历史位移与速度都为0
end
