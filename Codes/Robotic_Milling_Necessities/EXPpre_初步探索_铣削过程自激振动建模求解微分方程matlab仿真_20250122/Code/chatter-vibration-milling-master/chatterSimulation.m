%% Milling Cutting Simulation 
% Based on code by Schmitz and Smith

% function [t, F, Fx, Fy, x, y, RevStep] = ForceSimulation(rpm, AxialDepth, RevDes, tmin) 

%% Inputs for ForceSimulation
clear;
clc;

rpm = 5000;                 % Spindle Speed (rpm)
AxialDepth = 2 * 1e-3;        % Axial Depth (m)
RevDes = 25;                 % Desired number of revolutions to analyze
tmin = 0.5;                  % Minimum simulation time (sec)

%% Setup Cutting Conditions
NT = 3;                      % Number of teeth
% Feedrate = .798e-3;         % (m/min)
% FeedperTooth = Feedrate / (rpm * NT);  % Feed per tooth (m/tooth)
avgChip = 0.002 * 0.0254;    % Average chip thickness (m)

%   *** Look below for this code *** 
% FeedperTooth = avgChip*(StartAngle-EndAngle)*(pi/180)/...  
%     (cosd(EndAngle)-cosd(StartAngle)); % (m/tooth) 
% FeedperTooth = .15e-3; % (m/tooth) 

% Tool Parameters
ToolDiameter = 12 * 1e-3;     % Tool diameter in meters
HelixAngle = 17.869;              % Helix angle in degrees
RO = zeros(1, NT) * 1e-6;         % Tooth-to-tooth runout (m)
% RO = [5 -25 0]*1e-6; 
RadialDepth = ToolDiameter * 1; % Radial Depth in meters
CuttingType = 2;                  % 1: Down Milling, 2: Up Milling

%% Cutting Coefficients
% Ks = 600e6;     % N/m^2 
% beta = 60;      % deg 
% Ktc = Ks*sin(beta*pi/180);      % (N/m^2) 
% Krc = Ks*cos(beta*pi/180);      % (N/m^2) 
% Kte = 0;     % (N/m) 
% Kre = 0;     % (N/m) 

% Steel
% Ktc = 1738e6;   % (N/m^2)
% Krc = 584e6;    % (N/m^2)
% Kte = 62e3;     % (N/m)
% Kre = 87e3;     % (N/m)

% Aluminum
Ktc = 600e6;    % Tangential cutting force coefficient (N/m^2)
Krc = 120e6;    % Radial cutting force coefficient (N/m^2)
Kte = 20e3;     % Tangential edge force coefficient (N/m)
Kre = 19e3;     % Radial edge force coefficient (N/m)

% Aluminum (Koh) 
% Ktc = 688.0e6;    % (N/m^2) 
% Krc = 229.4e6;    % (N/m^2) 
% Kte = 17.2e3;     % (N/m) 
% Kre = 10.5e3;     % (N/m) 

% Aluminum (Zhao) Valid for .002 to .004 in. 
% Ktc = 820e6;    % (N/m^2)
% Krc = 280e6;    % (N/m^2)
% Kte = 19e3;     % (N/m)
% Kre = 12e3;     % (N/m)

%% Time Parameters
TimeStepDes = 1e-5;                % Desired time step (s)
RevStep = floor(60 / (rpm * TimeStepDes));  % Number of steps per revolution
TimeStep = 60 / (rpm * RevStep);   % Actual time step (s)
TimeEnd = tmin + (RevDes * RevStep * TimeStep);  % End time for simulation
t = 0:TimeStep:TimeEnd;            % Time vector
dphi = 360 / RevStep;              % Angular increment per step (deg)

ToolRadius = ToolDiameter / 2;     % Tool radius (m)

% Lag Angle Calculation
LagAngle = asin((AxialDepth * tan(HelixAngle * pi / 180)) / ToolRadius) * 180 / pi;

%% Determine Start and End Angles Based on Cutting Type
% For slot cutting, it does not matter whether type 1 or 2.
% First quadrant: +X & +Y, clockwise rotation

if CuttingType == 1
    StartAngle = 180 - acos((ToolRadius - RadialDepth) / ToolRadius) * 180 / pi;
    EndAngle = 180;
