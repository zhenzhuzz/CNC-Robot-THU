% Copyright
% Zhen Zhu
% January 5, 2025

% m11_milling_CSSV.m
% Demonstrates how to update the figure at each revolution with sine-modulated spindle speed.

clc;
close all;
clear;

% ------------------------------------------------
% Define cutting force coefficients
Ks = 2000e6;  % N/m^2
beta = 70;    % deg
kt = Ks * sin(beta*pi/180);
kn = Ks * cos(beta*pi/180);
C = 2e4;      % N/m

% ------------------------------------------------
% Define modal parameters for x direction
kx = [9e6];             % N/m
zetax = [0.03];
wnx = [900] * 2*pi;     % rad/s
mx = kx ./ (wnx.^2);    % kg
cx = 2 * zetax .* sqrt(mx .* kx);  % N-s/m

% ------------------------------------------------
% Define modal parameters for y direction
ky = [9e6];             % N/m
zetay = [0.03];
wny = [900] * 2*pi;     % rad/s
my = ky ./ (wny.^2);    % kg
cy = 2 * zetay .* sqrt(my .* ky);  % N-s/m

% ------------------------------------------------
% Define cutting parameters
Nt = 3;          % number of teeth
d = 19e-3;       % teeth diameter (m)
gamma = 30;      % helix angle (deg)
phis = 0;        % start angle (deg)
phie = 90;       % exit angle (deg)
ft = 0.1e-3;     % feed per tooth (m)
b = 3e-3;        % axial depth of cut (m)
omega0 = 8500;  % base spindle speed (rpm)
speed_increment = 50;  % rpm

% ------------------------------------------------
% Sine Modulation Parameters
RVA = 0.3;       % Ratio of modulation amplitude (<= 0.3)
RVF = 1;         % Ratio of modulation frequency (not equal to 1)
phi_phase = 0;   % Phase shift (radians)

% ------------------------------------------------
% Vibration threshold
x_threshold = 300e-6;     % (m), e.g. 300 microns

% ------------------------------------------------
% Total number of revolutions
rev = 20;               
revs_completed = 0;

% ------------------------------------------------
% Select Mode
% Uncomment one of the following lines to set the desired mode
% mode = 0;  % No modulation, No chatter detection
% mode = 1;  % No modulation, With chatter detection
% mode = 2;  % With modulation, No chatter detection
% mode = 3;  % With modulation, With chatter detection

% Alternatively, use user input for mode selection
prompt = ['Select Mode:', ...
          '\n0 - No modulation, No chatter detection', ...
          '\n1 - No modulation, With chatter detection', ...
          '\n2 - With modulation, No chatter detection', ...
          '\n3 - With modulation, With chatter detection', ...
          '\nEnter mode (0, 1, 2, or 3): '];
mode = input(prompt);

% Validate input
if ~ismember(mode, [0,1,2,3])
    error('Invalid mode selected. Please choose 0, 1, 2, or 3.');
end

% -- Initialize arrays for the entire run --
all_time  = [];
all_Fx    = [];
all_Fy    = [];
all_xpos  = [];
all_ypos  = [];

% -- Create figure once, before the loop --
figure('Name','Real-Time Milling Simulation with Sine-Modulated Spindle Speed');
h1 = subplot(321);
h3 = subplot(323);
h5 = subplot(325);
h2 = subplot(322);

f2 = figure('Name','Spindle Speed');


