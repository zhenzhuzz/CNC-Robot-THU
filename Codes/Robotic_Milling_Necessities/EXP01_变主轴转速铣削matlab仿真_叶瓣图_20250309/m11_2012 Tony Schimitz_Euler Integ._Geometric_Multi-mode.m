% p_4_18_1.m
% Copyright
% Zhen Zhu
% January 5, 2025

clc
close all
clear

% Define cutting force coefficients
Ks = 2000e6;                    % N/m^2
beta = 70;                      % deg
kt = Ks*sin(beta*pi/180);
kn = Ks*cos(beta*pi/180);
C = 2e4;                        % N/m

% Define modal parameters for x direction
kx = [9e6];                     % N/m
zetax = [0.03];
wnx = [900]*2*pi;               % rad/s
mx = kx./(wnx.^2);              % kg
cx = 2*zetax.*(mx.*kx).^0.5;    % N-s/m
x_modes = length(kx);           % number of modes in x direction

% Define modal parameters for y direction
ky = [9e6];                     % N/m
zetay = [0.03];
wny = [900]*2*pi;               % rad/s
my = ky./(wny.^2);              % kg
cy = 2*zetay.*(my.*ky).^0.5;    % N-s/m
y_modes = length(ky);           % number of modes in y direction

% Define cutting parameters
Nt = 3;
d = 19e-3;                      % teeth diameter, m
gamma = 30;                     % helix angle, deg
phis = 0;                       % deg
phie = 90;                      % deg
omega = 10000;                    % rpm
b = 3e-3;                       % m
ft = 0.1e-3;                    % m
v = pi*d*omega/60;              % m/s

% Simulation specifications
fnmax = max([wnx wny])/2/pi;        % max natural frequency, Hz
DT = 1/(20*fnmax);                  % nominal integration time step, s
steps_rev = 60/(omega*DT);          % steps per revolution
steps_tooth = steps_rev/Nt;         % steps per tooth
steps_tooth = round(steps_tooth);   % verify that steps_tooth is an integer
steps_rev = steps_tooth*Nt;
dt = 60/(steps_rev*omega);          % reset dt using new steps_rev value, s
dphi = 360/steps_rev;               % deg
if gamma == 0
    db = b;
else
    % discretized axial depth, m
    db = d*(dphi*pi/180)/2/tan(gamma*pi/180);
end
% number of steps along tool axis
steps_axial = round(b/db);
rev = 20;
steps = rev*steps_rev;

% Initialize vectors
for cnt = 1:Nt
    teeth(cnt) = (cnt-1)*steps_rev/Nt + 1;
end
for cnt = 1:steps_rev
	phi(cnt) = (cnt - 1)*dphi;
end

% Initialize vectors
surf = zeros(steps_axial, steps_rev);
xpos = zeros(1, steps);
ypos = zeros(1, steps);
xvel = zeros(1, steps);
yvel = zeros(1, steps);
Forcex = zeros(1, steps);
Forcey = zeros(1, steps);

% Euler integration initial conditions
x = 0;
y = 0;
x_dot = 0;
y_dot = 0;
dp = zeros(1, x_modes);         
p = zeros(1, x_modes);          % x-direction modal displacements, m
dq = zeros(1, y_modes);
q = zeros(1, y_modes);          % y-direction modal displacements, m

% Function to keep track of simulation progress
handle = waitbar(0, 'Please wait... simulation in progress.');

for cnt1 = 1:steps
    waitbar(cnt1/steps, handle)
        
    for cnt2 = 1:Nt              
   		teeth(cnt2) = teeth(cnt2) + 1;
	    if teeth(cnt2) > steps_rev 
	      	teeth(cnt2) = 1;
      	end
	end		

    Fx = 0;
    Fy = 0;
    
    for cnt3 = 1:Nt
        for cnt4 = 1:steps_axial
            phi_counter = teeth(cnt3) - (cnt4-1);
            if phi_counter < 1          % helix has wrapped through phi = 0 deg
                phi_counter = phi_counter + steps_rev;
            end
            phia = phi(phi_counter);    % angle for given axial disk, deg
            
            if (phia >= phis) && (phia <= phie)
                n = x*sin(phia*pi/180) - y*cos(phia*pi/180);                % m
                n_dot = x_dot*sin(phia*pi/180) - y_dot*cos(phia*pi/180);    % m/s
                h = ft*sin(phia*pi/180) + surf(cnt4, phi_counter) - n;      % m
                if h < 0
	           	    Ft = 0;
                    Fn = 0;
	                surf(cnt4, phi_counter) = surf(cnt4, phi_counter) + ft*sin(phia*pi/180);
                else
                    Ft = kt*db*h;
                    Fn = kn*db*h - C*db/v*n_dot;
                    surf(cnt4, phi_counter) = n;
                end
         	else
    			Ft = 0;
                Fn = 0;
            end
	
            Fx = Fx + Ft*cos(phia*pi/180) + Fn*sin(phia*pi/180);
            Fy = Fy + Ft*sin(phia*pi/180) - Fn*cos(phia*pi/180);
        end
    end
    
    Forcex(cnt1) = Fx;
    Forcey(cnt1) = Fy;
        
    % Numerical integration for position
    x = 0;
    y = 0;
    x_dot = 0;
    y_dot = 0;

    % x direction
    for cnt5 = 1:x_modes
        ddp = (Fx - cx(cnt5)*dp(cnt5) - kx(cnt5)*p(cnt5))/mx(cnt5);
        dp(cnt5) = dp(cnt5) + ddp*dt;
        x_dot = x_dot + dp(cnt5);
        p(cnt5) = p(cnt5) + dp(cnt5)*dt;
        x = x + p(cnt5);        % m
    end
        
    % y direction
    for cnt5 = 1:y_modes
        ddq = (Fy - cy(cnt5)*dq(cnt5) - ky(cnt5)*q(cnt5))/my(cnt5);
        dq(cnt5) = dq(cnt5) + ddq*dt;
        y_dot = y_dot + dq(cnt5);
        q(cnt5) = q(cnt5) + dq(cnt5)*dt;
        y = y + q(cnt5);        % m
    end
    xpos(cnt1) = x;
    ypos(cnt1) = y;
    xvel(cnt1) = x_dot;
    yvel(cnt1) = y_dot;
end

close(handle);              % close progress bar
time = ((1:steps)-1)*dt;    % s

figure(1)
subplot(211)
plot(time, Forcex)
axis([0 max(time) 0 2300]) 
set(gca,'FontSize', 14)
ylabel('F_x (N)')
subplot(212)
plot(time, xpos*1e6)
axis([0 max(time) -1000 1000]) 
set(gca,'FontSize', 14)
xlabel('t (s)')
ylabel('x (\mum)')

% figure(2)
% subplot(211)
% plot(time, Forcey)
% xlim([0 max(time)]) 
% set(gca,'FontSize', 14)
% ylabel('F_y (N)')
% subplot(212)
% plot(time, ypos*1e6)
% xlim([0 max(time)]) 
% set(gca,'FontSize', 14)
% xlabel('t (s)')
% ylabel('y (\mum)')

F = (Forcex.^2 + Forcey.^2).^0.5;   % N
% figure(3)
% plot(time, F)
% xlim([0 max(time)])
% set(gca,'FontSize', 14)
% xlabel('t (s)')
% ylabel('F (N)')
