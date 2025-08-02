% p_4_17_2.m
% Copyright
% Zhen Zhu
% January 5, 2025

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

% Calculate spindle speeds
omega = w / (Nt * 2 * pi) ./ (n + epsilon / (2 * pi)) * 60;   % rpm

% Iterate on initial solution
for loop = 1:iterations
    v = pi * d * omega / 60;
    
    cnewx = cx + C * blim ./ v * (cos(pi/2 - phiave*pi/180))^2;
    zetax = cnewx / (2 * sqrt(kx * mx));
    cnewy = cy + C * blim ./ v * (cos(pi - phiave*pi/180))^2;
    zetay = cnewy / (2 * sqrt(ky * my));

    rx = w / wnx;
    FRF_real_x = 1/kx * (1 - rx.^2) ./ ((1 - rx.^2).^2 + (2 * zetax .* rx).^2);
    FRF_imag_x = 1/kx * (-2 * zetax .* rx) ./ ((1 - rx.^2).^2 + (2 * zetax .* rx).^2);
    ry = w / wny;
    FRF_real_y = 1/ky * (1 - ry.^2) ./ ((1 - ry.^2).^2 + (2 * zetay .* ry).^2);
    FRF_imag_y = 1/ky * (-2 * zetay .* ry) ./ ((1 - ry.^2).^2 + (2 * zetay .* ry).^2);

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
    
    % Calculate spindle speeds
    omega = w / (Nt * 2 * pi) ./ (n + epsilon / (2 * pi)) * 60;   % rpm
end

% Plot initial blim vs omega
figure(1)
plot(omega, blim * 1e3, 'b-', 'LineWidth', 1.5)
axis([0 10000 0 10])
set(gca, 'FontSize', 14)
xlabel('\Omega (rpm)', 'FontSize', 16)
ylabel('b_{lim} (mm)', 'FontSize', 16)
grid on
hold on

% Define the points to be marked
points_x = [7500, 8500, 9000, 9000]; % Omega values in rpm
points_y = [3, 3, 3, 4];                % blim values in mm

% Plot the points with solid red circles
plot(points_x, points_y, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8)

% Optional: Add labels or annotations for clarity
% for i = 1:length(points_x)
%     text(points_x(i), points_y(i), sprintf('(%d,%d)', points_x(i), points_y(i)), ...
%         'Color', 'red', 'FontSize', 12, 'HorizontalAlignment', 'center','VerticalAlignment', 'bottom')
% end

% Continue with the rest of the script: Iterate over lobes
for n = (n + 1):num_lobes
    % Re-define parameters for x direction
    kx = 9e6;                   % N/m
    wnx = 900*2*pi;             % rad/s
    zetax = 0.03;
    mx = kx / (wnx^2);          % kg
    cx = 2 * zetax * sqrt(mx * kx);   % N-s/m

    % Re-define parameters for y direction
    ky = 9e6;                   % N/m
    wny = 900*2*pi;             % rad/s
    zetay = 0.03;
    my = ky / (wny^2);          % kg
    cy = 2 * zetay * sqrt(my * ky);   % N-s/m

    % Re-define FRFs for two directions
    w = (0:0.1:2*wnmax);        % frequency, rad/s
    rx = w / wnx;
    FRF_real_x = 1/kx * (1 - rx.^2) ./ ((1 - rx.^2).^2 + (2 * zetax .* rx).^2);
    FRF_imag_x = 1/kx * (-2 * zetax .* rx) ./ ((1 - rx.^2).^2 + (2 * zetax .* rx).^2);
    ry = w / wny;
    FRF_real_y = 1/ky * (1 - ry.^2) ./ ((1 - ry.^2).^2 + (2 * zetay .* ry).^2);
    FRF_imag_y = 1/ky * (-2 * zetay .* ry) ./ ((1 - ry.^2).^2 + (2 * zetay .* ry).^2);

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

    % Calculate spindle speeds
    omega = w / (Nt * 2 * pi) ./ (n + epsilon / (2 * pi)) * 60;   % rpm

    % Iterate on initial solution
    for loop = 1:iterations
        v = pi * d * omega / 60;
    
        cnewx = cx + C * blim ./ v * (cos(pi/2 - phiave*pi/180))^2;
        zetax = cnewx / (2 * sqrt(kx * mx));
        cnewy = cy + C * blim ./ v * (cos(pi - phiave*pi/180))^2;
        zetay = cnewy / (2 * sqrt(ky * my));
        
        rx = w / wnx;
        FRF_real_x = 1/kx * (1 - rx.^2) ./ ((1 - rx.^2).^2 + (2 * zetax .* rx).^2);
        FRF_imag_x = 1/kx * (-2 * zetax .* rx) ./ ((1 - rx.^2).^2 + (2 * zetax .* rx).^2);
        ry = w / wny;
        FRF_real_y = 1/ky * (1 - ry.^2) ./ ((1 - ry.^2).^2 + (2 * zetay .* ry).^2);
        FRF_imag_y = 1/ky * (-2 * zetay .* ry) ./ ((1 - ry.^2).^2 + (2 * zetay .* ry).^2);
        
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
        
        % Calculate spindle speeds
        omega = w / (Nt * 2 * pi) ./ (n + epsilon / (2 * pi)) * 60;   % rpm
    end
    
    % Plot blim vs omega for current lobe
    plot(omega, blim * 1e3, 'b-', 'LineWidth', 1.0)
end

% Optional: Add a legend
legend('b_{lim} curves', 'Marked Points', 'Location', 'best')

% Enhance plot aesthetics
title('Limit Cutting Depth (b_{lim}) vs Spindle Speed (\Omega)', 'FontSize', 16)
