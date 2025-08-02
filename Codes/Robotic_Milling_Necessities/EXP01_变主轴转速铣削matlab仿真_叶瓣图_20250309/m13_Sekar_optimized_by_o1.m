%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chatter_simulation_pass_by_pass_optimized_v2.m
%
% 在原先的脚本基础上:
%   1) 去掉了 function chatter_simulation_pass_by_pass_optimized() 头部声明,
%      使其成为一个可直接运行的脚本。
%   2) 更注重时域数学物理模型的细节:
%      - 确定了再生厚度公式 h_d = h_s + (u_tau - u_now), 并对 h_d < 0 的情况置为 0。
%      - 将半浸入的角度设为 [0, π], 并清晰区分刀齿角度与 mod 2π 的处理。
%      - 保留 pass-by-pass(齿周期) 分段集成, 保留 Poincaré 映射等分析方法。
%
% 运行方式:
%   1) 将本脚本保存为 .m 文件(如 chatter_simulation_pass_by_pass_optimized_v2.m)
%   2) 在 MATLAB 命令行输入该脚本文件名回车, 即可执行。
%
% 数学物理模型上的优化要点:
%   - 采用更“严格”的负厚度置零, 避免非物理的负切削力.
%   - 半浸入角度统一设为 [0, π], 并且在循环中采用 theta = (2πN/60)*t + j*(2π/Z).
%   - pass-by-pass 的思路接近实际刀具逐齿“离散”过程, 方便观察每个周期末的状态.
%   - 保留 FFT, 速度, 位移, Poincaré 等图, 以便多角度观察稳定性/颤振.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;  clearvars;  clc;

%% =========================== 全局参数声明 ===========================
global PARAMS

%% ============ [1] 定义主要铣削动力学及切削参数 =============
% 1.1 系统动力学参数 (X 方向)
f_nx          = 600;    % X方向主振频率 (Hz)
PARAMS.zeta_x = 0.035;  % X方向阻尼比
PARAMS.k_x    = 5.6e6;  % 刚度 (N/m)
omega_nx      = 2*pi*f_nx;
PARAMS.m_x    = PARAMS.k_x / (omega_nx^2);
PARAMS.c_x    = 2*PARAMS.zeta_x*omega_nx*PARAMS.m_x;

% 1.2 系统动力学参数 (Y 方向)
f_ny          = 660; 
PARAMS.zeta_y = 0.035;
PARAMS.k_y    = 5.6e6;
omega_ny      = 2*pi*f_ny;
PARAMS.m_y    = PARAMS.k_y / (omega_ny^2);
PARAMS.c_y    = 2*PARAMS.zeta_y*omega_ny*PARAMS.m_y;

% 1.3 铣削刀具与切削条件
PARAMS.Z   = 4;       % 刀齿数
PARAMS.N   = 10000;    % 主轴转速 (rpm)
PARAMS.Kt  = 600e6;   % 切向切削力系数 (Pa)
PARAMS.Kr  = 0.07;    % 径向与切向之比
PARAMS.a   = 3e-3;    % 轴向切深 (m)
PARAMS.feed= 1e-4;    % 每齿进给量 (m)

% 刀齿周期(时滞)
T = 60/(PARAMS.N * PARAMS.Z);
PARAMS.toothPeriod = T;

% 半浸入角度区间 [0, π]
PARAMS.phi_e = 0;  % 刀具进入角
PARAMS.phi_x = pi; % 刀具退出角

% 1.4 仿真结束时间
tmax = 0.2;  % 可根据需要加大

%% =========== [2] 定义初始历史, pass 估计, dde23 选项 ============
% 初始历史:  t<=0 时系统置于静止(位移与速度均为0)
histFun = @(t) [0;0;0;0];

% pass-by-pass 总共需要做多少段
passCountEst = ceil(tmax / T);

% dde23 选项
opts = ddeset('RelTol',1e-6, 'AbsTol',1e-8);

%% =========== [3] pass-by-pass 循环集成并收集解 =============
t0 = 0;
piecewiseSols = {};  % 用来储存每段求解的结果

hWB = waitbar(0, 'Simulating pass-by-pass...');

