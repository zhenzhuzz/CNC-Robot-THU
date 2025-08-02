%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chatter_simulation_global.m
% Demonstrates pass-by-pass chatter simulation using DDE23 and GLOBAL params
% Features:
%  (1) All main variables in 'global PARAMS' -> accessible in base workspace
%  (2) Pass-by-pass integration with time delay T
%  (3) Waitbar + console output each pass
%  (4) Final plots: 3×1 displacement + FFT, velocity, Poincaré
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;          % Close all existing figures
clearvars;          % Clear local variables
clc;                % Clear Command Window

global PARAMS       % Declare a global struct for parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) DEFINE GLOBAL PARAMS
%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.m_x    = 0.5;       % mass in x (kg)
PARAMS.zeta_x = 0.035;     
PARAMS.wn_x   = 2*pi*600;  
PARAMS.c_x    = 2*PARAMS.zeta_x*PARAMS.m_x*PARAMS.wn_x;
PARAMS.k_x    = PARAMS.m_x*(PARAMS.wn_x^2);

PARAMS.m_y    = 0.5;
PARAMS.zeta_y = 0.035;
PARAMS.wn_y   = 2*pi*660;
PARAMS.c_y    = 2*PARAMS.zeta_y*PARAMS.m_y*PARAMS.wn_y;
PARAMS.k_y    = PARAMS.m_y*(PARAMS.wn_y^2);

PARAMS.Z      = 4;         % number of teeth
PARAMS.N      = 3000;      % rpm
PARAMS.Kt     = 600e6;     % tangential cutting coeff (Pa)
PARAMS.Kr     = 0.07;      % radial ratio
PARAMS.a      = 1e-3;      % axial depth of cut (m)
PARAMS.feed   = 1e-4;      % feed per tooth (m)
PARAMS.phi_e  = 0;         % entry angle (rad)
PARAMS.phi_x  = pi;        % exit angle (rad) -> half-immersion

% One-tooth period
T = 60/(PARAMS.N * PARAMS.Z);  
PARAMS.toothPeriod = T;

% Simulation time
tmax = 0.2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) DDE FUNCTION + INITIAL HISTORY + OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We reference global PARAMS from chatterDDE_global, so no arguments needed.
ddeSys  = @chatterDDE_global;          
histFun = @(t) [0;0;0;0];             % zero displacement + velocity, t<=0

passCountEst = ceil(tmax / T);
opts = ddeset('RelTol',1e-6, 'AbsTol',1e-8);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) PASS-BY-PASS SOLUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%
t0 = 0;
piecewiseSols = {};

% Waitbar
hWB = waitbar(0,'Simulation in progress...');

for passIndex = 1:passCountEst
    t1 = t0 + T;
    if t1 > tmax
        t1 = tmax;
    end

    fractionDone = min(passIndex/passCountEst,1);
    waitbar(fractionDone, hWB, ...
        sprintf('Pass %d / %d: [%.4f, %.4f]', passIndex, passCountEst, t0, t1));
    drawnow;

    % Solve for [t0, t1]
    solPiece = dde23(ddeSys, T, histFun, [t0, t1], opts);
    piecewiseSols{end+1} = solPiece; %#ok<AGROW>

    % Show console message
    fprintf('Completed pass %d at t=%.4f\n', passIndex, solPiece.x(end));

    % Update t0 for the next pass
    t0 = solPiece.x(end);
    if t0 >= tmax
        break;
    end

    % Build new local history from the solver's actual domain
    tStart = solPiece.x(1);
    tEnd   = solPiece.x(end);
    tHist  = linspace(tStart, tEnd, 200);
    yHist  = deval(solPiece, tHist);

    % Next pass: define local interpolation history
    histFun = @(tt) localHistoryFun_global(tt, tStart, tEnd, tHist, yHist);
end

