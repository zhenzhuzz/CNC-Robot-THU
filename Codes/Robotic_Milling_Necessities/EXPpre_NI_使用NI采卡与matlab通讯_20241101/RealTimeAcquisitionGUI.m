function RealTimeAcquisitionGUI
    % Main function to initialize the GUI
    % Create a figure window
    fig = figure('Name', 'Real-Time Data Acquisition', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 800, 600], ...
                 'CloseRequestFcn', @stopAcquisition);

    % Initialize UI components
    uicontrol(fig, 'Style', 'text', ...
                   'String', 'Real-Time Data Acquisition from NI 9234', ...
                   'FontSize', 14, ...
                   'Position', [250, 550, 300, 30]);

    % Start button
    startButton = uicontrol(fig, 'Style', 'pushbutton', ...
                                 'String', 'Start', ...
                                 'Position', [100, 500, 100, 40], ...
                                 'Callback', @startAcquisition);

    % Stop button
    stopButton = uicontrol(fig, 'Style', 'pushbutton', ...
                                'String', 'Stop', ...
                                'Position', [600, 500, 100, 40], ...
                                'Callback', @stopAcquisition, ...
                                'Enable', 'off');

    % Axes for time-domain plot
    timeAxes = axes(fig, 'Position', [0.1, 0.3, 0.35, 0.4]);
    title(timeAxes, 'Time-Domain Signal');
    xlabel(timeAxes, 'Time (s)');
    ylabel(timeAxes, 'Amplitude');

    % Axes for frequency-domain plot (FFT)
    freqAxes = axes(fig, 'Position', [0.55, 0.3, 0.35, 0.4]);
    title(freqAxes, 'Frequency-Domain (FFT)');
    xlabel(freqAxes, 'Frequency (Hz)');
    ylabel(freqAxes, 'Magnitude');

    % Create data acquisition session
    session = daq.createSession('ni');
    session.Rate = 25600; % Sampling rate
    session.IsContinuous = true;

    % Add an analog input channel for the NI 9234 (channel 1 in this example)
    addAnalogInputChannel(session, 'cDAQ1Mod1', 0, 'IEPE');
    session.Channels(1).Range = [-5 5]; % Set range for IEPE accelerometer
    
    % Initialize variables for live data plotting
    bufferSize = 1024; % Size of data buffer for display
    timeData = zeros(bufferSize, 1);
    fftData = zeros(bufferSize, 1);
    timeVec = (0:(bufferSize-1)) / session.Rate;

    % Plot handles (for updating plots)
    timePlot = plot(timeAxes, timeVec, timeData);
    fftPlot = plot(freqAxes, linspace(0, session.Rate/2, bufferSize/2), fftData(1:bufferSize/2));
    
    % Callback functions
    function startAcquisition(~, ~)
        % Enable and disable appropriate buttons
        startButton.Enable = 'off';
        stopButton.Enable = 'on';

        % Start continuous acquisition
        session.startBackground();
        
        % Continuous data handling using listener
        lh = addlistener(session, 'DataAvailable', @processData);
    end

    function processData(~, event)
        % Update the time data
        timeData = event.Data(:, 1);
        set(timePlot, 'YData', timeData);

        % Perform FFT and update FFT plot
        fftResult = abs(fft(timeData)) / bufferSize;
        set(fftPlot, 'YData', fftResult(1:bufferSize/2));

        % Update plots in real-time
        drawnow;
    end

    function stopAcquisition(~, ~)
        % Stop acquisition and remove listener
        session.stop();
        delete(lh); % Delete listener to free resources

        % Reset button states
        startButton.Enable = 'on';
        stopButton.Enable = 'off';
    end

    % Set default figure close behavior
    function closeRequest(src, ~)
        % Stop acquisition if ongoing
        if session.IsRunning
            session.stop();
        end
        delete(gcf); % Close the figure window
    end
end
