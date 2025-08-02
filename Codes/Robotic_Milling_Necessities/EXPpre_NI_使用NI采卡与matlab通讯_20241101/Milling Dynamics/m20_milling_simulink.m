% m20_milling_simulink.m
% Copyright
% Zhen Zhu
% January 5, 2025
%
% This script demonstrates a refactored approach to your original milling.m,
% preparing it for easy conversion into a Simulink model.


clc
close all
clear

% STEP 1: Initialize model parameters
% In Simulink, these become tunable parameters or a Bus for parameter data.
params = initMillingParameters();

% STEP 2: Initialize states
% In Simulink, these might become discrete states or Data Store Memory.
states = initMillingStates(params);

% STEP 3: Pre-allocate storage for logging (optional in Simulink).
logger = initLogger(params);

% STEP 4: Main simulation loop
% In Simulink, you'd typically let the solver handle time stepping
% rather than manually looping. This loop is for illustration only.
handle = waitbar(0, 'Please wait... simulation in progress.');
for stepCount = 1:params.totalSteps
    waitbar(stepCount/params.totalSteps, handle);

    % 4A: Update tooth angles (could be a separate block in Simulink).
    states = updateTeeth(states, params);

    % 4B: Calculate cutting forces. In Simulink, this is likely a
    %     MATLAB Function block or System object that reads states and
    %     parameters, then outputs forces.
    [Fx, Fy, updatedSurf] = computeCuttingForces(states, params);

    % 4C: Integrate the structural dynamics. Another block in Simulink.
    states = integrateDynamics(states, Fx, Fy, params);

    % 4D: Log results
    logger.Forcex(stepCount) = Fx;
    logger.Forcey(stepCount) = Fy;
    logger.xpos(stepCount)   = states.x;
    logger.ypos(stepCount)   = states.y;
    logger.xvel(stepCount)   = states.x_dot;
    logger.yvel(stepCount)   = states.y_dot;

    % 4E: Update the surface array for next iteration
    states.surf = updatedSurf;
end
close(handle);

% STEP 5: Plot results (maps to Simulink sinks or scope blocks).
plotResults(states, logger, params);


% -------------------------------------------------------------------------
% Subfunction to initialize parameters
% This would map to a Bus or constant parameters in Simulink.
function params = initMillingParameters()

    % Define cutting force coefficients
    params.Ks   = 2000e6;  % N/m^2
    params.beta = 70;      % deg
    params.kt   = params.Ks * sin(params.beta*pi/180);
    params.kn   = params.Ks * cos(params.beta*pi/180);
    params.C    = 0;       % N/m

    % Define modal parameters for x direction
    params.kx    = 9e6;          % N/m
    params.zetax = 0.03;
    params.wnx   = 900 * 2*pi;   % rad/s
    params.mx    = params.kx / (params.wnx^2); % kg
    params.cx    = 2 * params.zetax * sqrt(params.mx*params.kx);

    % Define modal parameters for y direction
    params.ky    = 9e6;          % N/m
    params.zetay = 0.03;
    params.wny   = 900 * 2*pi;   % rad/s
    params.my    = params.ky / (params.wny^2); % kg
    params.cy    = 2 * params.zetay * sqrt(params.my*params.ky);

    % Define cutting parameters
    params.Nt   = 3;         % Number of teeth
    params.d    = 19e-3;     % teeth diameter, m
    params.gamma = 30;       % helix angle, deg
    params.phis = 0;         % deg
    params.phie = 90;        % deg
    params.omega = 250;      % rpm
    params.b    = 3e-3;      % axial depth of cut, m
    params.ft   = 0.1e-3;    % feed per tooth, m
    params.v    = pi*params.d*params.omega/60; % m/s

    % Simulation specifications
    fnmax  = max([params.wnx params.wny])/(2*pi);  
    DT     = 1/(25*fnmax);
    steps_rev  = 60/(params.omega*DT);
    steps_tooth = round(steps_rev / params.Nt);
    steps_rev   = steps_tooth * params.Nt;
    params.dt   = 60/(steps_rev*params.omega);
    params.dphi = 360/steps_rev;

    if params.gamma == 0
        db = params.b;
    else
        db = params.d * (params.dphi*pi/180) / (2 * tan(params.gamma*pi/180));
    end

    params.steps_axial = round(params.b/db);
    params.rev         = 20;                     % total revolutions
    params.steps_rev   = steps_rev;              % steps per rev
    params.totalSteps  = params.rev * steps_rev; % total steps of simulation

    % Angles for one revolution
    params.phi = (0 : params.dphi : 360 - params.dphi); 

end


% -------------------------------------------------------------------------
% Subfunction to initialize states
% In Simulink, these become discrete states or DSM (Data Store Memory).
function states = initMillingStates(params)

    % Indices for each tooth
    states.teeth = zeros(1, params.Nt);
    for cnt = 1:params.Nt
        states.teeth(cnt) = (cnt-1)*params.steps_rev/params.Nt + 1;
    end

    % Initialize geometry array
    states.surf = zeros(params.steps_axial, params.steps_rev);

    % Initial conditions for structural dynamics
    states.x      = 0;
    states.y      = 0;
    states.x_dot  = 0;
    states.y_dot  = 0;

    % For single-mode x and y as in your script
    states.p  = 0;  % displacement in x-mode
    states.dp = 0;  % velocity in x-mode
    states.q  = 0;  % displacement in y-mode
    states.dq = 0;  % velocity in y-mode

