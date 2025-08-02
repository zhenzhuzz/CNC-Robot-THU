%% Multi-mode (4-DOF) Milling Stability Using Semi-Discretization
%  Two modes in the x direction, two modes in the y direction

clc; clear
tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of teeth
N = 2;

% Cutting force coefficients (N/m^2)
Kt = 6e8; 
Kn = 2e8;

% -- Mode parameters in x direction (two modes) --
%  1st mode in x
w0x1   = 922 * 2*pi;     % natural frequency (rad/s)
zetax1 = 0.011;          % damping ratio
m_x1   = 0.03993;        % mass (kg)

%  2nd mode in x
w0x2   = 1000 * 2*pi;    % just an example ~ 15915.5 rad/s
zetax2 = 0.015;          % example damping ratio
m_x2   = 0.04;           % example mass (kg)

% -- Mode parameters in y direction (two modes) --
%  1st mode in y
w0y1   = 922 * 2*pi; 
zetay1 = 0.011;
m_y1   = 0.03993;

%  2nd mode in y
w0y2   = 970 * 2*pi;    % example ~ 15271.3 rad/s
zetay2 = 0.013;         
m_y2   = 0.041;         

% Radial depth of cut (fraction of tool radius)
aD = 0.05;

% Up- or down-milling: +1 for up, -1 for down
up_or_down = -1;

% Start and exit angles
if up_or_down == 1
    % Up-milling
    fist = 0; 
    fiex = acos(1 - 2*aD);
else
    % Down-milling
    fist = acos(2*aD - 1);
    fiex = pi;
end

