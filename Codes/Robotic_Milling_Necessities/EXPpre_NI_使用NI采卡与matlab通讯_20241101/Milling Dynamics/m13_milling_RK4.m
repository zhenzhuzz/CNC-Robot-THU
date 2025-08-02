% Copyright
% Zhen Zhu
% January 5, 2025

% m13_milling_RK4.m
% Updated version with RK4 integration

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
omega0 = 8500;   % base spindle speed (rpm)
speed_increment = 50;  % rpm

% ------------------------------------------------
% Sine Modulation Parameters
RVA = 0.2;       % Ratio of modulation amplitude (<= 0.3)
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
all_omega = [];  % To store spindle speed over time

% -- Initialize arrays for internal parameters --
all_DT = [];
all_steps_rev = [];
all_steps_tooth = [];
all_dt = [];
all_dphi = [];
all_v = [];

% -- Create figure once, before the loop --
figure('Name','Real-Time Milling Simulation with Sine-Modulated Spindle Speed');
% Define subplot handles
h1 = subplot(3,2,1); % Cutting Force in X-direction
h4 = subplot(3,2,2); % Spindle Speed vs Time
h2 = subplot(3,2,3); % Tool Vibration in X-direction
h5 = subplot(3,2,4); % FFT of X Displacement
h3 = subplot(3,2,5); % Resultant Cutting Force
% h6 = subplot(3,2,6); % Optional: Empty or additional plot

% -- Define FFT Parameters --
desired_revolutions_for_fft = 5;  % Number of revolutions to include in FFT

% -- Main loop: revolve chunk by chunk --
while revs_completed < rev
    % Determine the current time to compute modulated omega
    if isempty(all_time)
        timeStart = 0;
    else
        timeStart = all_time(end);
    end
    
    if mode == 2 || mode == 3
        % Compute the instantaneous spindle speed with sine modulation
        omega = omega0 * (1 + RVA * sin(RVF * 2*pi/60 * omega0 * timeStart + phi_phase));
    else
        % Use constant spindle speed
        omega = omega0;
    end

    % revolve 1 revolution at a time
    rev_segment = min(rev - revs_completed,1);

    %----------------------------------------
    % 1) Simulate one revolution with current omega
    [time_segment, Forcex, Forcey, xpos, ypos, omega_segment, params] = simulateOneRevolution( ...
        kx, cx, mx, ...
        ky, cy, my, ...
        kt, kn, C, ...
        Nt, d, gamma, phis, phie, b, ft, ...
        revs_completed, rev_segment, timeStart, RVA, RVF, phi_phase, omega0, mode);
    
    %----------------------------------------
    % 2) Append the data
    all_time  = [all_time,  time_segment];
    all_Fx    = [all_Fx,    Forcex];
    all_Fy    = [all_Fy,    Forcey];
    all_xpos  = [all_xpos,  xpos];
    all_ypos  = [all_ypos,  ypos];
    all_omega = [all_omega, omega_segment];

    % Append internal parameters
    all_DT = [all_DT, params.DT];
    all_steps_rev = [all_steps_rev, params.steps_rev];
    all_steps_tooth = [all_steps_tooth, params.steps_tooth];
    all_dt = [all_dt, params.dt];
    all_dphi = [all_dphi, params.dphi];
    all_v = [all_v, params.v];
    
    %----------------------------------------
    % 3) (Optional) Check threshold → Adjust speed
    %    This section is retained in case you want to keep the chatter detection.
    %    However, with sine modulation, manual speed adjustments might interfere.
    %    Consider removing or modifying this part based on your specific needs.

    if mode == 1 || mode == 3
        if max(abs(xpos)) > x_threshold
            omega0 = omega0 + speed_increment;
            fprintf('Chatter! New speed = %.2f rpm.\n', omega0);
        end
    end
    
    %----------------------------------------
    % 4) Update the figure
    %    We can just do a quick plot for each subplot

    F = sqrt(all_Fx.^2 + all_Fy.^2);
    
    % -- Force in X --
    subplot(h1);  % Cutting Force in X-direction
    plot(all_time, all_Fx, '-b','LineWidth',0.8);
    ylabel('F_x (N)');
    title('Cutting Force in X-direction');
    grid on;
    set(gca,'FontSize', 12);
    axis([0 max(all_time) 0 2300]);
    
    % -- Spindle Speed --
    subplot(h4);  % Spindle Speed vs Time
    plot(all_time, all_omega, '-g','LineWidth',0.8);
    ylabel('\omega (rpm)');
    title('Spindle Speed vs Time');
    grid on;
    set(gca,'FontSize', 12);
    % Optionally, set axis limits based on modulation parameters
    min_omega = omega0 * (1 - RVA);
    max_omega = omega0 * (1 + RVA);
    axis([0 max(all_time) min_omega max_omega]);
    
    % -- Displacement in X --
    subplot(h2);
    plot(all_time, all_xpos*1e6, '-r','LineWidth',0.8);
    ylabel('x (\mum)');
    title('Tool Vibration in X-direction');
    grid on;
    set(gca,'FontSize', 12);
    axis([0 max(all_time) -1000 1000]);
    
    % -- FFT of X Displacement --
    subplot(h5);
    [f, X_f] = fourier(time_segment, xpos);
    plot(f, X_f, '-m','LineWidth',1.2);
    xlabel('Frequency (Hz)');
    ylabel('|X(f)|');
    title('FFT of X Displacement');
    grid on;
    set(gca,'FontSize', 12);
    axis([0 3000 0 max(X_f)*1.1]);
    
    % -- Resultant Cutting Force --
    subplot(h3);
    plot(all_time, F, '-k','LineWidth',0.8);
    xlabel('t (s)');
    ylabel('F (N)');
    title('Resultant Cutting Force');
    grid on;
    set(gca,'FontSize', 12);
    axis([0 max(all_time) 0 max(F)*1.1]);
    
    % Optional: Leave subplot(3,2,6) empty or add another plot
    % subplot(3,2,6);
    % plot(...); % Your additional plot here

    % Force MATLAB to refresh the figure window now
    drawnow;
    
    %----------------------------------------
    % 5) Advance revolution counter
    revs_completed = revs_completed + rev_segment;
    pause(0.05);  % Reduced pause for smoother simulation