for passIndex = 1:passCountEst
    t1 = t0 + T;
    if t1 > tmax
        t1 = tmax;
    end

    fracDone = min(passIndex/passCountEst,1);
    waitbar(fracDone, hWB, ...
        sprintf('Pass %d / %d: [%.4f, %.4f]', passIndex, passCountEst, t0, t1));
    drawnow;

    % 调用 dde23, 每段只积分一个齿周期长度(或到达 tmax 为止)
    solPiece = dde23(@chatterDDE_global, T, histFun, [t0, t1], opts);
    piecewiseSols{end+1} = solPiece; %#ok<AGROW>

    fprintf('Pass %d done: t=%.4f\n', passIndex, solPiece.x(end));

    % 更新起始时间
    t0 = solPiece.x(end);
    if t0 >= tmax
        break; 
    end

    % 生成下一段所需的“局部历史”: 插值本段解
    tStart = solPiece.x(1);
    tEnd   = solPiece.x(end);
    tHist  = linspace(tStart, tEnd, 200);
    yHist  = deval(solPiece, tHist);
    % 用匿名函数把插值结果作为下一段的 history
    histFun = @(tt) localHistoryFun(tt, tStart, tEnd, tHist, yHist);
end

close(hWB);

%% =========== [4] 将所有 pass 的解拼接, 得到全局时域曲线 ==========
[tAll, yAll] = mergePiecewiseSolutions(piecewiseSols);

% 状态向量顺序: [ x; xdot; y; ydot ]
xVal = yAll(1,:);
vX   = yAll(2,:);
yVal = yAll(3,:);
vY   = yAll(4,:);

%% =========== [5] 绘图: 位移, 速度, FFT, Poincaré 映射 ===========

