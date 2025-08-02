%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATLAB CODE:
%   Demo of using a "periodic predictor + AR(2) chatter model" approach
%   for a synthetic milling signal that transitions among:
%       - steady state (s1)
%       - transition to chatter (s2)
%       - full chatter (s3)
%       - return to steady (s4)
%   with added Gaussian noise.
%
%   We will:
%     1) Generate the signal s(t) piecewise over 3 seconds
%     2) Use NLMS to identify the spindle/harmonics (periodic part)
%     3) Use a Kalman filter (AR(2) model) on the residual => get poles
%        => track chatter frequency if |pole|>1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

%% (1) Simulation parameters
Fs     = 2000;        % sampling frequency [Hz], example
dt     = 1/Fs;
Tend   = 3;           % total simulation time [s]
t      = 0:dt:Tend;
N      = length(t);

% Frequencies (from your definition)
f_SP = 25;    % spindle pass frequency (Hz)
f_CH = 133;   % chatter frequency (Hz)

% Build your signals for each region:
%   s1(t): steady cutting (harmonics of f_SP)
%   s2(t): transition to chatter (1->1.5s)
%   s3(t): full chatter state (1.5->2.5s)
%   s4(t): return to steady after 2.5s

% (1a) s1(t)
s1 = 2 .* sin(2*pi*f_SP*t) + ...
     3 .* sin(2*pi*(2*f_SP)*t) + ...
     5 .* sin(2*pi*(3*f_SP)*t);

% (1b) s2(t)
s2 = (50 ./ (1 + exp(-15.*(t - 1))) - 25) .* ...
     cos(2*pi*f_CH*t + 0.5*sin(2*pi*f_SP*t));

% (1c) s3(t)
s3 = 25 .* cos(2*pi*f_CH*t + 0.5.*sin(2*pi*f_SP*t));

% (1d) s4(t)
s4 = 2 .* sin(2*pi*f_SP*t) + ...
     3 .* sin(2*pi*(2*f_SP)*t) + ...
     5 .* sin(2*pi*(3*f_SP)*t);

% (1e) Gaussian white noise (with 15 dB power)
%     15 dB => amplitude factor = 10^(15/20)
% noiseAmp = 10^(15/20);
noiseAmp = 0;

Nvec     = noiseAmp .* randn(size(t));

% (1f) Combine piecewise
s = zeros(size(t));
for k=1:N
   if t(k) <= 1
       s(k) = s1(k) + Nvec(k);
   elseif t(k) <= 1.5
       s(k) = s1(k) + s2(k) + Nvec(k);
   elseif t(k) <= 2.5
       s(k) = s1(k) + s3(k) + Nvec(k);
   else
       s(k) = s4(k) + Nvec(k);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (2) Set up the "two-step" identification approach
%   Step1: NLMS for periodic (f_SP) + harmonics
%   Step2: Kalman filter for AR(2) "chatter channel" on the residual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% # of harmonics to track
nL = 3;  % we have up to 3*f_SP in s1

% NLMS parameters
alphaNLMS = 0.5;    % step size
etaNLMS   = 0.999;  % forgetting factor

% AR(2) model => D(q)=1 + d1 z^-1 + d2 z^-2
% We'll do a random-walk Kalman approach

Re = 1e-5;  % process noise
Rw = 1e-3;  % measurement noise
Pk = 1e-3*eye(2);  % cov matrix init

theta_p = zeros(2*nL,1);  % for cos/sin gain
theta_u = zeros(2,1);     % [d1; d2]

