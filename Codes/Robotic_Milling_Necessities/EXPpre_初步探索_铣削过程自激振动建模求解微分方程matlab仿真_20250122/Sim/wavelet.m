%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Time-Frequency Control of Milling Instability - One-Click Script
%
%  This script:
%    1. Defines and simulates the milling model from the chapter (Eq. 8.1).
%    2. Activates a "wavelet-based" time-frequency controller at t=0.2 s.
%    3. Plots Time Response, Fourier Spectrum, Instantaneous Frequency,
%       and Marginal Spectrum (wavelet-based).
%
%  Author: ChatGPT
%  Date:   2025-01-25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

%% 1. Set Milling Model Parameters
m    = 0.0431;     % mass (kg)
k    = 1.4e6;      % stiffness (N/m)
c_m  = 8.2;        % damping coefficient (Ns/m)
w_n  = sqrt(k/m);  % natural frequency (rad/s)
zeta = c_m/(2*m*w_n);  % damping ratio

% Cutting and time-delay parameters
N            = 2;         % number of cutting edges
Omega_rpm    = 12000;     % spindle speed in rpm (pick a chaotic example)
Omega_rad    = Omega_rpm*2*pi/60; 
tau          = (2*pi/N) / (Omega_rad); % time delay
h0           = 0.01;      % feed per tooth
K_cut        = 1e9;       % empirical constant for the 3/4 rule
w_chip       = 1;         % chip width

% Simulation Time
tStart  = 0;
tEnd    = 0.8;
dt      = 1e-5;                % Smaller dt => more accurate
timeVec = (tStart:dt:tEnd)';

% Controller Activation
controlStartTime = 0.2;   % controller ON after 0.2s
controllerActive = false;

% For reference, define a "target" position we want ~0
x_target = 0;

%% 2. Preallocate State Arrays
nSteps = length(timeVec);
x    = zeros(nSteps,1);   % displacement
xdot = zeros(nSteps,1);   % velocity
u_c  = zeros(nSteps,1);   % control force record (for plotting)

% Initial Conditions
x(1)    = 0;
xdot(1) = 0;

%% 3. Main Time-Stepping Loop (Euler for clarity)
for i = 1:(nSteps-1)
    tNow = timeVec(i);
    
    if (tNow >= controlStartTime)
        controllerActive = true;
    end
    
    % 3.1 Evaluate the cutting force & delta(t)
    [Fc_val, delta_val] = cuttingForce(tNow, x, i, dt, h0, tau, K_cut, w_chip);
    
    % 3.2 Wavelet-Based Time-Frequency Control (placeholder logic)
    if controllerActive
        % Error signal (difference from target):
        e_t = x(i) - x_target; 
        % We pass the entire signal up to now into the wavelet-based
        % controller so it can adapt in "real time".
        x_signal_so_far = x(max(1,i-1000):i);  % small window
        t_signal_so_far = timeVec(max(1,i-1000):i);
        
        u_now = waveletBasedFXLMS(e_t, x_signal_so_far, t_signal_so_far);
    else
        u_now = 0;
    end
    
    % 3.3 Net force on the tool
    F_net = -k*x(i) - c_m*xdot(i) + Fc_val*delta_val + u_now;
    
    % 3.4 Euler integration
    xdot(i+1) = xdot(i) + (F_net/m)*dt;
    x(i+1)    = x(i)   + xdot(i)*dt;
    u_c(i+1)  = u_now;
end

%% 4. Plot Results
% 4.1 Time Response
figure('Name','Time Response','Color','w');
plot(timeVec, x, 'b-', 'LineWidth',1);
hold on; yline(0,'r--','Target=0');
xlabel('Time (s)'); ylabel('Displacement x(t) (m)');
title(['Time Response at \Omega = ',num2str(Omega_rpm),' rpm']);
grid on;

% Mark the control activation time
xlim([0 tEnd]);
ylim([1.1*min(x), 1.1*max(x)]);
line([controlStartTime controlStartTime],ylim,'Color','m','LineStyle','--','LineWidth',1.2);
text(controlStartTime,0,'  Controller ON','Color','m','FontWeight','bold');

% 4.2 Fourier Spectrum of x(t)
[fftMag,freqVec] = computeFFT(x, dt);
figure('Name','Fourier Spectrum','Color','w');
plot(freqVec, fftMag, 'LineWidth',1);
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('Fourier Spectrum of x(t)');
xlim([0 5000]); grid on;