close(hWB);  % close waitbar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) MERGE PIECEWISE SOLUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[tAll, yAll] = mergeSolutions_global(piecewiseSols);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) FINAL PLOTS: DISPLACEMENT, VELOCITY, POINCARÉ MAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% (A) 3x1: x(t), y(t), and FFT(x)
figure('Name','(A) Displacement & FFT','Color','w');
subplot(3,1,1)
  plot(tAll, yAll(1,:), 'b-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('x(t)'); title('x-displacement');

subplot(3,1,2)
  plot(tAll, yAll(3,:), 'r-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('y(t)'); title('y-displacement');

subplot(3,1,3)
  xVals = yAll(1,:) - mean(yAll(1,:));
  dt    = mean(diff(tAll));
  Fs    = 1/dt;
  L     = length(xVals);
  Xfft  = fft(xVals);
  faxis = Fs*(0:(L-1))/L;
  Amp   = abs(Xfft)/L;
  plot(faxis, Amp, 'k-','LineWidth',1.2);
  xlabel('Frequency (Hz)'); ylabel('Amplitude');
  xlim([0, 2000]);
  title('FFT of x(t)');
  grid on;

% (B) Velocity
figure('Name','(B) Velocity','Color','w');
subplot(2,1,1)
  plot(tAll, yAll(2,:), 'b-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('dx/dt'); title('Velocity in X');
subplot(2,1,2)
  plot(tAll, yAll(4,:), 'r-','LineWidth',1.2);
  xlabel('Time (s)'); ylabel('dy/dt'); title('Velocity in Y');

% (C) Poincaré Plot
figure('Name','(C) Poincaré','Color','w');
tPoincare = 0 : T : tAll(end);
xP  = zeros(size(tPoincare));
dxP = zeros(size(tPoincare));
for i = 1:length(tPoincare)
    if tPoincare(i) <= tAll(end)
        Yp = ddevalPiecewise_global(piecewiseSols, tPoincare(i));
        xP(i)  = Yp(1);
        dxP(i) = Yp(2);
    end
end
plot(xP, dxP, 'ko','MarkerFaceColor','b','MarkerSize',4);
xlabel('x'); ylabel('dx/dt');
title('Poincaré Map at multiples of tooth period');
grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  LOCAL FUNCTIONS (EACH REFERENCES 'global PARAMS' AS NEEDED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dYdt = chatterDDE_global(t, Y, Z_lag)
% Uses the global PARAMS to compute chatter forces
global PARAMS

x1 = Y(1);  x2 = Y(2);
y1 = Y(3);  y2 = Y(4);
x1_tau = Z_lag(1);
y1_tau = Z_lag(3);

% Unpack from PARAMS
m_x  = PARAMS.m_x;   c_x = PARAMS.c_x;   k_x = PARAMS.k_x;
m_y  = PARAMS.m_y;   c_y = PARAMS.c_y;   k_y = PARAMS.k_y;
Kt   = PARAMS.Kt;    Kr  = PARAMS.Kr;    a   = PARAMS.a;
feed = PARAMS.feed;  Z   = PARAMS.Z;     N   = PARAMS.N;
phi_e= PARAMS.phi_e; phi_x=PARAMS.phi_x;

Fx_total = 0; Fy_total = 0;
for j = 0:(Z-1)
    th = (2*pi*N/60)*t - j*(2*pi/Z);
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
% Interpolate states within [tStart, tEnd], else fallback
if (tt >= tStart) && (tt <= tEnd)
    v = interp1(tHist', yHist', tt, 'linear','extrap')';
else
    v = yHist(:,1);
end
end

function [tAll, yAll] = mergeSolutions_global(piecewiseSols)
% Concatenate piecewise solutions, removing duplicates
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

function Yp = ddevalPiecewise_global(piecewiseSols, tquery)
% Evaluate piecewise solution at time tquery
for i = 1:length(piecewiseSols)
    tstart = piecewiseSols{i}.x(1);
    tend   = piecewiseSols{i}.x(end);
    if (tquery >= tstart) && (tquery <= tend)
        Yp = deval(piecewiseSols{i}, tquery);
        return;
    end
end
% If beyond last piece, fallback to final state
Yp = deval(piecewiseSols{end}, piecewiseSols{end}.x(end));
end