% logs
residual_nlms  = zeros(1,N);
theta_p_log    = zeros(2*nL, N);
theta_u_log    = zeros(2, N);
poles_log      = zeros(2, N);
fchatter_log   = zeros(1, N);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (3) Online recursion at each sample
for k=1:N
    
    % ---- Step1: NLMS periodic predictor ----
    % Build harmonic basis for f_SP, up to 3rd harmonic
    phi_p = zeros(2*nL,1);
    for l=1:nL
        phi_p(2*l-1) = cos(2*pi*(l*f_SP)*t(k));
        phi_p(2*l  ) = sin(2*pi*(l*f_SP)*t(k));
    end
    
    % predicted a^*(k)= phi_p^T * theta_p
    a_pred = phi_p.' * theta_p;
    eps_k  = s(k) - a_pred;   % residual => presumed chatter + noise
    
    residual_nlms(k)= eps_k;
    
    % NLMS update
    norm_phi= max(1e-12, phi_p.'*phi_p);
    theta_p = etaNLMS*theta_p + 2*alphaNLMS*(eps_k*phi_p)/norm_phi;
    theta_p_log(:,k)= theta_p;
    
    % ---- Step2: AR(2) Kalman filter on eps_k ----
    % AR(2) => eps(k)= -[d1 d2]* [eps(k-1); eps(k-2)] + w
    % let x= [d1; d2], phi_u= -[ eps(k-1); eps(k-2)], y_meas= eps(k)
    
    x_pred= theta_u;
    P_pred= Pk + Re*eye(2);
    
    if k>2
        phi_u= -[residual_nlms(k-1); residual_nlms(k-2)];
    else
        phi_u= [0;0];
    end
    
    y_meas= eps_k;
    y_hat= phi_u.'* x_pred;
    
    S= phi_u.'*P_pred*phi_u + Rw;
    Kt= (P_pred*phi_u)/ S;
    
    err= y_meas- y_hat;
    theta_u= x_pred + Kt* err;
    Pk= P_pred - Kt*(phi_u.'*P_pred);
    theta_u_log(:,k)= theta_u;
    
    % compute AR(2) poles => D(z)=1 + d1 z + d2 z^2=0
    d1= theta_u(1);
    d2= theta_u(2);
    rts= roots([1 d1 d2]);  % z^2 + d1 z + d2=0
    poles_log(:,k)= rts;
    
    % chatter freq => pick dominant root
    [~,imx]= max(abs(rts));
    z_dom   = rts(imx);
    
    % approximate freq => angle(z_dom)/(2*pi*dt), wrap if negative
    angle_rad= angle(z_dom);
    freq_est = angle_rad/(2*pi*dt);
    if freq_est<0
        freq_est= freq_est+ Fs;  % wrap freq to positive freq
    end
    fchatter_log(k)= freq_est;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (4) Results / Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

timeMs= t*1e3;

figure('Name','Simulated Signal');
plot(timeMs, s,'b','LineWidth',1.2);
xlabel('Time [ms]'); ylabel('Amplitude');
title('Synthetic Milling Signal with Four Stages + Noise');
grid on;

figure('Name','NLMS Residual');
plot(timeMs, residual_nlms,'LineWidth',1.2);
xlabel('Time [ms]'); ylabel('\epsilon(k)');
title('Residual after subtracting identified periodic part');
grid on;

figure('Name','AR(2) Poles and Identified Chatter Freq');
subplot(2,1,1);
plot(timeMs, abs(poles_log(1,:)),'r','LineWidth',1.2); hold on;
plot(timeMs, abs(poles_log(2,:)),'b','LineWidth',1.2);
legend('|pole_1|','|pole_2|','Location','best');
xlabel('Time [ms]'); ylabel('Magnitude');
title('AR(2) pole magnitudes vs time');
grid on;

subplot(2,1,2);
plot(timeMs, fchatter_log,'k','LineWidth',1.2);
xlabel('Time [ms]');
ylabel('Freq [Hz]');
title('Estimated chatter frequency from dominant AR(2) pole');
grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Explanation:
%   - Before t=1s => mostly s1 => residual is small if we've properly
%     identified harmonic of f_SP=25Hz + its 2nd,3rd harm. => AR(2) won't
%     see strong poles outside |z|=1 => chatter freq might be random.
%
%   - t=1..1.5 => s2 => "transition" => we start seeing partial chatter
%   - t=1.5..2.5 => s3 => "full chatter" => AR(2) tries to lock onto ~133Hz
%     dominant root => see if freq_est near 133.
%   - t>2.5 => back to s4 => again no strong chatter => freq_est returns near
%     random or meaningless as the pole moves inside the unit circle.
%
%   - There's random noise (15 dB) => so results won't be perfectly stable,
%     but should roughly show a jump near 133Hz in the middle region.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
