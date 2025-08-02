%% ADVANCED SEMI-DISCRETIZATION FOR MILLING STABILITY
%  - Non-symmetric M, C, K (4 second-order DOFs => 8 state variables)
%  - Non-proportional damping, cross-FRF, complex modes
%  - Time-varying B(t) from flute rotation (piecewise constant per sub-interval)
%  - Delay = (60 / spindleSpeed) / (#teeth)
%  - "Delay-chain" assembly => big transition matrix => eigenvalue test

clc; clear; close all;
tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) SYSTEM MATRICES (GENERAL, NON-SYMMETRIC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We define 4 second-order DOFs => size(M)=4x4, etc.
% Example: a slightly "tilted" mass matrix, a "cross" damping, and a "coupled" stiffness.
% (In a real scenario, you'd get these from measurement or FE analysis.)

M = [ 0.04   0.001  0      0    ;
      0.0005 0.039  0     -0.0003;
      0      0      0.05  0.001 ;
      0.0002 -0.001  0.0005 0.052 ];
  
C = [ 50     5     0      0    ;
      5     55     2      0    ;
      0      2    60      5    ;
      0      0     5     65    ];
  
K = [ 4.0e5   0.6e4  0      0     ;
      0.5e4  3.7e5  0.5e4  0     ;
      0      0.5e4  4.2e5  0.3e4 ;
      0      0      0.3e4  4.5e5 ];

% Number of physical DOFs in second-order form:
nDOF = size(M,1);  % =4 in this example

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) MILLING & TIME-DELAY PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nTeeth      = 2;           % e.g. 2 flutes
Kt          = 6.0e8;       % tangential cutting force coefficient (N/m^2)
Kn          = 2.0e8;       % normal cutting force coefficient (N/m^2)
radialDepth = 0.05;        % radial immersion fraction (aD in [0..1])

% Up- or Down-milling
%  +1 => up-milling
%  -1 => down-milling
upOrDown = -1;  

% Start & exit angles for each flute
if upOrDown == 1
    % Up-milling
    phiStart = 0;
    phiEnd   = acos(1 - 2*radialDepth);
else
    % Down-milling
    phiStart = acos(2*radialDepth - 1);
    phiEnd   = pi;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3) SPINDLE SPEED & DEPTH-OF-CUT RANGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nSpeedSteps = 50;      % # of speed increments
nDepthSteps = 50;      % # of doc increments

speedStart  = 5000;    % rpm
speedEnd    = 25000;   % rpm
apStart     = 0e-3;    % min axial depth [m]
apEnd       = 10e-3;   % max axial depth [m]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4) SEMI-DISCRETIZATION SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mSub  = 20;   % # sub-intervals per tooth period
int_k = 20;   % # integration steps in each sub-interval for angle
wa    = 0.5;  % weighting factor for time-delay interpolation
wb    = 0.5;  % wa+wb=1 typically

