%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%_CHARTTER VIBRATION ANALYSIS IN THIN WALL MILLING_%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all
% format
format compact

%% Variable declaration

global omega_nx omega_ny xi_x xi_y Kt Kr kx ky a N Z T theta time theta_entry theta_exit mx my fz f 
global f1 c1 k1 f2 c2 k2 f1_sum f2_sum state
global A_fx omega_fx phi_fx A_fy omega_fy phi_fy % Added for external forces

% Cutting Force Parameters
Kt = 600; % tangential cutting coefficient (N/mm or appropriate unit)
Kr = 0.2; % radial cutting coefficient (unitless or appropriate unit)

% Damping Ratios
xi_x = 0.131; % damping ratio in x direction
xi_y = 0.131; % damping ratio in y direction

% Natural Frequencies (converted to rad/s if originally in Hz)
omega_nx = 2 * pi * 641; % natural frequency in rad/s (x component)
omega_ny = 2 * pi * 641; % natural frequency in rad/s (y component)

% Stiffness (N/m)
kx = 3.258e6; % stiffness in X (N/m)
ky = 3.327e6; % stiffness in Y (N/m)

% Modal Mass Calculation
mx = kx / omega_nx^2;
my = ky / omega_ny^2;

% Milling Parameters
a = 3e-3; % axial depth of cut, ADOC in meters (converted from mm)
N = 4250; % rpm
Z = 3; % number of teeth on cutter
T = 60/(N*Z); % tooth passing period in seconds
f_rev = 0.1; % feed per rev, mm/rev
f_rev = f_rev / 1000; % convert to meters/rev
f = f_rev * N; % feed rate in meters/min
f = f / 60; % convert to meters/second
fz = f_rev / Z; % feed per tooth in meters/tooth

lags = [T T]; % time lags for DDE equal to tooth passing period

tf = 1; % total time of simulation in seconds

% External Force Parameters
A_fx = 10;            % Amplitude of external force in X (N)
omega_fx = 2 * pi * 100; % Frequency of external force in X (rad/s)
phi_fx = 0;           % Phase of external force in X (rad)

A_fy = 5;             % Amplitude of external force in Y (N)
omega_fy = 2 * pi * 100; % Frequency of external force in Y (rad/s)
phi_fy = pi/4;        % Phase of external force in Y (rad)

theta = 0; % instantaneous theta initialized
theta_entry = 0 * pi / 180; % in radians
theta_exit = 90 * pi / 180; % in radians
x = 0;
y = 0;

state = 0; % represents time in steps of tooth passing time
state_idx = 0;
time = linspace(0, tf, 10000); % in seconds

%% First calculation

f1_sum = 0;
f2_sum = 0;
fprintf('################ Simulation begins ################\n');
for tooth = 1:Z
    theta = 2 * pi * N * state / 60 + Z * 2 * pi / N;
    fprintf('< %d >-----', tooth);
    engagement = g(theta);
    f1 = (Kt * Kr * a * (-sin(theta)) + Kt * a * (-cos(theta))) * engagement;
    f2 = (Kt * Kr * a * (-cos(theta)) + Kt * a * (sin(theta))) * engagement;

    f1_sum = f1 + f1_sum;
    f2_sum = f2 + f2_sum;
end

c1 = -2 * xi_x * omega_nx;
k1 = -omega_nx^2;

c2 = -2 * xi_y * omega_ny;
k2 = -omega_ny^2;

options = ddeset('Event', @ChtrEvents); % custom trigger event is set
state = state + T;
state_idx = state_idx + 1;
sol = dde23(@ddefunc, lags, @yhist, [0 tf], options);

%% Simulation calculations till final time
tolerance = 1e-6;

while (tf - sol.x(end)) > tolerance
    state = state + T;
    state_idx = state_idx + 1;

    fprintf('\n______________Integration Restart at %5.6f_____________\n', sol.x(end));
    fprintf('state value after this cycle = %f \n', state);

    f1_sum = 0;
    f2_sum = 0;

    for tooth = 1:Z
        theta = 2 * pi * N * state / 60 + (tooth - 1) * 2 * pi / Z;
        fprintf('< %d >-----', tooth);
        engagement = g(theta);
        f1 = (Kt * Kr * a * (-sin(theta)) + Kt * a * (-cos(theta))) * engagement;
        f2 = (Kt * Kr * a * (-cos(theta)) + Kt * a * (sin(theta))) * engagement;

        f1_sum = f1 + f1_sum;
        f2_sum = f2 + f2_sum;
    end

    c1 = -2 * xi_x * omega_nx;
    k1 = -omega_nx^2;

    c2 = -2 * xi_y * omega_ny;
    k2 = -omega_ny^2;

    % Calculating the solution with external forces included
    sol = dde23(@ddefunc, lags, sol, [sol.x(end) tf], options);
end
fprintf('\n******************Simulation Done******************\n\n');

%% Roughness calculations

Ray = 0; % avg. roughness y direction
for i = 1:length(sol.x)
    itr = i - 1;
    if itr == 0
        prevTime = 0;
    else
        prevTime = sol.x(itr);
    end
    Ray = Ray + abs(sol.y(1, i)) * (sol.x(i) - prevTime) / tf;
end

% Average Roughness in Y direction
fprintf('Average Roughness Ra\n');
fprintf('Ra_y = %f μm\n', Ray * 1e6);

