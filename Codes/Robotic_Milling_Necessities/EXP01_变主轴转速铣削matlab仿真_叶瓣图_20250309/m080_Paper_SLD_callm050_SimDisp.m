%% stability_map_script.m
clear; clc;

% 仿真参数
feedRate = 450;   % 进给速率（mm/min）
numTeeth = 4;     % 刀齿数
simTime  = 1;     % 仿真时间（s）

rpm_values = 4000:1000:10000;
cutDepth_values = 5e-3:-1e-3:0;  % 单位 m

% 创建图形窗口
figure;
hold on;
markerSize = 50;  % 标记尺寸

% 循环遍历所有组合
for i = 1:length(rpm_values)
    for j = 1:length(cutDepth_values)
        curr_rpm = rpm_values(i);
        curr_cutDepth = cutDepth_values(j);
        simOut = milling_simulation(curr_rpm, curr_cutDepth, 450, 4, 1);
        % 根据 simOut 结果绘图
        if ~simOut.toolBroken
            scatter(curr_rpm, curr_cutDepth, 50, 'g', 'filled');
        else
            fraction = simOut.finalTime / 1;
            if fraction < 1/3
                alphaVal = 1.0;
            elseif fraction < 2/3
                alphaVal = 0.6;
            else
                alphaVal = 0.3;
            end
            s = scatter(curr_rpm, curr_cutDepth, 50, 'r', 'x');
            s.MarkerEdgeAlpha = alphaVal;
        end
        drawnow;
    end
end


xlabel('Spindle Speed (rpm)', 'FontSize', 12);
ylabel('Cutting Depth (m)', 'FontSize', 12);
title('Stability Map', 'FontSize', 14);
grid on;
hold off;

% 保存图形为 PNG 文件，分辨率 1500 DPI
fileName = 'p030_SLD.png';
print(gcf, fileName, '-dpng', '-r1500');