end

disp('Simulation complete.');

%=======================================================================
function [time_segment, Forcex, Forcey, xpos, ypos, omega_segment, params] = simulateOneRevolution( ...
    kx, cx, mx, ...
    ky, cy, my, ...
    kt, kn, C, ...
    Nt, d, gamma, phis, phie, b, ft, ...
    revs_completed, rev_segment, timeStart, RVA, RVF, phi_phase, omega0, mode)

    % --- Persistent Variables ---
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

    DT = 1/(20 * fnmax);  % Adjusted for higher accuracy with RK4
    steps_rev = round(60 / (omega0 * DT));
    steps_rev = max(steps_rev, 2000);  % Ensure at least 1000 steps per revolution
    steps_tooth = round(steps_rev / Nt);
    steps_rev   = steps_tooth * Nt;
    dt          = 60 / (steps_rev * omega0);

    dphi = 360 / steps_rev;
    v = pi*d*omega0 / 60;

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
    omega_segment = zeros(1, steps_segment);  % To store omega at each step

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

        % Compute current time
        current_time = timeStart + ((iStep-1)*dt);

        % Compute omega based on mode and modulation
        if mode == 2 || mode == 3
            omega = omega0 * (1 + RVA * sin(RVF * 2*pi/60 * omega0 * current_time + phi_phase));
        else
            omega = omega0;
        end
        omega_segment(iStep) = omega;

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

        % ----- RK4 Integration for x-direction -----
        [dp_new, p_new, x_dot_new, x_new] = RK4_RK4(x, dp, p, Fx, cx, kx, mx, dt);

        % ----- RK4 Integration for y-direction -----
        [dq_new, q_new, y_dot_new, y_new] = RK4_RK4(y, dq, q, Fy, cy, ky, my, dt);

        % Update persistent variables
        dp = dp_new;
        p = p_new;
        x_dot = x_dot_new;
        x = x_new;

        dq = dq_new;
        q = q_new;
        y_dot = y_dot_new;
        y = y_new;

        xpos(iStep) = x;
        ypos(iStep) = y;
    end


    % -- Build time vector --
    time_segment = ((1:steps_segment) - 1)*dt + timeStart;
    
    % -- Assign internal variables to the params structure --
    params.DT = DT;
    params.steps_rev = steps_rev;
    params.steps_tooth = steps_tooth;
    params.dt = dt;
    params.dphi = dphi;
    params.v = v;
end

%=======================================================================
function [dp_new, p_new, x_dot_new, x_new] = RK4_RK4(x, dp, p, F, c, k, m, dt)
    % RK4_RK4 Performs RK4 integration for displacement and velocity
    %
    % Inputs:
    %   x      - Current displacement (scalar, sum across modes)
    %   dp     - Current velocity vector (dp/dt for each mode)
    %   p      - Current displacement vector (p for each mode)
    %   F      - Current force
    %   c      - Damping coefficients vector
    %   k      - Stiffness coefficients vector
    %   m      - Masses vector
    %   dt     - Time step
    %
    % Outputs:
    %   dp_new      - Updated velocity vector
    %   p_new       - Updated displacement vector
    %   x_dot_new   - Updated total velocity (scalar, sum across modes)
    %   x_new       - Updated total displacement (scalar, sum across modes)

    % Define the derivative function for each mode
    dFdt = (F - c .* dp - k .* p) ./ m;

    % Compute k1
    k1_p = dp;
    k1_dp = dFdt;

    % Compute k2
    p_temp = p + 0.5 * dt * k1_p;
    dp_temp = dp + 0.5 * dt * k1_dp;
    dFdt_k2 = (F - c .* dp_temp - k .* p_temp) ./ m;
    k2_p = dp_temp;
    k2_dp = dFdt_k2;

    % Compute k3
    p_temp = p + 0.5 * dt * k2_p;
    dp_temp = dp + 0.5 * dt * k2_dp;
    dFdt_k3 = (F - c .* dp_temp - k .* p_temp) ./ m;
    k3_p = dp_temp;
    k3_dp = dFdt_k3;

    % Compute k4
    p_temp = p + dt * k3_p;
    dp_temp = dp + dt * k3_dp;
    dFdt_k4 = (F - c .* dp_temp - k .* p_temp) ./ m;
    k4_p = dp_temp;
    k4_dp = dFdt_k4;

    % Update displacement and velocity vectors
    p_new = p + (dt / 6) * (k1_p + 2*k2_p + 2*k3_p + k4_p);
    dp_new = dp + (dt / 6) * (k1_dp + 2*k2_dp + 2*k3_dp + k4_dp);

    % Compute total displacement and velocity by summing across all modes
    x_new = sum(p_new);
    x_dot_new = sum(dp_new);
end
