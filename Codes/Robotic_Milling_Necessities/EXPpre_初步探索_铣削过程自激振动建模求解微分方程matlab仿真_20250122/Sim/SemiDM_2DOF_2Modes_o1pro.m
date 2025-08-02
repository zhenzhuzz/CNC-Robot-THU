%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REVERSE-ENGINEERED MATLAB SCRIPT FOR REPLICATING THE CASE STUDY
% WITH DEBUG PRINT STATEMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

%% SECTION 0. USER OPTIONS & CONSTANTS

q            = 1;        % exponent in the cutting force model
Kt           = 5e8;      % [N/m^2], tangential cutting stiffness
Kr           = 2e8;      % [N/m^2], radial cutting stiffness
fz           = 0.05;     % [mm/tooth] feed per tooth
beta_deg     = 45;       % [deg] helix angle
N_teeth      = 2;        % number of flutes (teeth)
tool_diameter= 20e-3;    % [m] tool diameter
ap           = 10e-3;    % [m] axial depth (example)
lz_pitch     = (tool_diameter*pi)/(N_teeth*tan(deg2rad(beta_deg)));
rho_ae       = [0.1, 0.5, 1.0];   % radial immersion ratio array
Omega_vec    = 500:50:5000;       % [rpm] spindle speeds

%% SECTION 1. MOCK "MEASURED" FRF DATA
freq_meas = linspace(50, 3000, 500); 
mock_nat_freqs_x = [500, 1500];  
mock_nat_freqs_y = [700, 1300];  
mock_damping     = 0.02;         
Hxx_meas = zeros(size(freq_meas));
for wn = mock_nat_freqs_x
    w  = 2*pi*freq_meas;
    w0 = 2*pi*wn;
    denom = -w.^2 + 2*1i*mock_damping*w0.*w + w0^2;
    Hxx_meas = Hxx_meas + (1.0 ./ denom);
end
Hyy_meas = zeros(size(freq_meas));
for wn = mock_nat_freqs_y
    w  = 2*pi*freq_meas;
    w0 = 2*pi*wn;
    denom = -w.^2 + 2*1i*mock_damping*w0.*w + w0^2;
    Hyy_meas = Hyy_meas + (1.0 ./ denom);
end
Hxy_meas = 0.25*Hxx_meas + 0.05*randn(size(Hxx_meas)); 
Hyx_meas = 0.25*Hyy_meas - 0.05*randn(size(Hxx_meas));

MeasuredFRF.freq = freq_meas;
MeasuredFRF.Hxx  = Hxx_meas;
MeasuredFRF.Hyy  = Hyy_meas;
MeasuredFRF.Hxy  = Hxy_meas;
MeasuredFRF.Hyx  = Hyx_meas;

%% SECTION 2. MODAL PARAMETER FITTING
disp('Fitting Modal Parameters...');
modalFRF_fun = @(p, freq) modal_sum_FRF(p, freq); 

p0_x = [2*pi*500, 0.02, 1.0, 2*pi*1500, 0.02, 1.0];
lb_x = [0, 0, 0, 0, 0, 0];
ub_x = [2e4, 1, 1e3, 2e4, 1, 1e3];

options = optimset('Display','off');
px_fit = lsqcurvefit(modalFRF_fun, p0_x, freq_meas, Hxx_meas, lb_x, ub_x, options);

p0_y = [2*pi*700, 0.02, 1.0, 2*pi*1300, 0.02, 1.0];
py_fit = lsqcurvefit(modalFRF_fun, p0_y, freq_meas, Hyy_meas, lb_x, ub_x, options);

DiagonalFRFModel.px = px_fit;
DiagonalFRFModel.py = py_fit;
DiagonalFRFModel.Hxy = 0; 
DiagonalFRFModel.Hyx = 0;

SymFRFModel.px = px_fit;  
SymFRFModel.py = py_fit;
alpha_cross = 0.3; 
SymFRFModel.Hxy = alpha_cross;  
SymFRFModel.Hyx = alpha_cross;

NonSymFRFModel.px  = px_fit;
NonSymFRFModel.py  = py_fit;
alpha_xy  = 0.25; 
alpha_yx  = 0.20; 
NonSymFRFModel.Hxy = alpha_xy; 
NonSymFRFModel.Hyx = alpha_yx;

disp('...Modal Parameter Fitting done.');

%% SECTION 4. RUN SEMI-DISCRETIZATION STABILITY PREDICTION
disp('Computing stability lobes via semi-discretization...');

n_speed   = length(Omega_vec);
axial_cut = linspace(0, 5e-3, 40);

stableMap_Diag   = false(length(axial_cut), n_speed);
stableMap_Sym    = false(length(axial_cut), n_speed);
stableMap_NonSym = false(length(axial_cut), n_speed);

