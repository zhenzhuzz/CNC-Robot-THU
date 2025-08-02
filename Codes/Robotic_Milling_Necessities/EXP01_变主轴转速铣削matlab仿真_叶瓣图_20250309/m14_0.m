%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chatter_simulation_global.m
% Updated for continuous simulation with dynamic spindle speed adjustment
% Features:
%  (1) Real-time figure updates (displacement, FFT, velocity, Poincaré)
%  (2) Continuous simulation until manually stopped
%  (3) Interactive UI elements (slider and input for spindle speed)
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
PARAMS.N      = 9000;      % rpm
PARAMS.Kt     = 600e6;     % tangential cutting coeff (Pa)
PARAMS.Kr     = 0.07;      % radial ratio
PARAMS.a      = 3e-3;      % axial depth of cut (m)
PARAMS.feed   = 1e-4;      % feed per tooth (m)
PARAMS.phi_e  = 0;         % entry angle (rad)
PARAMS.phi_x  = pi;        % exit angle (rad) -> half-immersion

% One-tooth period
T = 60/(PARAMS.N * PARAMS.Z);  
PARAMS.toothPeriod = T;

% Simulation time
tmax = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) DDE FUNCTION + INITIAL HISTORY + OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ddeSys  = @chatterDDE_global;          
histFun = @(t) [0;0;0;0];             % zero displacement + velocity, t<=0

passCountEst = ceil(tmax / T);
opts = ddeset('RelTol',1e-6, 'AbsTol',1e-8);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) CREATE FIGURE WITH UI ELEMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%
f = figure('Name', 'Chatter Simulation', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 900, 600]);

% Create subplot for Displacement & FFT, Velocity, and Poincaré map
subplot1 = subplot(3, 1, 1, 'Parent', f);
subplot2 = subplot(3, 1, 2, 'Parent', f);
subplot3 = subplot(3, 1, 3, 'Parent', f);

% Create a slider to control spindle speed (N) and text for display
uicontrol('Style', 'text', 'Position', [50 550 100 30], 'String', 'Spindle Speed (N)', 'BackgroundColor', 'w');
hSlider = uicontrol('Style', 'slider', 'Min', 1000, 'Max', 20000, 'Value', PARAMS.N, 'Position', [150 550 200 20]);
hText = uicontrol('Style', 'text', 'Position', [150 580 200 20], 'String', sprintf('N = %.2f RPM', PARAMS.N), 'BackgroundColor', 'w');

% Add callback for slider to adjust spindle speed dynamically
addlistener(hSlider, 'Value', 'PreSet', @(src, event) updateSpindleSpeed(src, hText));

% Initialize time and history variables
t0 = 0;
piecewiseSols = {};
hWB = waitbar(0,'Simulation in progress...');

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) PASS-BY-PASS SOLUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%
while ishandle(f)  % Run until the figure is closed
    % Update spindle speed
    PARAMS.N = round(hSlider.Value);
    T = 60 / (PARAMS.N * PARAMS.Z);  % Update tooth period
    PARAMS.toothPeriod = T;  % Update global parameter

    % Perform a new pass
    t1 = t0 + T;
    if t1 > tmax
        t1 = tmax;
    end

    fractionDone = min(t0 / tmax, 1);
    waitbar(fractionDone, hWB, sprintf('Simulation Progress: [%.4f, %.4f]', t0, t1));

    % Solve for [t0, t1]
    solPiece = dde23(ddeSys, T, histFun, [t0, t1], opts);
    piecewiseSols{end+1} = solPiece;

    % Console output
    fprintf('Completed pass at t=%.4f\n', solPiece.x(end));

    % Update t0 for the next pass
    t0 = solPiece.x(end);
    if t0 >= tmax
        break;
    end

    % Build new local history from solver
    tStart = solPiece.x(1);
    tEnd   = solPiece.x(end);
    tHist  = linspace(tStart, tEnd, 200);
    yHist  = deval(solPiece, tHist);

    % Next pass: define local interpolation history
    histFun = @(tt) localHistoryFun_global(tt, tStart, tEnd, tHist, yHist);

    % Merge and update the plots
    [tAll, yAll] = mergeSolutions_global(piecewiseSols);

    % (A) Displacement and FFT
    plot(subplot1, tAll, yAll(1,:), 'b-', 'LineWidth', 1.2);
    xlabel(subplot1, 'Time (s)'); ylabel(subplot1, 'x(t)'); title(subplot1, 'x-displacement');

    plot(subplot2, tAll, yAll(3,:), 'r-', 'LineWidth', 1.2);
    xlabel(subplot2, 'Time (s)'); ylabel(subplot2, 'y(t)'); title(subplot2, 'y-displacement');

    % FFT of x-displacement
    xVals = yAll(1,:) - mean(yAll(1,:));
    dt = mean(diff(tAll));
    Fs = 1 / dt;
    L = length(xVals);
    Xfft = fft(xVals);
    faxis = Fs * (0:(L - 1)) / L;
    Amp = abs(Xfft) / L;
    plot(subplot3, faxis, Amp, 'k-', 'LineWidth', 1.2);
    xlabel(subplot3, 'Frequency (Hz)'); ylabel(subplot3, 'Amplitude');
    xlim(subplot3, [0, 2000]);
    title(subplot3, 'FFT of x(t)');
    drawnow;  % Update plots

end

close(hWB);  % Close waitbar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  LOCAL FUNCTIONS (EACH REFERENCES 'global PARAMS' AS NEEDED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function updateSpindleSpeed(slider, textHandle)
    % Callback function to update spindle speed (N) in the UI
    N = round(slider.Value);
    PARAMS.N = N;
    set(textHandle, 'String', sprintf('N = %.2f RPM', N));
end

function dYdt = chatterDDE_global(t, Y, Z_lag)
    % This function computes the chatter forces using global parameters
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
    for j = 0:(Z - 1)
        th = (2*pi*N / 60) * t - j * (2*pi / Z);
        th_mod = mod(th, 2*pi);

        if (th_mod >= phi_e) && (th_mod <= phi_x)
            hs = feed * abs(sin(th_mod));
            u_now = - x1 * sin(th_mod) - y1 * cos(th_mod);
            u_tau = - x1_tau * sin(th_mod) - y1_tau * cos(th_mod);
            hd = hs + (u_now - u_tau);
            if hd > 0
                Ft = Kt * hd * a;
                Fr = Kt * Kr * hd * a;
                Fx_j = -sin(th_mod) * Fr - cos(th_mod) * Ft;
                Fy_j = -cos(th_mod) * Fr + sin(th_mod) * Ft;
                Fx_total = Fx_total + Fx_j;
                Fy_total = Fy_total + Fy_j;
            end
        end
    end

    dx1dt = x2;
    dx2dt = (1/m_x) * (Fx_total - c_x * x2 - k_x * x1);
    dy1dt = y2;
    dy2dt = (1/m_y) * (Fy_total - c_y * y2 - k_y * y1);

    dYdt = [dx1dt; dx2dt; dy1dt; dy2dt];
end

function v = localHistoryFun_global(tt, tStart, tEnd, tHist, yHist)
    if (tt >= tStart) && (tt <= tEnd)
        v = interp1(tHist', yHist', tt, 'linear', 'extrap')';
    else
        v = yHist(:, 1);
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
