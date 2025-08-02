clc;
clear all;

% Step 1: List all available DAQ devices
devices = daqlist;
disp("Available DAQ Devices:");
disp(devices);
deviceInfo = devices{:, "DeviceInfo"}

% Step 2: Create a DataAcquisition object for the vendor
dq = daq("ni"); % Replace "ni" with your specific vendor if different
dq.Rate = 12800;


% Step 3: Add an input channel (adjust as per your device ID and channel)
ch = addinput(dq, "cDAQ1Mod1", "ai0", "Accelerometer"); % Replace "Dev1" and "ai0" as per your setup

% Step 4: Display all available ranges
disp(ch.Range);

%%

clc;
clear all;
d = daq("ni");
ch1 = addinput(d,"cDAQ2Mod2","ai0","Voltage");
ch2 = addoutput(d,"cDAQ2Mod3","ao0","Voltage");
d.Channels

outData = linspace(-1,10,3000)';

inData = readwrite(d,outData,"OutputFormat","Matrix");
plot(inData)