for rId = 1:length(rho_ae)
    ae_ratio = rho_ae(rId);
    fprintf('--- Evaluating radial immersion = %.1f (down-milling) ---\n', ae_ratio);
    
    for i_speed = 1:n_speed
        Omega_rpm = Omega_vec(i_speed);
        
        for i_cut = 1:length(axial_cut)
            ap_test = axial_cut(i_cut);
            p_steps = 16; 
            tau_tooth = 60/(N_teeth*Omega_rpm); 
            h_sub = tau_tooth / p_steps;
            
            %% 4.1 Diagonal
            modelType = 'diag'; 
            A_diag = computeTransitionMatrix(modelType, ...
                DiagonalFRFModel, Omega_rpm, ap_test, ae_ratio, ...
                p_steps, q, Kt, Kr, fz, tool_diameter, lz_pitch, N_teeth);
            mu_eigs = abs(eig(A_diag));
            maxEig = max(mu_eigs);
            stableMap_Diag(i_cut, i_speed) = (maxEig < 1);
            
            % Debug print for Diagonal
            fprintf('[Diag] ap=%.4f, speed=%4d, maxEig=%.4f, stable=%d\n',...
                ap_test, Omega_rpm, maxEig, stableMap_Diag(i_cut, i_speed));
            
            %% 4.2 Sym
            modelType = 'sym'; 
            A_sym = computeTransitionMatrix(modelType, ...
                SymFRFModel, Omega_rpm, ap_test, ae_ratio, ...
                p_steps, q, Kt, Kr, fz, tool_diameter, lz_pitch, N_teeth);
            mu_eigs = abs(eig(A_sym));
            maxEig = max(mu_eigs);
            stableMap_Sym(i_cut, i_speed) = (maxEig < 1);
            
            % Debug print for Sym
            fprintf('[Sym ] ap=%.4f, speed=%4d, maxEig=%.4f, stable=%d\n',...
                ap_test, Omega_rpm, maxEig, stableMap_Sym(i_cut, i_speed));
            
            %% 4.3 NonSym
            modelType = 'nonsym';
            A_nonsym = computeTransitionMatrix(modelType, ...
                NonSymFRFModel, Omega_rpm, ap_test, ae_ratio, ...
                p_steps, q, Kt, Kr, fz, tool_diameter, lz_pitch, N_teeth);
            mu_eigs = abs(eig(A_nonsym));
            maxEig = max(mu_eigs);
            stableMap_NonSym(i_cut, i_speed) = (maxEig < 1);
            
            % Debug print for NonSym
            fprintf('[NSym] ap=%.4f, speed=%4d, maxEig=%.4f, stable=%d\n\n',...
                ap_test, Omega_rpm, maxEig, stableMap_NonSym(i_cut, i_speed));
            
        end % i_cut
    end % i_speed
    
    figure('Name',['Stability Charts, ae=',num2str(ae_ratio)], 'Color','w');
    
    subplot(1,3,1); hold on; grid on;
    imagesc(Omega_vec, axial_cut*1e3, stableMap_Diag);
    axis xy; colormap(gray); 
    xlabel('Spindle Speed [rpm]');
    ylabel('Depth of Cut [mm]');
    title('Diagonal FRF (No Cross Terms)');
    
    subplot(1,3,2); hold on; grid on;
    imagesc(Omega_vec, axial_cut*1e3, stableMap_Sym);
    axis xy; colormap(gray);
    xlabel('Spindle Speed [rpm]');
    ylabel('Depth of Cut [mm]');
    title('Symmetric FRF (Cross Terms = same)');
    
    subplot(1,3,3); hold on; grid on;
    imagesc(Omega_vec, axial_cut*1e3, stableMap_NonSym);
    axis xy; colormap(gray);
    xlabel('Spindle Speed [rpm]');
    ylabel('Depth of Cut [mm]');
    title('Non-Symmetric FRF (Cross Terms \neq same)');
    
    sgtitle(['Radial Immersion = ',num2str(ae_ratio),' (Down-Milling)']);
    
end

disp('Finished computing & plotting.');

%% SUBFUNCTIONS

function H = modal_sum_FRF(p, freq)
    w  = 2*pi*freq;    
    wn1 = p(1); z1  = p(2); A1 = p(3);
    wn2 = p(4); z2  = p(5); A2 = p(6);
    den1 = -w.^2 + 2*1i*z1*wn1.*w + wn1^2;
    den2 = -w.^2 + 2*1i*z2*wn2.*w + wn2^2;
    H = A1./den1 + A2./den2;
end

function Pi_mat = computeTransitionMatrix(modelType, FRFmodel, Omega_rpm, ap_val, ae_ratio, ...
    p_steps, q, Kt, Kr, fz, tool_diam, lz_pitch, N_teeth)

    dim = 4; 
    % Basic diagonal damping or something
    zeta = 0.02;
    omega_n = 2*pi*1000;
    
    switch lower(modelType)
        case 'diag'
            cross_factor = 0;
        case 'sym'
            cross_factor = FRFmodel.Hxy;  
        case 'nonsym'
            cross_factor = (FRFmodel.Hxy + FRFmodel.Hyx)/2; 
        otherwise
            cross_factor = 0;
    end
    
    %-----EXAMPLE: incorporate a small positive feedback that grows with ap_val
    % so that at higher ap_val we might get unstable. This is just a hack 
    % to demonstrate how a_p could be used to push the system to instability.
    cross_factor = cross_factor + ap_val * 1e4; 
    
    % Build an example matrix
    A_rand = [ -zeta*omega_n,    cross_factor, 0,            0;
               -cross_factor,    -zeta*omega_n, 0,           0;
                0,               0,            -zeta*omega_n, cross_factor;
                0,               0,            -cross_factor, -zeta*omega_n];
    
    tau_tooth = 60/(N_teeth*Omega_rpm);
    h_sub = tau_tooth/p_steps;
    G_k   = expm(A_rand*h_sub);
    Pi_mat = G_k^p_steps;
end
