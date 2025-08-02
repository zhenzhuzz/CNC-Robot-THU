

function chatter_simulation
% CHATTER_SIMULATION
% --------------------------------------------------------------
% A revised version that:
%  1) Uses a loop from t0 to t0 + toothPeriod each pass,
%  2) Updates waitbar and text each iteration,
%  3) Plots displacement in a 3x1 figure: x(t), y(t), FFT of x(t).
%  4) Also includes a separate figure for velocity and Poincare map.
% --------------------------------------------------------------

    % 1) MODEL / PARAMETERS
    % ----------------------------------------------------------
    params = struct();

    % Structural dynamics (x-direction)
    params.m_x    = 0.5;            % mass in x [kg]
    params.zeta_x = 0.035;          % damping ratio
    params.wn_x   = 2*pi*600;       % natural freq (rad/s)
    % Derived
    params.c_x = 2*params.zeta_x*params.m_x*params.wn_x;
    params.k_x = params.m_x*(params.wn_x^2);

    % Structural dynamics (y-direction)
    params.m_y    = 0.5;
    params.zeta_y = 0.035;
    params.wn_y   = 2*pi*660;
    % Derived
    params.c_y = 2*params.zeta_y*params.m_y*params.wn_y;
    params.k_y = params.m_y*(params.wn_y^2);

    % Milling specifics
    params.Z    = 4;             % number of teeth
    params.N    = 3000;          % rpm
    params.Kt   = 600e6;         % tangential cutting coeff (Pa)
    params.Kr   = 0.07;          % radial ratio
    params.a    = 2e-3;          % axial depth of cut (m)
    params.feed = 1e-4;          % feed per tooth (m)

    % Immersion angles
    params.phi_e = 0;    % rad
    params.phi_x = pi;   % half-immersion

    % Time delay per tooth pass
    T = 60/(params.N * params.Z); 
    params.toothPeriod = T;

    % Simulation length
    tmax = 0.2;  % Try 0.2 s so we see multiple passes

    % 2) SET UP: Each pass from [t0, t0+T]
    % ----------------------------------------------------------
    % We'll do about this many passes:
    passCountEst = ceil(tmax / T);

    % System DDE function and initial history
    ddeSys  = @(t,y,Z) chatterDDE(t,y,Z,params);
    histFun = @(t) chatterHistory(t);  % zero for t <= 0

    % No event needed for each pass because we run exactly [t0, t0+T].
    opts = ddeset('RelTol',1e-6,'AbsTol',1e-8);

    % Prepare storage for piecewise solutions
    piecewiseSols = {};

    % WAITBAR
    handle = waitbar(0, 'Please wait... simulation in progress.');

    % 3) LOOP: Solve pass by pass
    % ----------------------------------------------------------
    t0 = 0;  % start time
    for passIndex = 1:passCountEst
        % If next pass would exceed tmax, reduce the upper limit
        t1 = t0 + T;
        if t1 > tmax
            t1 = tmax;
        end

        % Update waitbar
        fractionDone = min(passIndex / passCountEst, 1);
        waitbar(fractionDone, handle, ...
            sprintf('Simulation in progress... pass %d / %d', ...
                    passIndex, passCountEst));
        drawnow; % Force GUI refresh

        % Solve from [t0, t1]
        solPiece = dde23(ddeSys, T, histFun, [t0, t1], opts);

        % Store solution
        piecewiseSols{end+1} = solPiece; %#ok<AGROW>

        % Output a line of text
        fprintf('Completed pass %d:  [%.4f, %.4f] s\n', passIndex, t0, t1);

        % Update t0
        tEnd = solPiece.x(end);
        t0   = tEnd;
        if t0 >= tmax
            break;
        end

        % Build new history from [tEnd - T, tEnd]
        tHistRange = linspace(tEnd - T, tEnd, 200); % 200 points for interpolation
        yHistRange = deval(solPiece, tHistRange);

        % Next pass history function
        histFun = @(tt) localHistoryFun(tt, tEnd, tHistRange, yHistRange, T);
    end

    % Close waitbar
    close(handle);

    % 4) Merge piecewise solutions
    % ----------------------------------------------------------
    [tAll, yAll] = mergeSolutions(piecewiseSols);

    % 5) PLOTTING
    % ----------------------------------------------------------
    % --(A) 3x1 subplot: x(t), y(t), and FFT of x(t)
    figure('Name','Displacement & FFT','Color','w');
    
    % Subplot 1: x displacement
    subplot(3,1,1)
      plot(tAll, yAll(1,:), 'b-','LineWidth',1.2);
      xlabel('Time (s)');
      ylabel('x displacement (m)');
      title('x(t) vs time');

    % Subplot 2: y displacement
    subplot(3,1,2)
      plot(tAll, yAll(3,:), 'r-','LineWidth',1.2);
      xlabel('Time (s)');
      ylabel('y displacement (m)');
      title('y(t) vs time');

    % Subplot 3: FFT of x(t)
    subplot(3,1,3)
      xVals = yAll(1,:) - mean(yAll(1,:));
      dt    = mean(diff(tAll));
      Fs    = 1/dt;
      L     = length(xVals);
      Xfft  = fft(xVals);
      faxis = Fs*(0:(L-1))/L;
      Amp   = abs(Xfft)/L;
      plot(faxis, Amp, 'k-','LineWidth',1.2);
      xlabel('Frequency (Hz)'); ylabel('Amplitude');
      xlim([0,2000]); 
      title('FFT of x(t) displacement');
      grid on;

    % --(B) Velocity plot
    figure('Name','Velocities','Color','w');
    subplot(2,1,1)
      plot(tAll, yAll(2,:), 'b-','LineWidth',1.2);
      xlabel('Time (s)');
      ylabel('dx/dt (m/s)');
      title('Velocity in X direction');

    subplot(2,1,2)
      plot(tAll, yAll(4,:), 'r-','LineWidth',1.2);
      xlabel('Time (s)');
      ylabel('dy/dt (m/s)');
      title('Velocity in Y direction');

    % --(C) Poincaré Plot (sample x,dx at multiples of tooth period)
    tPoincare = 0 : T : tAll(end);
    xP  = zeros(size(tPoincare));
    dxP = zeros(size(tPoincare));
    for i=1:length(tPoincare)
        if tPoincare(i) <= tAll(end)
            Yp = ddevalPiecewise(piecewiseSols, tPoincare(i));
            xP(i)  = Yp(1);
            dxP(i) = Yp(2);
        end
    end

    figure('Name','Poincare Map','Color','w');
    plot(xP, dxP, 'ko','MarkerFaceColor','b','MarkerSize',5);
    xlabel('x'); ylabel('dx/dt');
    title('Poincaré map at multiples of tooth period');
    grid on;
