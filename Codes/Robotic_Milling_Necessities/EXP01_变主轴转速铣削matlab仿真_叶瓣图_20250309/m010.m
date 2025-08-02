% mySLD_modified.m
% ------------------------------------------------------------------------------
%  基于原始 p_4_17_2.m 脚本, 将动力学参数修改为符合先前模型:
%    - k_x=k_y=5.6e6, f_nx=600 Hz, f_ny=660 Hz, zeta=0.035
%    - 切削力系数 Ks=600e6 (原为2000e6)
%  其余逻辑(如迭代求解、绘制刀条数的稳定叶线、标记点等)保持脚本原流程。
%  注意若需和前面完全一致, 还需对应更改刀齿数、进给角等细节。
% ------------------------------------------------------------------------------
clear
close all
clc

% 定义迭代次数、lobes数
iterations = 20;
num_lobes = 200;

% 初始的 'n' 值 (lobe计数起始)
n = 1;

% 刀具直径 (m)
d = 10e-3;

%% ========================== 新的动力学参数 ==========================
% 1) X 方向
kx    = 5.6e6;             % N/m
f_nx  = 600;               % Hz
wnx   = 2*pi*f_nx;         % rad/s
zetax = 0.035;
mx    = kx/(wnx^2);        % kg
% 注意: 这里采用 c = 2*zeta*sqrt(k*m) 形式, 等效于 c=2*zeta*m*wn 也行
cx    = 2*zetax*sqrt(mx*kx);  % N·s/m

% 2) Y 方向
ky    = 5.6e6;             
f_ny  = 660;               % Hz
wny   = 2*pi*f_ny;         
zetay = 0.035;
my    = ky/(wny^2);
cy    = 2*zetay*sqrt(my*ky);

% 3) 扫频范围
wnmax = max([wnx, wny]);
w     = (0:0.1:3*wnmax);   % rad/s

% 计算 FRF (X向)
rx = w/wnx;
FRF_real_x = (1 - rx.^2)./(kx*((1 - rx.^2).^2 + (2*zetax.*rx).^2));
FRF_imag_x = (-2*zetax.*rx)./(kx*((1 - rx.^2).^2 + (2*zetax.*rx).^2));

% 计算 FRF (Y向)
ry = w/wny;
FRF_real_y = (1 - ry.^2)./(ky*((1 - ry.^2).^2 + (2*zetay.*ry).^2));
FRF_imag_y = (-2*zetay.*ry)./(ky*((1 - ry.^2).^2 + (2*zetay.*ry).^2));

%% ============= 切削力模型参数 =============
% 之前脚本用 Ks=2000e6, 现改为 600e6 对应之前示例
Ks   = 600e6;         % N/m^2 (specific cutting force)
beta = 70*pi/180;     % 力角(默认保留70°),如需改为别的可自行修改
C    = 2e4;           % 过程阻尼系数 (N/m), 保留脚本原值

% 定义平均啮合齿数 Nt_star
Nt  = 3;           % 平均齿数
phis = 0;          % 进给起始角 (°)
phie = 90;         % 进给结束角 (°)
phiave = (phis + phie)/2;     % (°)
Nt_star = (phie - phis)*Nt/360;

% 刀具方向因子(和beta,phiave有关):
% mux= cos(β - (π/2 - φ)) * cos(π/2 - φ), 这里保留脚本原写法
mux = cos(beta - (pi/2 - phiave*pi/180)) * cos(pi/2 - phiave*pi/180);
muy = cos((pi - phiave*pi/180) - beta) * cos(pi - phiave*pi/180);

% 计算定向FRF
FRF_real_orient = mux.*FRF_real_x + muy.*FRF_real_y;
FRF_imag_orient = mux.*FRF_imag_x + muy.*FRF_imag_y;

% 找到 FRF_real_orient<0 的频率段
index = (FRF_real_orient < 0);
FRF_real_orient = FRF_real_orient(index);
FRF_imag_orient = FRF_imag_orient(index);
w = w(index);

