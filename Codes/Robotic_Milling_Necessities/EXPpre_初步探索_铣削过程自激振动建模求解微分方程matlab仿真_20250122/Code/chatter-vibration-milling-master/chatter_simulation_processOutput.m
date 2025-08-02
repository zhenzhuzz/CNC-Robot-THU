function chatter_simulation_processOutput
    close all;

% chatter_simulation_processOutput
% --------------------------------------------------------------
% Pass-by-pass milling chatter simulation using DDE23.
% Features:
%  (1) Waitbar + console output per pass
%  (2) Merge piecewise solutions
%  (3) Plots:
%       (A) 3×1: x(t), y(t), FFT of x(t)
%       (B) Velocity in x,y
%       (C) Poincaré map
%
% Each pass integrates over [t0, t0+T], updating history for the next pass.
% Delayed states from previous tooth pass ensure proper chip thickness.
%
% Author: Zhen Zhu
% --------------------------------------------------------------

    %% 1) DEFINE MODEL PARAMETERS
    params = struct();
    % X-direction dynamics
    params.m_x    = 0.5;      
    params.zeta_x = 0.035;    
    params.wn_x   = 2*pi*600;
    params.c_x    = 2*params.zeta_x*params.m_x*params.wn_x;
    params.k_x    = params.m_x*(params.wn_x^2);
    % Y-direction dynamics
    params.m_y    = 0.5;
    params.zeta_y = 0.035;
    params.wn_y   = 2*pi*660;
    params.c_y    = 2*params.zeta_y*params.m_y*params.wn_y;
    params.k_y    = params.m_y*(params.wn_y^2);
    % Milling parameters
    params.Z      = 4;          
    params.N      = 9000;       
    params.Kt     = 600e6;      
    params.Kr     = 0.07;       
    params.a      = 3e-3;       
    params.feed   = 1e-4;       
    params.phi_e  = 0;          
    params.phi_x  = pi;         
    % Time delay (one tooth period)
    T = 60/(params.N * params.Z);
    params.toothPeriod = T;

    % Simulation time
    tmax = 0.2;

    %% 2) SETUP: DDE, HISTORY, OPTIONS
    ddeSys  = @(t,y,Z) chatterDDE(t,y,Z,params);
    histFun = @(t) [0; 0; 0; 0];  % zero for t<=0
    passCountEst = ceil(tmax / T);
    opts = ddeset('RelTol',1e-6, 'AbsTol',1e-8);

    %% 3) WAITBAR + LOOP INITIALIZATION
    handle = waitbar(0,'Please wait... simulation in progress...');
    piecewiseSols = {};
    t0 = 0;

    %% 4) PASS-BY-PASS INTEGRATION
    for passIndex = 1:passCountEst
        t1 = t0 + T;
        if t1 > tmax
            t1 = tmax;
        end

        fractionDone = min(passIndex / passCountEst, 1);
        waitbar(fractionDone, handle, ...
            sprintf('Simulation in progress... pass %d / %d', ...
                    passIndex, passCountEst));
        drawnow;

        solPiece = dde23(ddeSys, T, histFun, [t0, t1], opts);
        piecewiseSols{end+1} = solPiece; %#ok<AGROW>

        tEnd = solPiece.x(end);
        fprintf('Completed pass %d at t=%.4f\n', passIndex, tEnd);

        t0 = tEnd;
        if t0 >= tmax, break; end

        % Build updated history from solver domain
        tStartPiece = solPiece.x(1);
        tEndPiece   = solPiece.x(end);
        tHistRange  = linspace(tStartPiece, tEndPiece, 200);
        yHistRange  = deval(solPiece, tHistRange);

        histFun = @(tt) localHistoryFun(tt, ...
                                        tStartPiece, tEndPiece, ...
                                        tHistRange, yHistRange);
    end
    close(handle);

    %% 5) MERGE SOLUTIONS
    [tAll, yAll] = mergeSolutions(piecewiseSols);

    %% 6) PLOTTING
    % (A) Displacement & FFT in 3×1
    figure('Name','(A) Displacement & FFT','Color','w');
    subplot(3,1,1)
      plot(tAll, yAll(1,:), 'b-','LineWidth',1.2);
      xlabel('Time (s)'); ylabel('x(t) [m]'); title('x-displacement');
    subplot(3,1,2)
      plot(tAll, yAll(3,:), 'r-','LineWidth',1.2);
      xlabel('Time (s)'); ylabel('y(t) [m]'); title('y-displacement');
    subplot(3,1,3)
      xVals = yAll(1,:) - mean(yAll(1,:));
      dt    = mean(diff(tAll));
      Fs    = 1/dt;
      L     = length(xVals);
      Xfft  = fft(xVals);
      faxis = Fs*(0:(L-1))/L;
      Amp   = abs(Xfft)/L;
      plot(faxis, Amp, 'k-','LineWidth',1.2);
      xlabel('Frequency (Hz)'); ylabel('Amplitude'); xlim([0,2000]);
      title('FFT of x(t)');

    % (B) Velocity
    figure('Name','(B) Velocity','Color','w');
    subplot(2,1,1)
      plot(tAll, yAll(2,:),'b-','LineWidth',1.2);
      xlabel('Time (s)'); ylabel('dx/dt'); title('Velocity in X');
    subplot(2,1,2)
      plot(tAll, yAll(4,:),'r-','LineWidth',1.2);
      xlabel('Time (s)'); ylabel('dy/dt'); title('Velocity in Y');

    % (C) Poincaré Map
    figure('Name','(C) Poincare','Color','w');
    tPoincare = 0 : T : tAll(end);
    xP  = zeros(size(tPoincare));
    dxP = zeros(size(tPoincare));
    for i=1:length(tPoincare)
        if tPoincare(i) <= tAll(end)
            Yp = ddevalPiecewise(piecewiseSols, tPoincare(i));
            xP(i)  = Yp(1);
            dxP(i) = Yp(2);
        end
    end
    plot(xP, dxP, 'ko','MarkerFaceColor','b','MarkerSize',4);
    xlabel('x'); ylabel('dx/dt'); title('Poincaré Map');
    grid on;