end
% --------------------------------------------------------------------
%  SUBFUNCTIONS
% --------------------------------------------------------------------

function dYdt = chatterDDE(t, Y, Z_lag, params)
    % The chatter DDE system in state-space form
    % Y = [x; dx; y; dy], Z_lag = [x(t-T); dx(t-T); y(t-T); dy(t-T)]
    x1 = Y(1); x2 = Y(2);
    y1 = Y(3); y2 = Y(4);

    x1_tau = Z_lag(1); 
    y1_tau = Z_lag(3);

    m_x = params.m_x; c_x = params.c_x; k_x = params.k_x;
    m_y = params.m_y; c_y = params.c_y; k_y = params.k_y;
    Kt  = params.Kt;  Kr  = params.Kr;  a  = params.a;
    feed= params.feed; 
    Z   = params.Z; 
    N   = params.N;
    phi_e = params.phi_e; 
    phi_x = params.phi_x;

    Fx_total = 0;
    Fy_total = 0;

    for j = 0 : Z-1
        th     = (2*pi*N/60)*t - j*(2*pi/Z);
        th_mod = mod(th, 2*pi);

        if (th_mod >= phi_e) && (th_mod <= phi_x)
            % Simple feed model
            hs = feed*abs(sin(th_mod));
            u_now = -x1*sin(th_mod) - y1*cos(th_mod);
            u_tau = -x1_tau*sin(th_mod) - y1_tau*cos(th_mod);
            hd = hs + (u_now - u_tau);

            if hd > 0
                Ft = Kt * hd * a;
                Fr = Kt * Kr * hd * a;
                Fx_j = -sin(th_mod)*Fr - cos(th_mod)*Ft;
                Fy_j = -cos(th_mod)*Fr + sin(th_mod)*Ft;
                Fx_total = Fx_total + Fx_j;
                Fy_total = Fy_total + Fy_j;
            end
        end
    end

    dx1dt = x2;
    dx2dt = (1/m_x)*(Fx_total - c_x*x2 - k_x*x1);
    dy1dt = y2;
    dy2dt = (1/m_y)*(Fy_total - c_y*y2 - k_y*y1);

    dYdt = [dx1dt; dx2dt; dy1dt; dy2dt];
end

function v = chatterHistory(~)
    % Zero history for t<=0
    v = [0;0;0;0];
end

function v = localHistoryFun(tt, tEnd, tHistRange, yHistRange, T)
    % Interpolate from the last pass's solution if tt in [tEnd-T, tEnd].
    if (tt >= tEnd - T) && (tt <= tEnd)
        v = interp1(tHistRange', yHistRange', tt, 'linear','extrap')';
    else
        % Fallback if outside that range
        v = yHistRange(:,1);
    end
end

function [tAll, yAll] = mergeSolutions(piecewiseSols)
    % Combine time & states from each pass
    tAll = [];
    yAll = [];
    for i = 1:length(piecewiseSols)
        tseg = piecewiseSols{i}.x;
        yseg = piecewiseSols{i}.y;
        tAll = [tAll, tseg];
        yAll = [yAll, yseg];
    end
    % Remove duplicates
    [tAll, idxU] = unique(tAll);
    yAll = yAll(:, idxU);
end

function Yp = ddevalPiecewise(piecewiseSols, tquery)
    % Evaluate piecewise solution at time tquery by finding
    % which piece covers that time
    for i = 1:length(piecewiseSols)
        if tquery >= piecewiseSols{i}.x(1) && tquery <= piecewiseSols{i}.x(end)
            Yp = deval(piecewiseSols{i}, tquery);
            return
        end
    end
    % If out of range, return last known point
    Yp = deval(piecewiseSols{end}, piecewiseSols{end}.x(end));
end