% Scanning range for spindle speed and depth of cut
stx  = 50;        % # steps for spindle speed
sty  = 20;        % # steps for depth of cut
w_st = 0e-3;      % start depth of cut (m)
w_fi = 10e-3;     % final depth of cut (m)
o_st = 5e3;       % start spindle speed (rpm)
o_fi = 25e3;      % final spindle speed (rpm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Semi-Discretization Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of sub-intervals per tooth period
k    = 20;  

% Number of integration steps in each sub-interval
intk = 20;   

% Because time delay = time period (for a 2-tooth scenario),
% we define weighting factors for time-delay splitting
wa = 0.5;
wb = 0.5;

% We now have 4 modes => 8 states (x1,x1dot,x2,x2dot,y1,y1dot,y2,y2dot).
% In the original code, matrix D was (2*m + 4) x (2*m + 4).
% Now it becomes (2*m + 8) x (2*m + 8).

% Pre-allocate space for the integrals of the directional factors
hxx = zeros(k,1);
hxy = zeros(k,1);
hyx = zeros(k,1);
hyy = zeros(k,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Numerical Integration of Force Coefficients (Equations 40–43 in paper)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dtr = 2*pi / (N*k);  % sub-interval of angle

for i = 1:k
    h_temp_xx = 0;
    h_temp_xy = 0;
    h_temp_yx = 0;
    h_temp_yy = 0;
    
    for j = 1:N  % sum over each tooth
        % We'll numerically integrate over each sub-sub-interval
        % from i*dtr+(j-1)*2*pi/N to i*dtr+(j-1)*2*pi/N + dtr
        fi_vals = linspace( ...
            (i-1)*dtr + (j-1)*2*pi/N, ...
             i   *dtr + (j-1)*2*pi/N, ...
            intk);
        
        % Evaluate for each small angle segment
        g_vals = zeros(size(fi_vals));
        cos_fi = cos(fi_vals);
        sin_fi = sin(fi_vals);
        
        for h = 1:intk
            if (fi_vals(h) >= fist) && (fi_vals(h) <= fiex)
                g_vals(h) = 1;
            else
                g_vals(h) = 0;
            end
        end
        
        % Force direction factors
        % Kt*cos(phi)+Kn*sin(phi) => cutting in x
        % -Kt*sin(phi)+Kn*cos(phi) => cutting in y
        fx_factor = (Kt .* cos_fi + Kn .* sin_fi);
        fy_factor = (-Kt .* sin_fi + Kn .* cos_fi);
        
        % Summation for hxx etc. is integral of g_vals * partial-derivatives
        h_temp_xx = h_temp_xx + sum(g_vals .* (fx_factor .* sin_fi));
        h_temp_xy = h_temp_xy + sum(g_vals .* (fx_factor .* cos_fi));
        h_temp_yx = h_temp_yx + sum(g_vals .* (fy_factor .* sin_fi));
        h_temp_yy = h_temp_yy + sum(g_vals .* (fy_factor .* cos_fi));
    end
    
    % Average out by intk
    hxx(i) = h_temp_xx / intk;
    hxy(i) = h_temp_xy / intk;
    hyx(i) = h_temp_yx / intk;
    hyy(i) = h_temp_yy / intk;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Main Loop Over Spindle Speed (o) and Depth of Cut (w)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ss = zeros(stx+1, sty+1);  % store spindle speeds
dc = zeros(stx+1, sty+1);  % store doc
ei = zeros(stx+1, sty+1);  % store max eigenvalues

m = k;  % same as in original code
for x_i = 1:(stx+1)
    
    % Spindle speed
    o = o_st + (x_i-1)*(o_fi - o_st)/stx;  
    % Time delay = period / N = (60/o)/N
    tau = 60/o/N;
    dt  = tau/m;
    
    for y_i = 1:(sty+1)
        
        w = w_st + (y_i-1)*(w_fi - w_st)/sty;  % depth of cut (m)
        
        % Initialize the overall transition matrix Fi (size 2*m+8)
        Fi = eye(2*m + 8);
        
        % Loop through each sub-interval i to build up the transition
        for i = 1:m
            
            %------------------------------------------------------------------
            % Build the 8x8 continuous-time system matrix A and 8x8 matrix B
            % for the i-th sub-interval. (We treat the cutting coefficients
            % hxx(i), hxy(i), hyx(i), hyy(i) as constant over dt in sub-interval.)
            %------------------------------------------------------------------
            
            A = zeros(8,8);
            B = zeros(8,8);
            
            % For convenience:
            hxx_i = hxx(i)*w;  % depth * integrated factor
            hxy_i = hxy(i)*w;
            hyx_i = hyx(i)*w;
            hyy_i = hyy(i)*w;
            
            % 1) x1 direction
            %    States: X(1) = x1, X(2) = dx1
            %    Equations:
            %       d(x1)/dt  = dx1
            %       d(dx1)/dt = - (w0x1^2)*x1 - 2*zeta_x1*w0x1*dx1 - [hxx_i*x_del + hxy_i*y_del]/m_x1
            A(1,2) = 1;  
            A(2,1) = -w0x1^2;
            A(2,2) = -2*zetax1*w0x1;
            
            B(2,1) = - (hxx_i / m_x1);  % partial w.r.t. x1 (delayed)
            B(2,5) = - (hxy_i / m_x1);  % partial w.r.t. y1 (delayed)
            
            % 2) x2 direction
            %    States: X(3) = x2, X(4) = dx2
            A(3,4) = 1;
            A(4,3) = -w0x2^2;
            A(4,4) = -2*zetax2*w0x2;
            
            B(4,3) = - (hxx_i / m_x2); 
            B(4,7) = - (hxy_i / m_x2);
            
            % 3) y1 direction
            %    States: X(5) = y1, X(6) = dy1
            A(5,6) = 1;
            A(6,5) = -w0y1^2;
            A(6,6) = -2*zetay1*w0y1;
            
            B(6,1) = - (hyx_i / m_y1); 
            B(6,5) = - (hyy_i / m_y1);
            
            % 4) y2 direction
            %    States: X(7) = y2, X(8) = dy2
            A(7,8) = 1;
            A(8,7) = -w0y2^2;
            A(8,8) = -2*zetay2*w0y2;
            
            B(8,3) = - (hyx_i / m_y2); 
            B(8,7) = - (hyy_i / m_y2);
            
            % Matrix exponential over dt
            P_ = expm(A*dt);
            % The integral part (expm(A*dt) - I)*A^-1*B
            R_ = (P_ - eye(8)) / A * B;  
            
            %------------------------------------------------------------------
            % Now embed P and R into the (2*m+8)x(2*m+8) matrix D
            % The top-left 8x8 block is P
            % Then we add the R block into columns [2*m+1 : 2*m+4] for wa
            %                                    [2*m+5 : 2*m+8] for wb
            % to handle the delayed states with linear interpolation
            %------------------------------------------------------------------
            D_big = zeros(2*m+8, 2*m+8);
            D_big(1:8,1:8) = P_;
            
            % Weighted R for the delayed portion
            D_big(1:8, 2*m+1:2*m+4) = wa * R_(:,1:4);
            D_big(1:8, 2*m+5:2*m+8) = wb * R_(:,5:8);
            
            % Shift matrix, copying old states down (like the original code)
            dvec = ones(2*m,1);
            dvec(1:8) = 0;  % don't shift the top 8 states
            % shift by 8
            D_big = D_big + diag(dvec, -8);
            
            % Put the current states into the top of the 'delay chain'
            % (similar logic to D(5,1)=1, D(6,2)=1,... in old script)
            % We have 8 states, so:
            for rowIdx = 1:8
                D_big(8+rowIdx, rowIdx) = 1;
            end
            
            % Update Fi
            Fi = D_big * Fi;
        end
        
        % Store results
        ss(x_i, y_i) = o;          % spindle speed
        dc(x_i, y_i) = w * 1000;   % depth of cut in mm
        % The stability criterion is largest abs eigenvalue of Fi
        ei(x_i, y_i) = max(abs(eig(Fi)));
        
    end
    
    % Display iteration countdown
    (stx + 1 - x_i);
end

toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot Stability Lobe Diagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Name','SemiDM - 4DOF Milling');
contour(ss, dc, ei, [1,1],'k','LineWidth',2);
xlabel('Spindle speed \Omega (rpm)');
ylabel('Depth of cut a_p (mm)');
title('Stability Lobe Diagram - Semi-Discretization (4DOF)');

