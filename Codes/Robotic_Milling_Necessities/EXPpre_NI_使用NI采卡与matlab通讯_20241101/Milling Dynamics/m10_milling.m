% Copyright
% Zhen Zhu
% January 5, 2025

% m10_milling_fig.m
% Demonstrates how to update the figure at each revolution.
clear;
clc;
close all;

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
cx = 2 * zetax .* (mx .* kx).^(0.5);  % N-s/m

% ------------------------------------------------
% Define modal parameters for y direction
ky = [9e6];             % N/m
zetay = [0.03];
wny = [900] * 2*pi;     % rad/s
my = ky ./ (wny.^2);    % kg
cy = 2 * zetay .* (my .* ky).^(0.5);  % N-s/m

% ------------------------------------------------
% Define cutting parameters
Nt = 3;          % number of teeth
d = 19e-3;       % teeth diameter (m)
gamma = 30;      % helix angle (deg)
phis = 0;        % start angle (deg)
phie = 90;       % exit angle (deg)
ft = 0.1e-3;     % feed per tooth (m)
b = 3e-3;        % axial depth of cut (m)
omega = 8500;           % rpm
speed_increment = 50;  % rpm

% ------------------------------------------------
% Vibration threshold
x_threshold = 3e-4;     % (m), e.g. 300 microns

% ------------------------------------------------
% Total number of revolutions
rev = 20;               
revs_completed = 0;


% -- Initialize arrays for the entire run --
all_time  = [];
all_Fx    = [];
all_Fy    = [];
all_xpos  = [];
all_ypos  = [];

% -- Create figure once, before the loop --
figure('Name','Real-Time Milling Simulation');
h1 = subplot(311);
h2 = subplot(312);
h3 = subplot(313);

% -- Main loop: revolve chunk by chunk --
while revs_completed < rev
    % revolve 1 revolution at a time
    rev_segment = min(rev - revs_completed,1);

    %----------------------------------------
    % 1) Simulate one revolution
    [time_segment, Forcex, Forcey, xpos, ypos] = simulateOneRevolution( ...
        omega, ...
        kx, cx, mx, ...
        ky, cy, my, ...
        kt, kn, C, ...
        Nt, d, gamma, phis, phie, b, ft, ...
        revs_completed, rev_segment);

    %----------------------------------------
    % 2) Append the data
    all_time  = [all_time,  time_segment];
    all_Fx    = [all_Fx,    Forcex];
    all_Fy    = [all_Fy,    Forcey];
    all_xpos  = [all_xpos,  xpos];
    all_ypos  = [all_ypos,  ypos];

    %----------------------------------------
    % 3) Check threshold → Adjust speed
    if max(abs(xpos)) > x_threshold
        % omega = omega + speed_increment;
        disp(['Chatter! New speed = ', ...
              num2str(omega),' rpm.']);
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
    plot(all_time, all_xpos*1e6, '-r','LineWidth',0.8);
    ylabel('x (\mum)');
    title('Tool Vibration in X-direction');
    set(gca,'FontSize', 12);
    axis([0 max(all_time) -1000 1000]);

    % -- Resultant Cutting Force --
    subplot(h3);
    plot(all_time, F, '-k','LineWidth',0.8);
    xlabel('t (s)');
    ylabel('F (N)');
    title('Resultant Cutting Force');
    set(gca,'FontSize', 12);

    % Force MATLAB to refresh the figure window now
    drawnow;

    %----------------------------------------
    % 5) Advance revolution counter
    revs_completed = revs_completed + rev_segment;
    pause(0.1);
end

disp('Simulation complete.');


%=======================================================================
function [time_segment, Forcex, Forcey, xpos, ypos] = simulateOneRevolution( ...
    omega, ...
    kx, cx, mx, ...
    ky, cy, my, ...
    kt, kn, C, ...
    Nt, d, gamma, phis, phie, b, ft, ...
    revs_completed, rev_segment)

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
    steps_rev = 60 / (omega * DT);
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

    surfArray = zeros(steps_axial, steps_rev);

    teeth = zeros(1, Nt);
    for iT = 1:Nt
        teeth(iT) = (iT-1)*steps_rev/Nt + 1;
    end

    phi = (0 : dphi : (steps_rev-1)*dphi);

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
                phia = phi(phi_counter);

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
    timeStart = (revs_completed) * (60 / omega);
    time_segment = ((1:steps_segment) - 1)*dt + timeStart;
end
