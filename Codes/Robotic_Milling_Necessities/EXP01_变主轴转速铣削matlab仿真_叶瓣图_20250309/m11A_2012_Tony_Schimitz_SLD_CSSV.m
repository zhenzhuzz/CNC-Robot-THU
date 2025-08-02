clear
close all
clc

% Define converging analysis parameters
iterations = 20;
num_lobes = 200;

% Carry out calculations starting at selected N = n
n = 1;

% Define tool diameter
d = 19e-3;                  % m

% Define parameters for x direction
kx = 9e6;                   % N/m
wnx = 900*2*pi;             % rad/s
zetax = 0.03;
mx = kx/(wnx^2);            % kg
cx = 2*zetax*sqrt(mx*kx);   % N-s/m

% Define parameters for y direction
ky = 9e6;                   % N/m
wny = 900*2*pi;             % rad/s
zetay = 0.03;
my = ky/(wny^2);            % kg
cy = 2*zetay*sqrt(my*ky);   % N-s/m

% Define FRFs for two directions
wnmax = max([wnx wny]);
w = (0:0.1:2*wnmax);        % frequency, rad/s
rx = w/wnx;
FRF_real_x = 1/kx*(1 - rx.^2) ./ ((1 - rx.^2).^2 + (2*zetax.*rx).^2);
FRF_imag_x = 1/kx*(-2*zetax.*rx) ./ ((1 - rx.^2).^2 + (2*zetax.*rx).^2);
ry = w/wny;
FRF_real_y = 1/ky*(1 - ry.^2) ./ ((1 - ry.^2).^2 + (2*zetay.*ry).^2);
FRF_imag_y = 1/ky*(-2*zetay.*ry) ./ ((1 - ry.^2).^2 + (2*zetay.*ry).^2);

% Define force model
Ks = 2000e6;            % specific cutting force, N/m^2
beta = 70*pi/180;       % force angle, rad
C = 2e4;                % process damping coefficient, N/m

% Define average number of teeth in cut, Nt_star
Nt = 3;
phis = 0;                   % entry angle, deg
phie = 90;                  % exit angle, deg
phiave = (phis + phie)/2;   % average tooth angle, deg
Nt_star = (phie - phis)*Nt/360;

% Directional orientation factors
mux = cos((beta - (pi/2 - phiave*pi/180))) * cos(pi/2 - phiave*pi/180);
muy = cos((pi - phiave*pi/180) - beta) * cos(pi - phiave*pi/180);

% Oriented FRF
FRF_real_orient = mux * FRF_real_x + muy * FRF_real_y; 
FRF_imag_orient = mux * FRF_imag_x + muy * FRF_imag_y;

% Determine valid chatter frequency range
index = find(FRF_real_orient < 0);
FRF_real_orient = FRF_real_orient(index);
FRF_imag_orient = FRF_imag_orient(index);
w = w(index);

% Calculate blim
blim = -1 ./ (2 * Ks * FRF_real_orient * Nt_star);  % m

% Calculate epsilon
epsilon = zeros(1, length(FRF_imag_orient));
for cnt = 1:length(FRF_imag_orient)
    if FRF_imag_orient(cnt) < 0
        epsilon(cnt) = 2*pi - 2*atan(abs(FRF_real_orient(cnt) / FRF_imag_orient(cnt)));
    else
        epsilon(cnt) = pi - 2*atan(abs(FRF_imag_orient(cnt) / FRF_real_orient(cnt)));
    end
end

% Calculate spindle speeds (constant speed for initial case)
omega_const = w / (Nt * 2 * pi) ./ (n + epsilon / (2 * pi)) * 60;   % rpm

% Sine modulation spindle speed
Omega_0 = 5000; % base speed (rpm)
Omega_1 = 1000; % modulation amplitude (rpm)
omega_m = 1;    % modulation frequency (rad/s)
phi = 0;        % phase shift
RVA = Omega_1 / Omega_0;
RVF = 60 / (Omega_0 * 1);  % some example value for RVF
omega_sine = Omega_0 * (1 + RVA * sin(omega_m * (0:length(w)-1) + phi));

% Triangle modulation spindle speed
omega_triangle = Omega_0 * (1 + RVA) - 4 * RVF * mod((0:length(w)-1), 1); % Adjust this for triangle waveform

% Iterate on initial solution for constant speed and modulated speeds
for loop = 1:iterations
    v_const = pi * d * omega_const / 60;
    v_sine = pi * d * omega_sine / 60;
    v_triangle = pi * d * omega_triangle / 60;

    % Calculate new damping for constant speed, sine modulated, and triangle modulated
    cnewx_const = cx + C * blim ./ v_const * (cos(pi/2 - phiave*pi/180))^2;
    zetax_const = cnewx_const / (2 * sqrt(kx * mx));
    cnewy_const = cy + C * blim ./ v_const * (cos(pi - phiave*pi/180))^2;
    zetay_const = cnewy_const / (2 * sqrt(ky * my));
    
    % Repeat the process for sine and triangle modulation speeds
    cnewx_sine = cx + C * blim ./ v_sine * (cos(pi/2 - phiave*pi/180))^2;
    zetax_sine = cnewx_sine / (2 * sqrt(kx * mx));
    cnewy_sine = cy + C * blim ./ v_sine * (cos(pi - phiave*pi/180))^2;
    zetay_sine = cnewy_sine / (2 * sqrt(ky * my));
    
    cnewx_triangle = cx + C * blim ./ v_triangle * (cos(pi/2 - phiave*pi/180))^2;
    zetax_triangle = cnewx_triangle / (2 * sqrt(kx * mx));
    cnewy_triangle = cy + C * blim ./ v_triangle * (cos(pi - phiave*pi/180))^2;
    zetay_triangle = cnewy_triangle / (2 * sqrt(ky * my));

    % Continue with the rest of the iteration...
end

% Plot stability lobes
figure
hold on

% Plot for constant speed
plot(omega_const, blim * 1e3, 'b-', 'LineWidth', 1.5)

% Plot for sine modulated speed
plot(omega_sine, blim * 1e3, 'r-', 'LineWidth', 1.5)

% Plot for triangle modulated speed
plot(omega_triangle, blim * 1e3, 'g-', 'LineWidth', 1.5)

% Label the plot
xlabel('Spindle Speed (\Omega) [rpm]', 'FontSize', 16)
ylabel('Limit Depth (b_{lim}) [mm]', 'FontSize', 16)
title('Stability Lobes for Different Speed Modulations', 'FontSize', 18)
legend('Constant Speed', 'Sine Modulation', 'Triangle Modulation', 'Location', 'best')
grid on