% 4.3 Instantaneous Frequency (Hilbert Transform)
[instFreq, ampEnv] = instantaneousFrequency(x, dt);
timeIF = timeVec(1:end-1); % instFreq is length-1
figure('Name','Instantaneous Frequency','Color','w');
plot(timeIF, instFreq, 'LineWidth',1); 
xlabel('Time (s)'); ylabel('Frequency (Hz)');
title('Instantaneous Frequency via Hilbert Transform');
grid on;

% 4.4 Marginal Spectrum (Wavelet Approach)
[margSpec, freqAxis] = marginalSpectrum(x, dt);
figure('Name','Marginal Spectrum','Color','w');
plot(freqAxis, margSpec,'LineWidth',1);
xlabel('Frequency (Hz)'); ylabel('Amplitude');
title('Marginal Spectrum (sum of CWT over time)');
grid on;

% 4.5 Optional: Plot Control Force
figure('Name','Control Force','Color','w');
plot(timeVec, u_c, 'LineWidth',1);
xlabel('Time (s)'); ylabel('Control Force (N)');
title('Control Force Over Time');
grid on;

disp('Simulation complete. Figures generated.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  LOCAL FUNCTION DEFINITIONS (MUST APPEAR AT THE END OF THE FILE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Fc_val, delta_val] = cuttingForce(tNow, x, i, dt, h0, tau, K_cut, w_chip)
% cuttingForce:
%   Returns the cutting force (Fc_val) and delta(t) factor (delta_val).
%   In the chapter, delta(t)=1 only when the tooth is engaged in cutting.
%   For simplicity, we approximate that it is always engaged.
%   You can refine it to replicate the partial-immersion effect.

    % Index shift for time-delay
    delaySteps = round(tau/dt); 
    if i - delaySteps < 1
        x_delay = 0;
    else
        x_delay = x(i - delaySteps);
    end

    % Approx: always in contact
    delta_val = 1; 
    h_t = h0 + x_delay - x(i);
    if h_t < 0, h_t = 0; end % no negative chip thickness
    Fc_val = K_cut * w_chip * (h_t^(3/4));
end

function u_control = waveletBasedFXLMS(errorSignal, signalWin, timeWin)
% waveletBasedFXLMS:
%   Placeholder function demonstrating how you'd incorporate wavelet
%   processing and an adaptive update (FXLMS). In a real scenario, you would:
%     1) wavelet-transform the recent error
%     2) adapt filter coefficients
%     3) inverse-transform to obtain a time-domain control
%   Here, we just do a trivial "gain" to show usage.
    
    % ~~~~~~~~~~~~~ Placeholders ~~~~~~~~~~~~~
    gain = -2e3; 
    % A simple PD-like approach on the error signal:
    % The wavelet step is omitted for brevity.
    u_control = gain * errorSignal;
end

function [fftMag, freqVec] = computeFFT(sig, dt)
% computeFFT:
%   Returns single-sided amplitude spectrum of a real signal.
    N  = length(sig);
    Y  = fft(sig);
    % Single-sided
    Y  = Y(1:floor(N/2));
    fftMag = abs(Y)/(N/2);
    freqVec = (0:floor(N/2)-1)'/(N*dt);
end

function [instFreq, amplitude] = instantaneousFrequency(signal, dt)
% instantaneousFrequency:
%   Uses the Hilbert transform approach to get instantaneous frequency:
%     phi(t) = angle(hilbert(signal(t))),
%     freq(t) = (1/(2*pi)) * d/dt ( unwrapped phi(t) ).
    
    analyticSig = hilbert(signal);
    phi = unwrap(angle(analyticSig));
    % derivative of phase vs time => angular velocity
    omega_t = diff(phi)/dt;
    % convert rad/s => Hz
    instFreq = omega_t/(2*pi);
    amplitude = abs(analyticSig);
end

function [margSpec, freqAxis] = marginalSpectrum(signal, dt)
% marginalSpectrum:
%   Sums wavelet transform across time for each scale => "marginal" energy.
%   The wavelet scale->frequency mapping uses scal2frq. Adjust for your wavelet.

    scales = 1:256;        % wavelet scales
    wavename = 'db2';      % mother wavelet (Daubechies-2, as the text suggests)
    cwtCoeffs = cwt(signal, scales, wavename);
    % cwtCoeffs: size [length(scales) x length(signal)]
    
    freqApprox = scal2frq(scales, wavename, 1/dt);
    energyPerScale = sum(abs(cwtCoeffs).^2, 2); 
    margSpec = energyPerScale; 
    freqAxis = freqApprox;
    
    % NOTE: The shape of the marginal spectrum is approximate. 
    % For exact replication, you might use the same wavelet transform method 
    % used in the chapter’s code (including normalization factors).
end