elseif CuttingType == 2
    StartAngle = 0;
    EndAngle = acos((ToolRadius - RadialDepth) / ToolRadius) * 180 / pi;
else
    disp('---Wrong Cutting Type---');
    return;
end

% Adjust end angle based on helix lag
ActualEndAngle = EndAngle + LagAngle;

% Calculate Feed per Tooth
FeedperTooth = -avgChip * (EndAngle - StartAngle) * (pi / 180) / ...
               (cosd(EndAngle) - cosd(StartAngle)); % Feed per tooth (m/tooth)
%% Model start up 
% Define modal parameters for x direction (single mode)
% kx = 8e6;                   % Stiffness in x direction (N/m)
% zetax = .02; 
% wnx = 500*2*pi;             % Natural frequency in x direction (rad/s)
% kx = [2e7 1.5e7];           % N/m
% zetax = [0.05 0.03]; 
% wnx = [800 1000] * 2 * pi;  % rad/s

% Smart tool
% kx = [1.21e6 2.02e6];       % N/m
% zetax = [.099 .043]; 
% wnx = [628 1104] * 2 * pi;  % rad/s

% Smart tool single mode
kx = 3.258e6;                % Stiffness in x direction (N/m)
zetax = 0.131;               % Damping ratio in x direction
wnx = 641 * 2 * pi;          % Natural frequency in x direction (rad/s)
mx = kx / (wnx^2);           % Modal mass in x direction (kg)
cx = 2 * zetax * sqrt(mx * kx);  % Damping coefficient in x direction (N-s/m)
x_modes = length(kx);        % Number of modes in x direction

% Define modal parameters for y direction (single mode)
% ky = 8e6;                   % Stiffness in y direction (N/m)
% zetay = .02; 
% wny = 500 * 2 * pi;         % Natural frequency in y direction (rad/s)
% ky = [2e7 1.5e7];           % N/m
% zetay = [0.05 0.03]; 
% wny = [800 1000] * 2 * pi;  % rad/s

% Smart tool
% ky = [1.22e6 2.62e6];       % N/m
% zetay = [.110 .041]; 
% wny = [620 1328] * 2 * pi;  % rad/s

% Smart tool single mode
ky = 3.327e6;                % Stiffness in y direction (N/m)
zetay = 0.131;               % Damping ratio in y direction
wny = 641 * 2 * pi;          % Natural frequency in y direction (rad/s)
my = ky / (wny^2);           % Modal mass in y direction (kg)
cy = 2 * zetay * sqrt(my * ky);  % Damping coefficient in y direction (N-s/m)
y_modes = length(ky);        % Number of modes in y direction