end

%% ========================================================================
%  SUBFUNCTIONS
% ========================================================================

function dYdt = chatterDDE(t, Y, Z_lag, params)
    % 2-DOF DDE for chatter:
    %   Y=[x; dx; y; dy],  Z_lag=[x(t-T); dx(t-T); y(t-T); dy(t-T)]
    x1 = Y(1);  x2 = Y(2);
    y1 = Y(3);  y2 = Y(4);
    x1_tau = Z_lag(1);
    y1_tau = Z_lag(3);

    m_x = params.m_x; c_x = params.c_x; k_x = params.k_x;
    m_y = params.m_y; c_y = params.c_y; k_y = params.k_y;
    Kt  = params.Kt;  Kr  = params.Kr;  a = params.a;
    feed= params.feed; Z = params.Z; N = params.N;
    phi_e = params.phi_e; phi_x = params.phi_x;

    Fx_total = 0; Fy_total = 0;
    for j = 0:Z-1
        th = (2*pi*N/60)*t - j*(2*pi/Z);
        th_mod = mod(th, 2*pi);
        if (th_mod >= phi_e) && (th_mod <= phi_x)
            hs   = feed*abs(sin(th_mod));
            u_now= -x1*sin(th_mod) - y1*cos(th_mod);
            u_tau= -x1_tau*sin(th_mod) - y1_tau*cos(th_mod);
            hd   = hs + (u_now - u_tau);
            if hd>0
                Ft = Kt*hd*a;  Fr = Kt*Kr*hd*a;
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

function v = localHistoryFun(tt, t0, t1, tHist, yHist)
    % Interpolate the last pass if tt in [t0, t1], else fallback
    if (tt>=t0) && (tt<=t1)
        v = interp1(tHist', yHist', tt, 'linear','extrap')';
    else
        v = yHist(:,1);
    end
end

function [tAll, yAll] = mergeSolutions(piecewiseSols)
    % Concatenate piecewise solutions
    tAll = [];
    yAll = [];
    for i=1:length(piecewiseSols)
        tx = piecewiseSols{i}.x;
        yx = piecewiseSols{i}.y;
        tAll = [tAll, tx]; %#ok<AGROW>
        yAll = [yAll, yx]; %#ok<AGROW>
    end
    [tAll, idx] = unique(tAll);
    yAll = yAll(:, idx);
end

function Yp = ddevalPiecewise(piecewiseSols, tquery)
    % Evaluate in correct pass that covers tquery
    for i = 1:length(piecewiseSols)
        tstart = piecewiseSols{i}.x(1);
        tend   = piecewiseSols{i}.x(end);
        if (tquery>=tstart) && (tquery<=tend)
            Yp = deval(piecewiseSols{i}, tquery);
            return;
        end
    end
    % If beyond final pass, return last point
    Yp = deval(piecewiseSols{end}, piecewiseSols{end}.x(end));
end