end

% -------------------------------------------------------------------------
% Subfunction to initialize logger arrays
function logger = initLogger(params)

    logger.Forcex = zeros(1, params.totalSteps);
    logger.Forcey = zeros(1, params.totalSteps);
    logger.xpos   = zeros(1, params.totalSteps);
    logger.ypos   = zeros(1, params.totalSteps);
    logger.xvel   = zeros(1, params.totalSteps);
    logger.yvel   = zeros(1, params.totalSteps);

end

% -------------------------------------------------------------------------
% Subfunction to update tooth angles
% In Simulink, this might be part of the main step or a separate subsystem.
function states = updateTeeth(states, params)
    for cnt2 = 1:params.Nt
        states.teeth(cnt2) = states.teeth(cnt2) + 1;
        if states.teeth(cnt2) > params.steps_rev
            states.teeth(cnt2) = 1;
        end
    end
end

% -------------------------------------------------------------------------
% Subfunction to compute cutting forces
% Could be a MATLAB Function block or System object in Simulink
function [Fx, Fy, updatedSurf] = computeCuttingForces(states, params)

    Fx = 0;
    Fy = 0;
    updatedSurf = states.surf;  % local copy to update

    % Expand x, y, x_dot, y_dot for readability
    x     = states.x;
    y     = states.y;
    x_dot = states.x_dot;
    y_dot = states.y_dot;

    for cnt3 = 1:params.Nt
        for cnt4 = 1:params.steps_axial
            phi_counter = states.teeth(cnt3) - (cnt4 - 1);
            if phi_counter < 1
                phi_counter = phi_counter + params.steps_rev;
            end

            phia = params.phi(phi_counter);  % deg

            if (phia >= params.phis) && (phia <= params.phie)
                n      = x*sin(phia*pi/180) - y*cos(phia*pi/180);
                n_dot  = x_dot*sin(phia*pi/180) - y_dot*cos(phia*pi/180);
                h      = params.ft*sin(phia*pi/180) + updatedSurf(cnt4, phi_counter) - n;
                if h < 0
                    Ft = 0;
                    Fn = 0;
                    updatedSurf(cnt4, phi_counter) = ...
                        updatedSurf(cnt4, phi_counter) + params.ft*sin(phia*pi/180);
                else
                    Ft = params.kt * h * axialDiskHeight(params, phia);
                    Fn = params.kn * h * axialDiskHeight(params, phia) ...
                         - params.C * axialDiskHeight(params, phia) ...
                         * (1/params.v) * n_dot;
                    updatedSurf(cnt4, phi_counter) = n;
                end
            else
                Ft = 0;
                Fn = 0;
            end

            Fx = Fx + Ft*cos(phia*pi/180) + Fn*sin(phia*pi/180);
            Fy = Fy + Ft*sin(phia*pi/180) - Fn*cos(phia*pi/180);
        end
    end
end

% Helper to compute axial disk height (db) as a function of helix, etc.
% In your original code, db is constant along the axial steps,
% but this function might be extended for variable helix.
function db_val = axialDiskHeight(params, ~)
    if params.gamma == 0
        db_val = params.b;
    else
        db_val = params.d * (params.dphi*pi/180) / (2 * tan(params.gamma*pi/180));
    end
end


% -------------------------------------------------------------------------
% Subfunction to integrate structural dynamics
% Could be a MATLAB Function block or System object with discrete states.
function states = integrateDynamics(states, Fx, Fy, params)

    % x direction integration
    ddp       = (Fx - params.cx*states.dp - params.kx*states.p) / params.mx;
    states.dp = states.dp + ddp * params.dt;
    states.x_dot = states.dp;  % velocity contribution
    states.p  = states.p + states.dp * params.dt;
    states.x  = states.p;      % total x displacement

    % y direction integration
    ddq       = (Fy - params.cy*states.dq - params.ky*states.q) / params.my;
    states.dq = states.dq + ddq * params.dt;
    states.y_dot = states.dq;  % velocity contribution
    states.q  = states.q + states.dq * params.dt;
    states.y  = states.q;      % total y displacement

end

% -------------------------------------------------------------------------
% Subfunction to plot final results
% In Simulink, you might use scope blocks or to-workspace blocks.
function plotResults(states, logger, params)

    time = ((1:params.totalSteps)-1) * params.dt;  % s
    Fx = logger.Forcex;
    Fy = logger.Forcey;
    F  = sqrt(Fx.^2 + Fy.^2);

    figure(1)
    subplot(2,1,1)
    plot(time, Fx)
    axis([0 max(time) 0 2300])
    set(gca,'FontSize', 14)
    ylabel('F_x (N)')

    subplot(2,1,2)
    plot(time, logger.xpos*1e6)
    axis([0 max(time) -1000 1000])
    set(gca,'FontSize', 14)
    xlabel('t (s)')
    ylabel('x (\mum)')

    figure(2)
    subplot(2,1,1)
    plot(time, Fy)
    xlim([0 max(time)])
    set(gca,'FontSize', 14)
    ylabel('F_y (N)')

    subplot(2,1,2)
    plot(time, logger.ypos*1e6)
    xlim([0 max(time)])
    set(gca,'FontSize', 14)
    xlabel('t (s)')
    ylabel('y (\mum)')

    figure(3)
    plot(time, F)
    xlim([0 max(time)])
    set(gca,'FontSize', 14)
    xlabel('t (s)')
    ylabel('F (N)')

end