% First-order dimension = 2*nDOF. For nDOF=4 => 8 states:
nStates   = 2*nDOF;                    
% The big "delay-chain" dimension => 2*mSub + nStates
bigDim    = 2*mSub + nStates;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5) PREALLOCATION FOR RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SS = zeros(nSpeedSteps+1, nDepthSteps+1);  % store speeds
DC = zeros(nSpeedSteps+1, nDepthSteps+1);  % store depths
EI = zeros(nSpeedSteps+1, nDepthSteps+1);  % store max eigenvalue magnitude

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6) MAIN NESTED LOOP OVER SPEED, DEPTH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iSpeed = 0:nSpeedSteps
    
    % Current spindle speed [rpm]
    Omega_rpm = speedStart + iSpeed*(speedEnd - speedStart)/nSpeedSteps;
    
    % Time delay for 2 flutes => tau = (60 / Omega_rpm) / nTeeth
    tau = 60/Omega_rpm / nTeeth;   
    
    % Time step in each sub-interval
    dt = tau/mSub;
    
    % Build the "free vibration" part of A(t) for 2n states (assuming M,C,K constant)
    % We do standard 1st-order form: X=[x; dx],  => dot(X) = [dx; M^-1(-C dx -K x)] 
    % So A = [ 0, I;
    %         -M^-1*K, -M^-1*C ]
    invM   = inv(M);
    A_free = [ zeros(nDOF,nDOF),          eye(nDOF);
              -invM*K,                  -invM*C ];
    
    for jDepth = 0:nDepthSteps
        % Axial depth [m]
        ap_m = apStart + jDepth*(apEnd - apStart)/nDepthSteps;
        
        % Initialize the overall transition matrix = Identity (size bigDim)
        Fi_total = eye(bigDim);
        
        %------------------------------------------------------------------
        % For each of the mSub sub-intervals in a single tooth period
        % we do piecewise-constant B(t).  Then form P_i, R_i => a big block
        % D_i, multiply into Fi_total.
        %------------------------------------------------------------------
        
        for iSub = 1:mSub
            
            % 6.1) Compute partial derivatives of cutting forces in sub-interval
            %     We'll do a quick numeric integration in angle from iSub-1 to iSub
            %     for each tooth, accumulate h_xx, h_xy, h_yx, h_yy.  
            %     Then "B_i = M^-1 * (partialF/partialX_delayed)" 
            %     but now partialF/partialX is a FULL matrix.  
            
            dPhi = (2*pi / nTeeth)/mSub;  % angle slice for one sub-interval
            phi0 = (iSub-1)*dPhi;        % start angle for sub-interval iSub
            % We'll integrate from phi0 => phi0 + dPhi for each flute.
            
            % Example approach: compute a "4x4" partial derivative w.r.t. x(t - tau).
            % Because we have 4 second-order DOFs => in 1st-order form => 8 states.
            % The cutting force might couple x->x, x->y, y->x, y->y, plus extra DOFs.
            % We'll just define a small function that returns this partial derivative
            % as a 4x4 in second-order space. Then we embed it in B_i for 1st-order.
            
            dFdx_4x4 = zeros(nDOF,nDOF);
            
            % Sum over each flute
            for flute = 1:nTeeth
                % sub-sub divisions for integration
                phi_vals = linspace(phi0 + (flute-1)*2*pi/nTeeth, ...
                                    phi0 + dPhi + (flute-1)*2*pi/nTeeth, ...
                                    int_k );
                g_vals   = zeros(size(phi_vals));
                
                for kk = 1:length(phi_vals)
                    phik = phi_vals(kk);
                    % Check if flute is in cut:
                    if (phik >= phiStart) && (phik <= phiEnd)
                        g_vals(kk) = 1;
                    else
                        g_vals(kk) = 0;
                    end
                end
                
                % Evaluate tangential+normal cutting factors in x-y
                % Kt cos(phi)+Kn sin(phi) => direction of Fx
                % -Kt sin(phi)+Kn cos(phi) => direction of Fy
                cosphi = cos(phi_vals);
                sinphi = sin(phi_vals);
                
                Fx_factor = (Kt*cosphi + Kn*sinphi);  % how displacement in x affects force in x
                Fy_factor = (-Kt*sinphi + Kn*cosphi); % how displacement in y affects force in y
                
                % In a fully coupled sense, let's suppose each of the 4 DOFs
                % are physical x,y transforms. We'll just build a sample cross-coupling.
                
                % For demonstration, let's let dof(1), dof(2) ~ X direction,
                % and dof(3), dof(4) ~ Y direction. We'll assume the same chip thickness
                % "ap_m" scales the partial derivatives. 
                % Summation = integral( g_vals * partial(...) ) dphi
                sum_hxx = sum( g_vals .* Fx_factor .* sinphi ) / int_k;
                sum_hxy = sum( g_vals .* Fx_factor .* cosphi ) / int_k;
                sum_hyx = sum( g_vals .* Fy_factor .* sinphi ) / int_k;
                sum_hyy = sum( g_vals .* Fy_factor .* cosphi ) / int_k;
                
                % Weighted by ap_m
                sum_hxx = sum_hxx * ap_m;
                sum_hxy = sum_hxy * ap_m;
                sum_hyx = sum_hyx * ap_m;
                sum_hyy = sum_hyy * ap_m;
                
                % We'll place these partial derivatives into a hypothetical 4x4:
                %   [ hxx  hxy  0    0   ]
                %   [ hxy  hxx  0    0   ]
                %   [ 0    0    hyy  hyx ]
                %   [ 0    0    hyx  hyy ]
                % This is just an EXAMPLE layout to show cross terms non-symmetric.
                
                dFdx_4x4(1,1) = dFdx_4x4(1,1) + sum_hxx;
                dFdx_4x4(1,2) = dFdx_4x4(1,2) + sum_hxy;
                dFdx_4x4(2,1) = dFdx_4x4(2,1) + sum_hxy; 
                dFdx_4x4(2,2) = dFdx_4x4(2,2) + (0.9*sum_hxx); % subtle difference => non-symmetric
                dFdx_4x4(3,3) = dFdx_4x4(3,3) + sum_hyy;
                dFdx_4x4(3,4) = dFdx_4x4(3,4) + sum_hyx;
                dFdx_4x4(4,3) = dFdx_4x4(4,3) + (1.05*sum_hyx); % again non-symmetric
                dFdx_4x4(4,4) = dFdx_4x4(4,4) + sum_hyy;   
            end
            
            % 6.2) Build the B_i matrix in first-order space => 2N x 2N
            % The top half (rows 1..N) is zero. The bottom half (rows N+1..2N) = -inv(M)*dFdx_4x4
            % because eqn: M ddot(x) = -C dx -K x + dFdx_4x4*x(t-tau).
            B_i = zeros(nStates,nStates);
            B_i(nDOF+1:end,1:nDOF) = -invM * dFdx_4x4;
            
            % 6.3) Build the "local" A_i for the sub-interval
            % If the structural part is also angle/time-varying, do it here.
            % Often M,C,K are constant, so A_free is the same. We'll keep A_free.
            A_i = A_free;
            
            % 6.4) Compute P_i and R_i
            P_i = expm(A_i*dt);
            R_i = (P_i - eye(nStates)) / A_i * B_i;
            
            % 6.5) Form the big transition block D_i of size (bigDim x bigDim)
            D_i = zeros(bigDim);
            
            % Place P_i in the top-left block
            D_i(1:nStates,1:nStates) = P_i;
            % Place R_i in columns for the delayed states
            % We'll do the usual 2-part interpolation => wa & wb
            D_i(1:nStates, (2*mSub + 1):(2*mSub + nDOF))      = wa * R_i(:,1:nDOF);
            D_i(1:nStates, (2*mSub + nDOF+1):(2*mSub+2*nDOF)) = wb * R_i(:,nDOF+1:2*nDOF);
            
            % Shift matrix logic: we replicate the "chain" approach
            % The next lines shift states downward by nStates in the big chain:
            dVec = ones(2*mSub,1);
            dVec(1:nStates) = 0;  % do not shift top nStates
            D_i = D_i + diag(dVec, -nStates);
            
            % Copy current states to top of chain
            for rr = 1:nStates
                D_i(nStates+rr, rr) = 1;
            end
            
            % Multiply into total Fi
            Fi_total = D_i * Fi_total;
        end
        
        % 6.6) After completing all sub-intervals => get final eigenvalues
        lambdaAll = eig(Fi_total);
        maxAbsEig = max(abs(lambdaAll));
        
        % Store
        idxSpeed = iSpeed+1;
        idxDepth = jDepth+1;
        SS(idxSpeed, idxDepth) = Omega_rpm;
        DC(idxSpeed, idxDepth) = ap_m*1000;       % in mm
        EI(idxSpeed, idxDepth) = maxAbsEig;
        
    end
    
    % Optional progress display
    if (mod(iSpeed,5)==0)
        fprintf('Progress: iSpeed=%d of %d, Speed=%.1f rpm\n',...
            iSpeed,nSpeedSteps,Omega_rpm);
    end
end

toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7) PLOT STABILITY LOBE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;
contour(SS, DC, EI, [1 1], 'k', 'LineWidth',2);
xlabel('Spindle Speed \Omega (rpm)');
ylabel('Depth of Cut a_p (mm)');
title('Advanced Semi-Discretization Stability Boundary (Non-symmetric M,C,K)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Functions (if needed) can appear below
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% No local function needed here for demonstration, but if you had separate
% "getCuttingMatrix" or "timeVaryingA", they'd go here.
