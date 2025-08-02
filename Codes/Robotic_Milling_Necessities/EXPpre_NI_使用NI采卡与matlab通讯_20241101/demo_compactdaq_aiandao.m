%% Simultaneously Acquire Data and Generate Signals
%
% This example shows how to acquire and generate data using two National
% Instruments modules operating at the same time.

% Copyright 2010-2019 The MathWorks, Inc.

clc;
clear all;

%% Create a DataAcquisition
% Use |daq| to create a DataAcquisition
dq = daq("ni")

%%  Set up Hardware
% This example uses a compactDAQ chassis NI c9174 with NI 9234 (cDAQ1Mod1 -
% 4 analog input channels) module and NI 9263 (cDAQ1Mod2 - 4 analog output
% channels) module. Use |daqlist| to obtain more information about
% connected hardware.
%
% The analog output channels are physically connected to the analog input
% channels so that the acquired data is the same as the data generated from
% the analog output channel.

%% Add an Analog Input Channel and an Analog Output Channel
% Use |addinput| to add an analog input voltage channel.
% Use |addoutput| to add an analog output voltage channel.
addinput(dq, "cDAQ2Mod3", "ai0", "Voltage")
% addoutput(dq, "cDAQ2Mod2", "ao0", "Voltage") 
% dq.Rate = 25600; % Match the desired sampling rate

%% Create and Plot the Output Signal
% output = cos(linspace(0,2*pi,30000)');
% preload(dq,output);
start(dq,"Duration",seconds(30))

% plot(output);
% title("Output Data");
dataAll = [];
timestampsAll = [];

chunkDuration = seconds(1);
while dq.Running
    [data, timestamps] = read(dq,chunkDuration,OutputFormat="Matrix");
    dataAll = [dataAll; data];
    timestampsAll = [timestampsAll; timestamps];
    plot(timestampsAll,dataAll)
    pause(0.5*seconds(chunkDuration))
end
%% Generate and Acquire Data
% Use |readwrite| to generate and acquire scans simultaneously.
data1 = read(dq, output);

%% Plot the Acquired Data 
plot(data1.Time, data1.Variables);
ylabel("Voltage (V)")
title("Acquired Signal");

%% Generate and Acquire Date for Twice the Previous Duration
data2 = read(dq, [output; output]);

%% Plot the Acquired Data 
plot(data2.Time, data2.Variables);
ylabel("Voltage (V)")
title("Acquired Signal");
