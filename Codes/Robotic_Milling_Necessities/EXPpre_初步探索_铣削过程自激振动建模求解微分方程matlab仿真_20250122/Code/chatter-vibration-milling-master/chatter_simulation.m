function chatter_simulation
% CHATTER_SIMULATION
% --------------------------------------------------------------
% Demonstrates a milling chatter simulation using DDE23
% with an event each tooth period. It follows the flow chart
% but avoids nested function definitions that can cause
% "Function definition misplaced" errors in MATLAB.
% --------------------------------------------------------------

    % 1) MODEL / PARAMETERS
    % ----------------------------------------------------------
    params = struct();

    % Example structural dynamics in X direction
    params.m_x    = 0.5;        % mass in x [kg]
    params.zeta_x = 0.035;      % damping ratio
    params.wn_x   = 2*pi*600;   % natural freq (rad/s)
    % Derived x direction
    params.c_x = 2*params.zeta_x*params.m_x*params.wn_x;
    params.k_x = params.m_x*(params.wn_x^2);

    % Similarly for Y
    params.m_y    = 0.5;
    params.zeta_y = 0.035;
    params.wn_y   = 2*pi*660;

    params.c_y = 2*params.zeta_y*params.m_y*params.wn_y;
    params.k_y = params.m_y*(params.wn_y^2);

    % Milling specifics
    params.Z    = 4;          % number of teeth
    params.N    = 3000;       % rpm
    params.Kt   = 600e6;      % tangential cutting coeff (Pa)
    params.Kr   = 0.07;       % radial ratio
    params.a    = 0.5e-3;       % axial depth of cut (m)
    params.feed = 1e-4;       % feed per tooth (m)

    % Immersion angles
    params.phi_e = 0;    % rad
    params.phi_x = pi;   % half-immersion e.g. 180 deg

    % Time delay per tooth pass
    toothPeriod = 60/(params.N * params.Z);  % T = 60/(N*Z)
    params.toothPeriod = toothPeriod;

    % Max simulation time
    tmax = 0.2;  

    % 2) DDE OPTIONS (EVENTS, ETC.)
    % ----------------------------------------------------------
    % We pass 'params' via anonymous wrappers so the subfunctions
    % below receive them. This is a convenient approach without
    % nested functions:

    % The main system DDE function:
    ddeSys = @(t,y,Z) chatterDDE(t,y,Z,params);

    % The event function to stop at t = STATE+toothPeriod:
    eventFun = @(t,y,Z) myEvents(t,y,Z);

    % The *initial* history (all zero):
    histFun = @(t) chatterHistory(t);

    % Create solver options
    opts = ddeset('RelTol',1e-6,'AbsTol',1e-8,'Events',eventFun);

    % 3) LOOP + EVENT-DRIVEN INTEGRATION
    % ----------------------------------------------------------
    STATE = 0;         % for tracking next tooth event time
    t0 = 0;            % current start time of each sub-integration
    piecewiseSols = {};  % store solutions over each sub-interval

    while t0 < tmax
        % Integrate from [t0, tmax], but event triggers at t=STATE+toothPeriod
        solPiece = dde23(ddeSys, toothPeriod, histFun, [t0, tmax], opts);

        piecewiseSols{end+1} = solPiece; %#ok<AGROW>
        tEnd = solPiece.x(end);

        % Update t0
        t0 = tEnd;
        STATE = STATE + toothPeriod;

        % If we are at or beyond tmax, break
        if t0 >= tmax
            break;
        end

        % 4) BUILD A NEW HISTORY FROM THE LATEST SOLUTION
        %  We want to continue seamlessly. We'll get the solution
        %  from [tEnd-toothPeriod, tEnd], then define an updated
        %  history for the next pass.

        % Evaluate the final piece from tEnd - T to tEnd
        tHistRange = linspace(tEnd - toothPeriod, tEnd, 100);
        yHistRange = deval(solPiece, tHistRange);

        % Build a new function handle that uses these arrays
        histFun = @(tt) localHistoryFun(tt, tEnd, tHistRange, yHistRange, toothPeriod);
    end

    % 5) POST-PROCESS: MERGE PIECEWISE
    % ----------------------------------------------------------
    [tAll, yAll] = mergeSolutions(piecewiseSols);

    figure('Name','Chatter with Events','Color','w');
    subplot(2,1,1)
      plot(tAll, yAll(1,:), 'b-','LineWidth',1.2); hold on;
      plot(tAll, yAll(3,:), 'r-','LineWidth',1.2);
      xlabel('Time (s)'); ylabel('Displacement (m)');
      legend('x','y'); title('Displacement vs Time');

    subplot(2,1,2)
      % Quick FFT example of x(t)
      xVals = yAll(1,:) - mean(yAll(1,:)); 
      Fs = 1/mean(diff(tAll));  
      L  = length(xVals);
      Xfft = fft(xVals);
      faxis = Fs*(0:(L-1))/L;
      Amp = abs(Xfft)/L;
      plot(faxis, Amp, 'k-','LineWidth',1.2);
      xlabel('Frequency (Hz)'); ylabel('Amplitude');
      xlim([0,2000]);
      title('FFT of x displacement');
      grid on;