% (A) X(t), Y(t) 与 FFT(X)
figure('Name','(A) Displacement & FFT','Color','w');
subplot(3,1,1);
  plot(tAll, xVal, 'b-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('x(t)');
  title('X-Displacement vs Time'); grid on;

subplot(3,1,2);
  plot(tAll, yVal, 'r-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('y(t)');
  title('Y-Displacement vs Time'); grid on;

subplot(3,1,3);
  % 简易 FFT 分析
  xMeaned  = xVal - mean(xVal);
  dt       = mean(diff(tAll));
  Fs       = 1/dt;
  Xfft     = fft(xMeaned);
  Nfft     = length(Xfft);
  freqAxis = Fs*(0:(Nfft-1))/Nfft;
  ampSpec  = abs(Xfft)/Nfft;
  semilogy(freqAxis, ampSpec, 'k-','LineWidth',1.2);
  xlabel('Frequency (Hz)'); ylabel('Amplitude');
  xlim([0, 2000]);
  title('FFT of x(t)'); grid on;

% (B) 速度
figure('Name','(B) Velocity','Color','w');
subplot(2,1,1);
  plot(tAll, vX, 'b-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('dx/dt');
  title('X-Velocity vs Time'); grid on;
subplot(2,1,2);
  plot(tAll, vY, 'r-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('dy/dt');
  title('Y-Velocity vs Time'); grid on;

% (C) Poincaré 映射: 在每个齿周期末(或倍数)采样 x, xdot
figure('Name','(C) Poincare','Color','w');
tPoincare = 0 : T : tAll(end);
xP  = zeros(size(tPoincare));
vXP = zeros(size(tPoincare));

for i = 1:length(tPoincare)
    if tPoincare(i) <= tAll(end)
        Yp = piecewiseSolEval(piecewiseSols, tPoincare(i));
        xP(i)  = Yp(1);
        vXP(i) = Yp(2);
    end
end

plot(xP, vXP, 'ko','MarkerFaceColor','b','MarkerSize',4);
xlabel('x'); ylabel('dx/dt');
title('Poincaré Map (multiples of T)'); grid on;

disp('=== 优化后 pass-by-pass 仿真完成, 请查看相关图表! ===');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 以下为本脚本用到的本地函数定义 (统一放在脚本末尾) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dYdt = chatterDDE_global(t, Y, Ylag)
% chatterDDE_global:
%   pass-by-pass 每一段都会调用该函数来计算:
%   状态: Y = [x, x_dot, y, y_dot], Ylag = [x(t-T), x_dot(t-T), y(t-T), y_dot(t-T)].
%   切削力基于多齿叠加, 并采用再生厚度公式: h_d = h_s + (u_tau - u_now).
%   对 h_d<0 一律置 0, 避免非物理负厚度.

    global PARAMS

    x   = Y(1);
    xd  = Y(2);
    yv  = Y(3);
    yd  = Y(4);

    xLag = Ylag(1);
    yLag = Ylag(3);

    m_x = PARAMS.m_x; c_x = PARAMS.c_x; k_x = PARAMS.k_x;
    m_y = PARAMS.m_y; c_y = PARAMS.c_y; k_y = PARAMS.k_y;
    Z   = PARAMS.Z;   N   = PARAMS.N;
    Kt  = PARAMS.Kt;  Kr  = PARAMS.Kr;
    a   = PARAMS.a;
    feed= PARAMS.feed;

    phi_e= PARAMS.phi_e;
    phi_x= PARAMS.phi_x;

    Fx_total = 0;
    Fy_total = 0;

    % 多齿循环叠加
    for j = 0 : (Z-1)
        theta = (2*pi*N/60)*t + j*(2*pi/Z);
        th_mod = mod(theta, 2*pi);

        % 判断刀齿是否进入切削范围
        if (th_mod >= phi_e) && (th_mod <= phi_x)
            % 基础芯片厚度
            h_s = feed * sin(th_mod);

            % 坐标变换:
            %   u_now = - x*sin(th) - y*cos(th)
            %   u_tau = - xLag*sin(th) - yLag*cos(th)
            u_now = - x*sin(th_mod) - yv*cos(th_mod);
            u_tau = - xLag*sin(th_mod) - yLag*cos(th_mod);

            % 再生厚度 h_d
            h_d = h_s + (u_tau - u_now);
            if h_d < 0
                h_d = 0;  % 负厚度置0
            end

            if h_d > 0
                Ft = Kt * h_d * a;   % 切向力
                Fr = Kr * Ft;       % 径向力

                Fx_j = - sin(th_mod)*Fr - cos(th_mod)*Ft;
                Fy_j = - cos(th_mod)*Fr + sin(th_mod)*Ft;

                Fx_total = Fx_total + Fx_j;
                Fy_total = Fy_total + Fy_j;
            end
        end
    end

    % 动力学方程:
    %   m_x x'' + c_x x' + k_x x = Fx_total  --> x'' = [Fx - c_x x' - k_x x]/m_x
    xdd = (Fx_total - c_x*xd - k_x*x) / m_x;
    %   m_y y'' + c_y y' + k_y y = Fy_total
    ydd = (Fy_total - c_y*yd - k_y*yv) / m_y;

    dYdt = [ xd; xdd; yd; ydd ];
end

function val = localHistoryFun(tt, tstart, tEnd, tHist, yHist)
% localHistoryFun:
%   在 pass-by-pass 更新中, 用上一段解的插值作为本段的“历史”函数.
%   如果 tt 不在 [tstart, tEnd] 范围, 则返回段首 yHist(:,1).

    if (tt >= tstart) && (tt <= tEnd)
        val = interp1(tHist', yHist', tt, 'linear','extrap')';
    else
        val = yHist(:,1);
    end
end

function [tAll, yAll] = mergePiecewiseSolutions(piecewiseSols)
% mergePiecewiseSolutions:
%   将多段解合并, 去重, 使之成为一个完整的 (tAll, yAll).

    tAll = [];
    yAll = [];
    for i = 1:length(piecewiseSols)
        tseg = piecewiseSols{i}.x;
        yseg = piecewiseSols{i}.y;
        tAll = [tAll, tseg]; %#ok<AGROW>
        yAll = [yAll, yseg]; %#ok<AGROW>
    end

    [tAll, idxU] = unique(tAll);
    yAll = yAll(:, idxU);
end

function Yp = piecewiseSolEval(piecewiseSols, tquery)
% piecewiseSolEval:
%   给定拼接解 piecewiseSols, 在时间 tquery 上找到所在区段并 deval.
%   若超出最后一段, 返回最后一段末端状态.

    for i = 1:length(piecewiseSols)
        t0 = piecewiseSols{i}.x(1);
        t1 = piecewiseSols{i}.x(end);
        if (tquery >= t0) && (tquery <= t1)
            Yp = deval(piecewiseSols{i}, tquery);
            return;
        end
    end
    % 若超出最后一段, 则返回最后一段的末尾状态
    Yp = deval(piecewiseSols{end}, piecewiseSols{end}.x(end));
end