function simOut = milling_simulation(rpm, cutDepth, feedRate, numTeeth, simTime)
% milling_simulation - 基于给定主轴转速、切削深度、进给速率（mm/min）、刀齿数和仿真时间，
%                    计算仿真过程中是否发生断刀（颤振）并返回实际仿真时间。
%
% 输入参数：
%   rpm       - 主轴转速（rpm），数值或标量
%   cutDepth  - 切削深度（m），数值或标量
%   feedRate  - 进给速率（mm/min）
%   numTeeth  - 刀齿数
%   simTime   - 仿真总时长（s）
%
% 输出 simOut 结构体包含：
%   toolBroken  - 若发生断刀则为 true，否则为 false
%   finalTime   - 实际仿真结束时间（若断刀则 < simTime，否则 = simTime）
%   tAll, yAll  - 合并后的时域数据（可选，用于后续分析）

    % 使用全局变量 PARAMS 保存系统参数
    global PARAMS;
    
    % 初始化结构参数（不清空工作区，便于循环调用）
    PARAMS.k_x    = 5.6e6;         % 刚度 (N/m)
    PARAMS.zeta_x = 0.035;     
    PARAMS.wn_x   = 2*pi*600;  
    PARAMS.m_x    = PARAMS.k_x / (PARAMS.wn_x^2);
    PARAMS.c_x    = 2*PARAMS.zeta_x*PARAMS.m_x*PARAMS.wn_x;

    PARAMS.k_y    = 5.6e6;
    PARAMS.zeta_y = 0.035;
    PARAMS.wn_y   = 2*pi*660;
    PARAMS.m_y    = PARAMS.k_y / (PARAMS.wn_y^2);
    PARAMS.c_y    = 2*PARAMS.zeta_y*PARAMS.m_y*PARAMS.wn_y;

    PARAMS.Kt     = 600e6;        % 切向切削系数 (Pa)
    PARAMS.Kr     = 0.07;         % 径向比例系数
    PARAMS.phi_e  = 0;            % 切入角 (rad)
    PARAMS.phi_x  = pi;           % 切出角 (rad)
    PARAMS.Z      = numTeeth;      % 刀齿数
    
    toolBrokenLimit = 5e-3;  % 振动位移阈值（m）

    % 支持向量化设置：如果 rpm 或 cutDepth 为标量，则扩展为段向量
    segCount = max(length(rpm), length(cutDepth));
    if isscalar(rpm)
        rpm = repmat(rpm, segCount, 1);
    end
    if isscalar(cutDepth)
        cutDepth = repmat(cutDepth, segCount, 1);
    end
    segTime = simTime / segCount; % 每段仿真时间

    overallSols = {};  % 存储各段解
    overallTime = 0;   % 总体时间起点
    histFun = @(t) [0; 0; 0; 0];  % 初始历史函数
    toolBroken = false; % 断刀标志

    %% 外层循环（逐段仿真）
    for seg = 1:segCount
        % 更新当前段参数
        PARAMS.N = rpm(seg);
        PARAMS.a = cutDepth(seg);
        % 进给速率（mm/min 转 m/min）下计算 chip load（m/tooth）
        PARAMS.feed = (feedRate/1000) / (PARAMS.N * numTeeth);
        % 当前段单齿周期
        T = 60/(PARAMS.N * PARAMS.Z);
        PARAMS.toothPeriod = T;
        
        % 当前段起止时间
        segStart = overallTime;
        segEnd   = overallTime + segTime;
        
        t0 = segStart;
        segSols = {};  % 存储当前段各 pass 解
        passCountEst = ceil((segEnd - segStart) / T);
        
        % 内层循环（逐 pass 仿真）
        for passIndex = 1:passCountEst
            t1 = t0 + T;
            if t1 > segEnd
                t1 = segEnd;
            end
            solPiece = dde23(@chatterDDE_global, T, histFun, [t0, t1], ...
                              ddeset('RelTol',1e-6, 'AbsTol',1e-8));
            segSols{end+1} = solPiece;
            % 检查 x 或 y 振动是否超过设定阈值
            if max(abs(solPiece.y(1,:))) > toolBrokenLimit || ...
               max(abs(solPiece.y(3,:))) > toolBrokenLimit
                toolBroken = true;
                t0 = solPiece.x(end);
                break;
            end
            
            t0 = solPiece.x(end);
            if t0 >= segEnd
                break;
            end
            
            % 更新局部历史函数：插值当前段解
            tStart_local = solPiece.x(1);
            tEnd_local = solPiece.x(end);
            tHist  = linspace(tStart_local, tEnd_local, 200);
            yHist  = deval(solPiece, tHist);
            histFun = @(tt) localHistoryFun_global(tt, tStart_local, tEnd_local, tHist, yHist);
        end
        overallSols = [overallSols, segSols];
        overallTime = segEnd;
        
        if toolBroken
            break;
        end
    end

    % 合并各段解（可选，后续分析时用）
    [tAll, yAll] = mergeSolutions_global(overallSols);

    % 返回结果结构体
    simOut.toolBroken = toolBroken;
    simOut.finalTime  = overallTime;  % 若断刀，则 < simTime；否则 = simTime
    simOut.tAll = tAll;
    simOut.yAll = yAll;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 以下为局部函数（必须放在主函数之后）
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dYdt = chatterDDE_global(t, Y, Z_lag)
    global PARAMS
    x1 = Y(1);  x2 = Y(2);
    y1 = Y(3);  y2 = Y(4);
    x1_tau = Z_lag(1);
    y1_tau = Z_lag(3);

    m_x  = PARAMS.m_x;   c_x = PARAMS.c_x;   k_x = PARAMS.k_x;
    m_y  = PARAMS.m_y;   c_y = PARAMS.c_y;   k_y = PARAMS.k_y;
    Kt   = PARAMS.Kt;    Kr  = PARAMS.Kr;    a   = PARAMS.a;
    feed = PARAMS.feed;  Z   = PARAMS.Z;     N   = PARAMS.N;
    phi_e = PARAMS.phi_e; phi_x = PARAMS.phi_x;

    Fx_total = 0; 
    Fy_total = 0;
    for j = 0:(Z-1)
        th = (2*pi*N/60)*t + j*(2*pi/Z);
        th_mod = mod(th, 2*pi);
        if (th_mod >= phi_e) && (th_mod <= phi_x)
            hs    = feed*abs(sin(th_mod));
            u_now = - x1*sin(th_mod) - y1*cos(th_mod);
            u_tau = - x1_tau*sin(th_mod) - y1_tau*cos(th_mod);
            hd    = hs + (u_now - u_tau);
            if hd > 0
                Ft   = Kt*hd*a;
                Fr   = Kt*Kr*hd*a;
                Fx_j = -sin(th_mod)*Fr - cos(th_mod)*Ft;
                Fy_j = -cos(th_mod)*Fr + sin(th_mod)*Ft;
                Fx_total = Fx_total + Fx_j;
                Fy_total = Fy_total + Fy_j;
            end
        end
    end

    dx1dt = x2;
    dx2dt = (1/m_x)*(Fx_total - c_x*x2 - k_x*x1);
    dy1dt = y2;
    dy2dt = (1/m_y)*(Fy_total - c_y*y2 - k_y*y1);

    dYdt = [dx1dt; dx2dt; dy1dt; dy2dt];
end

function v = localHistoryFun_global(tt, tStart, tEnd, tHist, yHist)
    if (tt >= tStart) && (tt <= tEnd)
        v = interp1(tHist', yHist', tt, 'linear', 'extrap')';
    else
        v = yHist(:,1);
    end
end

function [tAll, yAll] = mergeSolutions_global(piecewiseSols)
    tAll = [];
    yAll = [];
    for i = 1:length(piecewiseSols)
        tseg = piecewiseSols{i}.x;
        yseg = piecewiseSols{i}.y;
        tAll = [tAll, tseg];
        yAll = [yAll, yseg];
    end
    [tAll, idxU] = unique(tAll);
    yAll = yAll(:, idxU);
end

function Yp = ddevalPiecewise_global(piecewiseSols, tquery)
    for i = 1:length(piecewiseSols)
        tstart = piecewiseSols{i}.x(1);
        tend   = piecewiseSols{i}.x(end);
        if (tquery >= tstart) && (tquery <= tend)
            Yp = deval(piecewiseSols{i}, tquery);
            return;
        end
    end
    Yp = deval(piecewiseSols{end}, piecewiseSols{end}.x(end));
end