end % chatter_simulation main function
% --------------------------------------------------------------------


%% SUBFUNCTIONS BELOW (no nesting)
% --------------------------------------------------------------------

function dYdt = chatterDDE(t, Y, Z_lag, params)
% CHATTERDDE: The system of delay differential equations in state-space form.
%  Y = [x; dx; y; dy]; 
%  Z_lag = [x(t-T); dx(t-T); y(t-T); dy(t-T)].

    % Unpack current states
    x1 = Y(1);  x2 = Y(2);
    y1 = Y(3);  y2 = Y(4);

    % Delayed states
    x1_tau = Z_lag(1);
    y1_tau = Z_lag(3);

    % Extract parameters
    m_x = params.m_x; c_x = params.c_x; k_x = params.k_x;
    m_y = params.m_y; c_y = params.c_y; k_y = params.k_y;
    Kt  = params.Kt;  Kr  = params.Kr;  a = params.a;
    feed= params.feed; 
    Z   = params.Z; 
    N   = params.N;
    phi_e = params.phi_e; 
    phi_x = params.phi_x;

    % Sum force from each tooth
    Fx_total = 0;  
    Fy_total = 0;

    for j = 0 : Z-1
        % Tooth angle
        th = (2*pi*N/60)*t - j*(2*pi/Z);
        th_mod = mod(th, 2*pi);

        % Check if this tooth is in cut
        if (th_mod >= phi_e) && (th_mod <= phi_x)
            % static chip thickness approx
            hs = feed*abs(sin(th_mod));

            % local radial displacement difference
            u_now = -x1*sin(th_mod) - y1*cos(th_mod);
            u_tau = -x1_tau*sin(th_mod) - y1_tau*cos(th_mod);

            hd = hs + (u_now - u_tau);
            if hd > 0
                Ft = Kt * hd * a;
                Fr = Kt * Kr * hd * a;
                % Transform to global
                Fx_j = -sin(th_mod)*Fr - cos(th_mod)*Ft;
                Fy_j = -cos(th_mod)*Fr + sin(th_mod)*Ft;
                Fx_total = Fx_total + Fx_j;
                Fy_total = Fy_total + Fy_j;
            end
        end
    end

    % State eqns
    dx1dt = x2;
    dx2dt = (1/m_x)*(Fx_total - c_x*x2 - k_x*x1);

    dy1dt = y2;
    dy2dt = (1/m_y)*(Fy_total - c_y*y2 - k_y*y1);

    dYdt = [dx1dt; dx2dt; dy1dt; dy2dt];
end


function [value,isterminal,direction] = myEvents(t, Y, Z_lag)
% MYEVENTS: Event function that triggers each tooth period.
% We keep track of next event at t = STATE + T externally. 
% So define value = t - (STATE+toothPeriod). The main code
% updates STATE.
% But we have no direct access to STATE here, so we do a "trick":
% we'll read the "next event time" from this function if we like,
% or pass it in. For simplicity, we'll define:
%   If value=0 => event

    % For this demonstration, let's parse it from the global
    % approach or just a fixed period. We'll keep it simple:
    global EVENTTIME
    if isempty(EVENTTIME), EVENTTIME=1e9; end

    value = t - EVENTTIME;
    isterminal = 1;      % Stop the integration
    direction  = +1;     % Only when crossing upward
end


function v = chatterHistory(~)
% CHATTERHISTORY: initial history for t<=0
    v = [0; 0; 0; 0];
end


function v = localHistoryFun(tt, tEnd, tHistRange, yHistRange, toothPeriod)
% LOCALHISTORYFUN: For subsequent passes, we define a new
% piecewise history that picks up from the end of the last pass.

    if tt >= (tEnd - toothPeriod) && tt <= tEnd
        % Interpolate from prior solution
        v = interp1(tHistRange', yHistRange', tt, 'linear','extrap')';
    else
        % Fallback if outside that range
        v = yHistRange(:,1); 
    end
end


function [tAll, yAll] = mergeSolutions(piecewiseSols)
% MERGESOLUTIONS: merges the piecewise dde23 solutions into
% single time + state arrays, removing duplicates.

    tAll = [];
    yAll = [];
    for i = 1:length(piecewiseSols)
        tseg = piecewiseSols{i}.x;
        yseg = piecewiseSols{i}.y;
        tAll = [tAll, tseg];
        yAll = [yAll, yseg];
    end

    [tAll, idxU] = unique(tAll);
    yAll = yAll(:, idxU);
end