% 初始 b_lim
blim = -1./(2*Ks*FRF_real_orient*Nt_star);  % m

% 初始 epsilon
epsilon = zeros(1,length(FRF_imag_orient));
for cnt = 1:length(FRF_imag_orient)
    if FRF_imag_orient(cnt) < 0
        epsilon(cnt) = 2*pi - 2*atan(abs(FRF_real_orient(cnt)/FRF_imag_orient(cnt)));
    else
        epsilon(cnt) = pi - 2*atan(abs(FRF_imag_orient(cnt)/FRF_real_orient(cnt)));
    end
end

% 主轴转速
omega = w/(Nt*2*pi)./(n + epsilon/(2*pi))*60;  % rpm

% 迭代更新
for loop = 1:iterations
    v = pi*d*omega/60;  % 刀具切线速度

    % 更新阻尼(过程阻尼叠加)
    cnewx = cx + C*blim./v*(cos(pi/2 - phiave*pi/180))^2;
    zetax = cnewx./(2*sqrt(kx*mx));
    cnewy = cy + C*blim./v*(cos(pi - phiave*pi/180))^2;
    zetay = cnewy./(2*sqrt(ky*my));

    % 根据更新后的阻尼计算新的 FRF
    rx = w/wnx;
    FRF_real_x = (1 - rx.^2)./(kx*((1 - rx.^2).^2 + (2*zetax.*rx).^2));
    FRF_imag_x = (-2*zetax.*rx)./(kx*((1 - rx.^2).^2 + (2*zetax.*rx).^2));
    ry = w/wny;
    FRF_real_y = (1 - ry.^2)./(ky*((1 - ry.^2).^2 + (2*zetay.*ry).^2));
    FRF_imag_y = (-2*zetay.*ry)./(ky*((1 - ry.^2).^2 + (2*zetay.*ry).^2));

    FRF_real_orient = mux.*FRF_real_x + muy.*FRF_real_y;
    FRF_imag_orient = mux.*FRF_imag_x + muy.*FRF_imag_y;

    index = (FRF_real_orient<0);
    FRF_real_orient = FRF_real_orient(index);
    FRF_imag_orient = FRF_imag_orient(index);
    w = w(index);

    blim = -1./(2*Ks*FRF_real_orient*Nt_star);
    epsilon = zeros(1, length(FRF_imag_orient));
    for cnt = 1:length(FRF_imag_orient)
        if FRF_imag_orient(cnt) < 0
            epsilon(cnt) = 2*pi - 2*atan(abs(FRF_real_orient(cnt)/FRF_imag_orient(cnt)));
        else
            epsilon(cnt) = pi - 2*atan(abs(FRF_imag_orient(cnt)/FRF_real_orient(cnt)));
        end
    end

    omega = w/(Nt*2*pi)./(n + epsilon/(2*pi))*60;  
end

% 绘图
figure(1)
plot(omega, blim*1e3, 'b-', 'LineWidth',1.5)
axis([0 15000 0 10])
set(gca,'FontSize',14)
xlabel('\Omega (rpm)','FontSize',16)
ylabel('b_{lim} (mm)','FontSize',16)
grid on
hold on

% 标记红点
points_x = [7500, 8500, 9000, 9000]; 
points_y = [3,    3,    3,    4   ];
plot(points_x, points_y, 'ro','MarkerFaceColor','r','MarkerSize',8)