% -- Main loop: revolve chunk by chunk --
while revs_completed < rev
    % Determine the current time to compute modulated omega
    if isempty(all_time)
        t_current = 0;
    else
        t_current = all_time(end);
    end
    
    if mode == 2 || mode == 3
        % Compute the instantaneous spindle speed with sine modulation
        omega = omega0 * (1 + RVA * sin(RVF * 2*pi/60 * omega0 * t_current + phi_phase));
    else
        % Use constant spindle speed
        omega = omega0;
    end

    % revolve 1 revolution at a time
    rev_segment = min(rev - revs_completed,1);

    %----------------------------------------
    % 1) Simulate one revolution with current omega
    [time_segment, Forcex, Forcey, xpos, ypos] = simulateOneRevolution( ...
        omega, ...
        kx, cx, mx, ...
        ky, cy, my, ...
        kt, kn, C, ...
        Nt, d, gamma, phis, phie, b, ft, ...
        revs_completed, rev_segment, t_current);
    
    %----------------------------------------
    % 2) Append the data
    all_time  = [all_time,  time_segment];
    all_Fx    = [all_Fx,    Forcex];
    all_Fy    = [all_Fy,    Forcey];
    all_xpos  = [all_xpos,  xpos];
    all_ypos  = [all_ypos,  ypos];

    %----------------------------------------
    % 3) (Optional) Check threshold → Adjust speed
    %    This section is retained in case you want to keep the chatter detection.
    %    However, with sine modulation, manual speed adjustments might interfere.
    %    Consider removing or modifying this part based on your specific needs.

    if mode == 1 || mode == 3
        if max(abs(xpos)) > x_threshold
            omega0 = omega0 + speed_increment;
            fprintf('Chatter detected! New base speed = %.2f rpm.\n', omega0);
        end
    end
    
    %----------------------------------------
    % 4) Update the figure
    %    We can just do a quick plot for each subplot
    F = sqrt(all_Fx.^2 + all_Fy.^2);

    % -- Force in X --
    subplot(h1);  % reference to the top subplot
    plot(all_time, all_Fx, '-b','LineWidth',0.8);
    ylabel('F_x (N)');
    title('Cutting Force in X-direction');
    set(gca,'FontSize', 12);
    axis([0 max(all_time) 0 2300]);

    % -- Displacement in X --
    subplot(h2);
    plot(all_time, omega, '-r','LineWidth',0.8);
    ylabel('x (\mum)');
    title('Tool Vibration in X-direction');
    set(gca,'FontSize', 12);
    axis([0 max(all_time) -1000 1000]);

    % -- Displacement in X --
    subplot(h3);
    plot(all_time, all_xpos*1e6, '-r','LineWidth',0.8);
    ylabel('x (\mum)');
    title('Tool Vibration in X-direction');
    set(gca,'FontSize', 12);
    axis([0 max(all_time) -1000 1000]);

    % -- Resultant Cutting Force --
    subplot(h5);
    plot(all_time, F, '-k','LineWidth',0.8);
    xlabel('t (s)');
    ylabel('F (N)');
    title('Resultant Cutting Force');
    set(gca,'FontSize', 12);
    axis([0 max(all_time) 0 max(F)*1.1]);

    % Force MATLAB to refresh the figure window now
    drawnow;

    %----------------------------------------
    % 5) Advance revolution counter
    revs_completed = revs_completed + rev_segment;
    pause(0.1);  % Reduced pause for smoother simulation
end

disp('Simulation complete.');

