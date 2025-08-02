%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chatter_simulation_global.m
% Updated for continuous simulation with dynamic spindle speed adjustment
% Features:
%  (1) Four subplots (2x2 layout)
%  (2) Reset button to reset everything from start
%  (3) Spindle speed variation plot with time as x-axis
%  (4) Removed y-limit input boxes
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

PARAMS.timeWindow = 0.2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) DDE FUNCTION + INITIAL HISTORY + OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ddeSys  = @chatterDDE_global;          
histFun = @(t) [0;0;0;0];             % zero displacement + velocity, t<=0

opts = ddeset('RelTol',1e-6, 'AbsTol',1e-8);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) CREATE FIGURE WITH UI ELEMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%
f = figure('Name', 'Chatter Simulation', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 20, 1000, 800]);

% Create 2x2 subplots for Displacement & FFT, Velocity, and Spindle Speed
subplot1 = subplot(2, 3, 1, 'Parent', f); % x-displacement
subplot2 = subplot(2, 3, 2, 'Parent', f); % y-displacement
subplot3 = subplot(2, 3, 3, 'Parent', f); % FFT of x-displacement
subplot4 = subplot(2, 3, 4, 'Parent', f); % Spindle speed variation
subplot5 = subplot(2, 3, 5, 'Parent', f); % Spindle speed variation


% Create a slider to control spindle speed (N) and text for display
uicontrol('Style', 'text', 'Position', [50 700 100 30], 'String', 'Spindle Speed (N)', 'BackgroundColor', 'w');
hSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 15000, 'Value', PARAMS.N, ...
                    'Position', [150 700 200 20], 'SliderStep', [0.005 0.1]);

% Dynamically updated text for spindle speed
hText = uicontrol('Style', 'text', 'Position', [150 730 200 20], 'String', sprintf('N = %.2f RPM', PARAMS.N), 'BackgroundColor', 'w');

% Add callback for slider to adjust spindle speed dynamically and update text
addlistener(hSlider, 'ContinuousValueChange', @(src, event) updateSpindleSpeed(src, hText));

% Reset button to reset everything from the start
uicontrol('Style', 'pushbutton', 'Position', [800 700 120 40], 'String', 'Reset', 'Callback', @(src, event) resetSimulation());

% Initialize time and history variables
t0 = 0;
piecewiseSols = {};
timeHistory = [];  % To store time for all plots (consistent for all)
spindleSpeedHistory = [];  % To store spindle speed for variation plot
energyHistory = []; % Initialize energyHistory as an empty array

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

    % Solve for [t0, t1]
    solPiece = dde23(ddeSys, T, histFun, [t0, t1], opts);
    piecewiseSols{end+1} = solPiece;

    % Update spindle speed history for variation plot
    timeHistory = [timeHistory, solPiece.x + t0];
    spindleSpeedHistory = [spindleSpeedHistory, repmat(PARAMS.N, size(solPiece.x))];

    % Update t0 for the next pass
    t0 = solPiece.x(end);

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
    
    % Display last PARAMS.timeWindow seconds data once available
    if max(tAll) > PARAMS.timeWindow
        xlim(subplot1, [max(tAll) - PARAMS.timeWindow, max(tAll)]);
    else
        xlim(subplot1, [0, max(tAll)]);
    end

    plot(subplot2, tAll, yAll(3,:), 'r-', 'LineWidth', 1.2);
    xlabel(subplot2, 'Time (s)'); ylabel(subplot2, 'y(t)'); title(subplot2, 'y-displacement');
    
    % Display last PARAMS.timeWindow seconds data once available
    if max(tAll) > PARAMS.timeWindow
        xlim(subplot2, [max(tAll) - PARAMS.timeWindow, max(tAll)]);
    else
        xlim(subplot2, [0, max(tAll)]);
    end

    % FFT of x-displacement
    xVals = yAll(1,:) - mean(yAll(1,:));  % Remove the mean to center the signal
    dt = mean(diff(tAll));                % Time step (assuming uniform sampling)
    Fs = 1 / dt;                           % Sampling frequency
    L = length(xVals);                    % Length of the signal
    Xfft = fft(xVals);                    % Compute the FFT
    faxis = Fs * (0:(L - 1)) / L;         % Frequency axis
    Amp = abs(Xfft) / L;                  % FFT amplitude (normalized)
    
    % Compute the energy as the sum of squared FFT amplitudes
    energy = sum(Amp.^2);
    
    % Plot the FFT amplitude (same as before)
    plot(subplot3, faxis, Amp, 'k-', 'LineWidth', 1.2);
    xlabel(subplot3, 'Frequency (Hz)'); ylabel(subplot3, 'Amplitude');
    xlim(subplot3, [0, 2000]);
    title(subplot3, 'FFT of x(t)');
    
    % Spindle speed variation plot
    plot(subplot4, timeHistory, spindleSpeedHistory, 'b-', 'LineWidth', 1.2);
    xlabel(subplot4, 'Time (s)'); ylabel(subplot4, 'Spindle Speed (RPM)');
    title(subplot4, 'Spindle Speed Variation');
    xlim(subplot4, [0, max(timeHistory)]);
    
    % Store the energy in energyHistory
    energyHistory = [energyHistory, repmat(energy, size(solPiece.x))];  % Add the current energy value to the history for each time step
    
    % Plot energy spectrum history in subplot5
    plot(subplot5, timeHistory, energyHistory, 'g-', 'LineWidth', 1.2);
    xlabel(subplot5, 'Time (s)'); ylabel(subplot5, 'Energy');
    title(subplot5, 'Energy Spectrum History');
    xlim(subplot5, [0, max(timeHistory)]);  % Adjust x-axis to the maximum time

    drawnow;  % Update plots
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  LOCAL FUNCTIONS (EACH REFERENCES 'global PARAMS' AS NEEDED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function to update spindle speed and the corresponding text
function updateSpindleSpeed(slider, textHandle)
    % Callback function to update spindle speed (N) in the UI
    N = round(slider.Value);
    PARAMS.N = N;
    set(textHandle, 'String', sprintf('N = %.2f RPM', N));  % Update the text dynamically
end

function resetSimulation()
    % Reset the simulation to the initial values
    global PARAMS timeHistory spindleSpeedHistory piecewiseSols
    
    PARAMS.N = 9000;  % Default spindle speed
    set(hSlider, 'Value', PARAMS.N);
    set(hText, 'String', sprintf('N = %.2f RPM', PARAMS.N));
    
    % Clear history and reset time
    timeHistory = [];
    spindleSpeedHistory = [];
    piecewiseSols = {};
    
    % Reset the figure plots
    subplot1 = subplot(2, 2, 1);
    subplot2 = subplot(2, 2, 2);
    subplot3 = subplot(2, 2, 3);
    subplot4 = subplot(2, 2, 4);
    cla(subplot1); cla(subplot2); cla(subplot3); cla(subplot4);
    title(subplot1, 'x-displacement'); title(subplot2, 'y-displacement');
    title(subplot3, 'FFT of x(t)'); title(subplot4, 'Spindle Speed Variation');
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