%% Interate model through time 
for i = 1:length(t)
    
    if t(i) == 0  % Time = 0, Initial values set
        phi = 0:dphi:(360 - dphi);
        p = zeros(x_modes, length(t));
        dp = zeros(x_modes, length(t));
        q = zeros(x_modes, length(t));
        dq = zeros(x_modes, length(t));
        x = zeros(1, length(t));
        y = zeros(1, length(t));

        % Set axial depth based on helix angle
        if HelixAngle == 0
            da = AxialDepth;  % Axial depth in m
        else
            % Discretized axial depth [m]
            da = ToolDiameter * (dphi * pi / 180) / (2 * tan(HelixAngle * pi / 180));
        end
        AxialStep = round(AxialDepth / da);
        surf = zeros(AxialStep, RevStep);  % Surface discretization
        Fx = zeros(1, length(t));  % Force in x-direction
        Fy = zeros(1, length(t));  % Force in y-direction
        F = zeros(1, length(t));   % Resultant force

        % Initialize tooth positions
        teeth = zeros(1, 4);
        if NT > 1
            for cnt = 2:NT
                teeth(cnt) = teeth(cnt - 1) + floor(RevStep / NT); % Tooth angular positions
                if teeth(cnt) > RevStep
                    teeth(cnt) = teeth(cnt) - RevStep;
                end
            end
        end

    else  % Time > 0, Iterate through time
        
        %%%%%%%%%%%%%%%%%%%%%%%% Simulation %%%%%%%%%%%%%%%%%%%%%%%%
        % Update teeth positions
        for cnt2 = 1:NT
            teeth(cnt2) = teeth(cnt2) + 1;
            if teeth(cnt2) > RevStep
                teeth(cnt2) = teeth(cnt2) - RevStep;
            end
        end

        % Cycle through all teeth and axial steps
        for cnt3 = 1:NT
            for cnt4 = 1:AxialStep
                cntphi = teeth(cnt3) - (cnt4 - 1);  % Angle based on bottom of teeth
                if cntphi < 1
                    cntphi = cntphi + RevStep;  % Helix wrapped through 0 degrees
                end

                phia = phi(cntphi);  % Angle for given axial disk [deg]

                % Determine current cutting forces
                if (StartAngle <= phia) && (phia <= ActualEndAngle)
                    n = x(i - 1) * sin(phia * pi / 180) - y(i - 1) * cos(phia * pi / 180);  % [m]
                    dt = FeedperTooth * sin(phia * pi / 180) + surf(cnt4, cntphi) - n + RO(cnt3);  % [m]

                    if dt < 0
                        dFt = 0;
                        dFr = 0;
                        surf(cnt4, cntphi) = surf(cnt4, cntphi) + FeedperTooth * sin(phia * pi / 180);
                    else
                        dFt = Ktc * dt * da + Kte * da;  % Tangential cutting force
                        dFr = Krc * dt * da + Kre * da;  % Radial cutting force
                        surf(cnt4, cntphi) = n - RO(cnt3);  % Update surface
                    end
                else
                    dt = 0;
                    dFt = 0;
                    dFr = 0;
                end

                %%%%%% Force output %%%%%%
                Fx(i) = Fx(i) + dFt * cos(phia * pi / 180) + dFr * sin(phia * pi / 180);  % X force
                Fy(i) = Fy(i) + dFt * sin(phia * pi / 180) - dFr * cos(phia * pi / 180);  % Y force
            end
        end

        % Compute resultant force
        F(i) = sqrt(Fx(i)^2 + Fy(i)^2);
        
        % Tool breakage condition
        if F(i) > 1.9e6
            F = NaN;
            disp('---Tool Broken---');
            return
        end

        % Numerical integration for position
        % X direction
        for cnt5 = 1:x_modes
            ddp = (Fx(i) - cx(cnt5) * dp(cnt5, i - 1) - kx(cnt5) * p(cnt5, i - 1)) / mx(cnt5);
            dp(cnt5, i) = dp(cnt5, i - 1) + ddp * TimeStep;
            p(cnt5, i) = p(cnt5, i - 1) + dp(cnt5, i) * TimeStep;
            x(i) = x(i) + p(cnt5, i);        
        end

        % Y direction
        for cnt5 = 1:y_modes
            ddq = (Fy(i) - cy(cnt5) * dq(cnt5, i - 1) - ky(cnt5) * q(cnt5, i - 1)) / my(cnt5);
            dq(cnt5, i) = dq(cnt5, i - 1) + ddq * TimeStep;
            q(cnt5, i) = q(cnt5, i - 1) + dq(cnt5, i) * TimeStep;
            y(i) = y(i) + q(cnt5, i);        
        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%% Function Ends %%%%%%%%%%%%%%%%%%%%%%%% 
%%
% Plot the x and y forces as two vertical subplots
figure;

% Subplot for Fx (force in the x-direction)
subplot(3, 1, 1);
plot(t, Fx, 'LineWidth', 1);
grid on;
title('Force in X direction vs Time');
xlabel('Time (s)');
ylabel('Force in X direction (N)');
xlim([0 0.1])

% Subplot for Fy (force in the y-direction)
subplot(3, 1, 2);
plot(t, Fy, 'LineWidth', 1);
grid on;
title('Force in Y direction vs Time');
xlabel('Time (s)');
ylabel('Force in Y direction (N)');
xlim([0 0.1])

% Subplot for Fy (force in the y-direction)
subplot(3, 1, 3);
plot(t, F, 'LineWidth', 1);
grid on;
title('Resultant Force vs Time');
xlabel('Time (s)');
ylabel('Force (N)');
xlim([0 0.1])