%=======================================================================
function [time_segment, Forcex, Forcey, xpos, ypos] = simulateOneRevolution( ...
    omega, ...
    kx, cx, mx, ...
    ky, cy, my, ...
    kt, kn, C, ...
    Nt, d, gamma, phis, phie, b, ft, ...
    revs_completed, rev_segment, timeStart)

    % --- We'll store the states in persistent variables so they 
    %     accumulate across calls. ---
    persistent x y x_dot y_dot dp p dq q

    if isempty(x)
       x = 0;        y = 0;
       x_dot = 0;    y_dot = 0;
       dp = zeros(size(kx));
       p  = zeros(size(kx));
       dq = zeros(size(ky));
       q  = zeros(size(ky));
    end

    % --- Highest natural frequency (approx) ---
    wnx = sqrt(kx./mx);
    wny = sqrt(ky./my);
    fnmax = max([wnx, wny]) / (2*pi);

    DT = 1/(20 * fnmax);
    steps_rev = round(60 / (omega * DT));
    steps_rev = max(steps_rev, Nt);  % Ensure at least Nt steps per revolution
    steps_tooth = round(steps_rev / Nt);
    steps_rev   = steps_tooth * Nt;
    dt          = 60 / (steps_rev * omega);

    dphi = 360 / steps_rev;
    v = pi*d*omega / 60;

    if gamma == 0
        db = b;
    else
        db = d*(dphi*pi/180)/(2*tan(gamma*pi/180));
    end
    steps_axial = round(b/db);

    steps_segment = rev_segment * steps_rev;

    Forcex = zeros(1, steps_segment);
    Forcey = zeros(1, steps_segment);
    xpos   = zeros(1, steps_segment);
    ypos   = zeros(1, steps_segment);

    % Initialize surfArray fresh for each revolution
    surfArray = zeros(steps_axial, steps_rev);

    teeth = zeros(1, Nt);
    for iT = 1:Nt
        teeth(iT) = floor((iT-1)*steps_rev/Nt) + 1;
    end

    phi_vec = (0 : dphi : (steps_rev-1)*dphi);

    for iStep = 1:steps_segment
        for iT = 1:Nt
            teeth(iT) = teeth(iT) + 1;
            if teeth(iT) > steps_rev
                teeth(iT) = 1;
            end
        end

        Fx = 0;  Fy = 0;
        for iT = 1:Nt
            for iAx = 1:steps_axial
                phi_counter = teeth(iT) - (iAx - 1);
                if phi_counter < 1
                    phi_counter = phi_counter + steps_rev;
                end
                phia = phi_vec(phi_counter);

                if (phia >= phis) && (phia <= phie)
                    n = x*sin(phia*pi/180) - y*cos(phia*pi/180);
                    n_dot = x_dot*sin(phia*pi/180) - y_dot*cos(phia*pi/180);
                    h = ft*sin(phia*pi/180) + surfArray(iAx, phi_counter) - n;
                    if h < 0
                        Ft = 0;    Fn = 0;
                        surfArray(iAx, phi_counter) = ...
                            surfArray(iAx, phi_counter) + ...
                            ft*sin(phia*pi/180);
                    else
                        Ft = kt*db*h;
                        Fn = kn*db*h - C*(db/v)*n_dot;
                        surfArray(iAx, phi_counter) = n;
                    end
                else
                    Ft = 0;  Fn = 0;
                end
                Fx = Fx + Ft*cos(phia*pi/180) + Fn*sin(phia*pi/180);
                Fy = Fy + Ft*sin(phia*pi/180) - Fn*cos(phia*pi/180);
            end
        end

        Forcex(iStep) = Fx;
        Forcey(iStep) = Fy;

        % -- Euler integration in x --
        x_tmp = 0;
        xdot_tmp = 0;
        for iMode = 1:numel(kx)
            ddp = (Fx - cx(iMode)*dp(iMode) - kx(iMode)*p(iMode))/mx(iMode);
            dp(iMode) = dp(iMode) + ddp*dt;
            xdot_tmp  = xdot_tmp + dp(iMode);
            p(iMode)  = p(iMode) + dp(iMode)*dt;
            x_tmp     = x_tmp   + p(iMode);
        end

        % -- Euler integration in y --
        y_tmp = 0;
        ydot_tmp = 0;
        for jMode = 1:numel(ky)
            ddq = (Fy - cy(jMode)*dq(jMode) - ky(jMode)*q(jMode))/my(jMode);
            dq(jMode) = dq(jMode) + ddq*dt;
            ydot_tmp  = ydot_tmp + dq(jMode);
            q(jMode)  = q(jMode) + dq(jMode)*dt;
            y_tmp     = y_tmp   + q(jMode);
        end

        x = x_tmp;      y = y_tmp;
        x_dot = xdot_tmp;  y_dot = ydot_tmp;
        xpos(iStep) = x;
        ypos(iStep) = y;
    end

    % -- Build time vector --
    time_segment = ((1:steps_segment) - 1)*dt + timeStart;
end
