% Define cutting force coefficients
Ks = 2000e6;  % N/m^2
beta = 70;    % deg
kt = Ks * sin(beta*pi/180);
kn = Ks * cos(beta*pi/180);
C = 0;        % N/m

% Define modal parameters for x direction
kx = 9e6;          % N/m
zetax = 0.03;
wnx = 900 * 2*pi;  % rad/s
mx = kx / (wnx^2); % kg
cx = 2 * zetax * sqrt(mx*kx);

% Define modal parameters for y direction
ky = 9e6;          % N/m
zetay = 0.03;
wny = 900 * 2*pi;  % rad/s
my = ky / (wny^2); % kg
cy = 2 * zetay * sqrt(my*ky);

% Define cutting parameters
Nt = 3;         % Number of teeth
d = 19e-3;      % teeth diameter, m
gamma = 30;     % helix angle, deg
phis = 0;       % deg
phie = 90;      % deg
omega = 250;    % rpm
b = 3e-3;       % axial depth of cut, m
ft = 0.1e-3;    % feed per tooth, m
v = pi*d*omega/60; % m/s

% Simulation specifications
fnmax = max([wnx wny])/(2*pi);
DT = 1/(25*fnmax);
steps_rev = 60/(omega*DT);
steps_tooth = round(steps_rev / Nt);
steps_rev = steps_tooth * Nt;
dt = 60/(steps_rev*omega);
dphi = 360/steps_rev;

if gamma == 0
    db = b;
else
    db = d * (dphi*pi/180) / (2 * tan(gamma*pi/180));
end

steps_axial = round(b/db);
rev = 20;                  % total revolutions
totalSteps = rev * steps_rev; % total steps of simulation

% Angles for one revolution
phi = (0 : dphi : 360 - dphi); 