% 下面继续迭代其它 lobes
for n = (n+1):num_lobes
    
    % 每次都重置到原始(线性)阻尼, 再在内部循环更新
    kx   = 5.6e6;
    wnx  = 2*pi*600;
    mx   = kx/(wnx^2);
    cx   = 2*0.035*sqrt(mx*kx);

    ky   = 5.6e6;
    wny  = 2*pi*660;
    my   = ky/(wny^2);
    cy   = 2*0.035*sqrt(my*ky);

    w = (0:0.1:2*wnmax);
    rx = w/wnx;
    FRF_real_x = (1 - rx.^2)./(kx*((1 - rx.^2).^2 + (2*0.035.*rx).^2));
    FRF_imag_x = (-2*0.035.*rx)./(kx*((1 - rx.^2).^2 + (2*0.035.*rx).^2));
    ry = w/wny;
    FRF_real_y = (1 - ry.^2)./(ky*((1 - ry.^2).^2 + (2*0.035.*ry).^2));
    FRF_imag_y = (-2*0.035.*ry)./(ky*((1 - ry.^2).^2 + (2*0.035.*ry).^2));

    FRF_real_orient = mux.*FRF_real_x + muy.*FRF_real_y;
    FRF_imag_orient = mux.*FRF_imag_x + muy.*FRF_imag_y;

    index = (FRF_real_orient<0);
    FRF_real_orient = FRF_real_orient(index);
    FRF_imag_orient = FRF_imag_orient(index);
    w = w(index);

    blim = -1./(2*Ks*FRF_real_orient*Nt_star);
    epsilon = zeros(1,length(FRF_imag_orient));
    for cnt = 1:length(FRF_imag_orient)
        if FRF_imag_orient(cnt)<0
            epsilon(cnt) = 2*pi - 2*atan(abs(FRF_real_orient(cnt)/FRF_imag_orient(cnt)));
        else
            epsilon(cnt) = pi - 2*atan(abs(FRF_imag_orient(cnt)/FRF_real_orient(cnt)));
        end
    end

    omega = w/(Nt*2*pi)./(n + epsilon/(2*pi))*60;

    % 二次迭代(带过程阻尼)
    for loop = 1:iterations
        v = pi*d*omega/60;

        cnewx = cx + C*blim./v*(cos(pi/2 - phiave*pi/180))^2;
        zetax = cnewx./(2*sqrt(kx*mx));
        cnewy = cy + C*blim./v*(cos(pi - phiave*pi/180))^2;
        zetay = cnewy./(2*sqrt(ky*my));

        rx = w/wnx;
        FRF_real_x = (1 - rx.^2)./(kx*((1 - rx.^2).^2 + (2*zetax.*rx).^2));
        FRF_imag_x = (-2*zetax.*rx)./(kx*((1 - rx.^2).^2 + (2*zetax.*rx).^2));
        ry = w/wny;
        FRF_real_y = (1 - ry.^2)./(ky*((1 - ry.^2).^2 + (2*zetay.*ry).^2));
        FRF_imag_y = (-2*zetay.*ry)./(ky*((1 - ry.^2).^2 + (2*zetay.*ry).^2));

        FRF_real_orient = mux.*FRF_real_x + muy.*FRF_real_y;
        FRF_imag_orient = mux.*FRF_imag_x + muy.*FRF_imag_y;

        index = (FRF_real_orient<0);
        FRF_real_orient = FRF_real_orient(index);
        FRF_imag_orient = FRF_imag_orient(index);
        w = w(index);

        blim = -1./(2*Ks*FRF_real_orient*Nt_star);
        epsilon = zeros(1,length(FRF_imag_orient));
        for cnt = 1:length(FRF_imag_orient)
            if FRF_imag_orient(cnt) < 0
                epsilon(cnt) = 2*pi - 2*atan(abs(FRF_real_orient(cnt)/FRF_imag_orient(cnt)));
            else
                epsilon(cnt) = pi - 2*atan(abs(FRF_imag_orient(cnt)/FRF_real_orient(cnt)));
            end
        end
        omega = w/(Nt*2*pi)./(n + epsilon/(2*pi))*60;
    end

    % 追加绘制
    plot(omega, blim*1e3, 'b-', 'LineWidth',1.0)
end

legend('b_{lim} curves','Marked Points','Location','best')
title('Limit Cutting Depth (b_{lim}) vs Spindle Speed (\Omega)','FontSize',16)