Rax = 0; % avg. roughness x direction
for i = 1:length(sol.x)
    itr = i - 1;
    if itr == 0
        prevTime = 0;
    else
        prevTime = sol.x(itr);
    end
    Rax = Rax + abs(sol.y(3, i)) * (sol.x(i) - prevTime) / tf;
end

% Average Roughness in X direction
fprintf('Ra_x = %f μm\n\n', Rax * 1e6);

Rqy = 0; % rms roughness y direction
for i = 1:length(sol.x)
    itr = i - 1;
    if itr == 0
        prevTime = 0;
    else
        prevTime = sol.x(itr);
    end
    Rqy = Rqy + ((sol.y(1, i))^2) * (sol.x(i) - prevTime) / tf;
end
Rqy = sqrt(Rqy);
% Root mean square Roughness in Y direction
fprintf('Root mean square Roughness Rq\n');
fprintf('Rq_y = %f μm\n', Rqy * 1e6);

Rqx = 0; % rms roughness x direction
for i = 1:length(sol.x)
    itr = i - 1;
    if itr == 0
        prevTime = 0;
    else
        prevTime = sol.x(itr);
    end
    Rqx = Rqx + ((sol.y(3, i))^2) * (sol.x(i) - prevTime) / tf;
end
Rqx = sqrt(Rqx);
% Root mean square Roughness in X direction
fprintf('Rq_x = %f μm\n\n', Rqx * 1e6);

Rty = max(sol.y(1, :)) - min(sol.y(1, :));
Rtx = max(sol.y(3, :)) - min(sol.y(3, :));

% Total height of profile
fprintf('Total height of profile\n');
fprintf('Rt_y = %f μm\n', Rty * 1e6);
fprintf('Rt_x = %f μm\n\n', Rtx * 1e6);

%% Amplitude plots - Combined graph

figure
subplot(2,1,1)
plot(sol.x, sol.y(1, :) * 1e6);
title('Amplitude variation in Y direction')
set(gca, 'FontSize', 14);
ylabel('y displacement (\mum)');
xlabel('Time (s)');

subplot(2,1,2)
plot(sol.x, sol.y(3, :) * 1e6);
title('Amplitude variation in X direction')
set(gca, 'FontSize', 14);
ylabel('x displacement (\mum)');
xlabel('Time (s)');

%% Tool Path vs Vibration Plot

% Parameters for tool path
feed_rate_per_second = f;  % meters/second

% Compute the tool path step for each time increment
tool_path_step = [0, diff(sol.x)] * feed_rate_per_second;  % Vector of tool path increments

% Initialize tool position array and accumulate positions
tool_position_x = zeros(1, length(sol.x));  % Initialize tool positions (X-direction)
tool_position_x(2:end) = cumsum(tool_path_step);  % Accumulate the tool path from the feed steps

% Now, plot the tool path (X) vs tool vibration (Y)
figure;
plot(tool_position_x * 1000, sol.y(1, :) * 1e6);  % Convert X to mm and Y to microns
title('Tool Vibration (Y-displacement) along the Tool Path (X)');
xlabel('Tool Path (mm)');
ylabel('Tool Y-displacement (\mum)');
grid on;

%% Function declarations

function yp = ddefunc(t, y, YL)
    global theta c1 k1 f1_sum fz mx c2 k2 f2_sum my
    global A_fx omega_fx phi_fx A_fy omega_fy phi_fy % Added for external forces

    yl1 = YL(:,1); % lag on y
    yl2 = YL(:,2); % lag on x
    y1 = y(1);     % y displacement
    y2 = y(2);     % y velocity
    x1 = y(3);     % x displacement
    x2 = y(4);     % x velocity

    % External Forces
    Fx = A_fx * sin(omega_fx * t + phi_fx); % External force in X
    Fy = A_fy * sin(omega_fy * t + phi_fy); % External force in Y

    % Dynamic Equations
    yp = [
        y2;
        c2 * y2 + k2 * y1 + (f2_sum * fz * sin(theta) + f2_sum * (x1 - yl2(2)) * sin(theta) + f2_sum * (y1 - yl1(1)) * cos(theta)) / my + Fy / my;
        x2;
        c1 * x2 + k1 * x1 + (f1_sum * fz * sin(theta) + f1_sum * (x1 - yl2(2)) * sin(theta) + f1_sum * (y1 - yl1(1)) * cos(theta)) / mx + Fx / mx
    ];
end

function y = yhist(t)
    % Initial history function: zero initial displacements and velocities
    y = [0; 0; 0; 0]';
end

function [value, isterminal, direction] = ChtrEvents(t, y, YL)
    global state
    epsilon = 1e-6; % Define a small tolerance
    value = state - t;
    isterminal = 1;
    direction = 0;
    if abs(state - t) < epsilon
        fprintf('Event triggered at t = %f. Integration terminated.\n', t);
    end
end

function intermittent_check = g(theta)
    global theta_entry theta_exit
    % Uncomment the following lines for debugging
    % fprintf('theta = %5.10f\n', theta);
    % fprintf('theta in 0 to 2pi: %4.4f \n', mod(theta, 2*pi));
    
    if (theta_entry < mod(theta, 2*pi)) && (mod(theta, 2*pi) < theta_exit)
        intermittent_check = 1;
        % Uncomment for debugging
        % fprintf('tooth engaged\n');
    else
        intermittent_check = 0;
        % Uncomment for debugging
        % fprintf('tooth is free\n');
    end
end
