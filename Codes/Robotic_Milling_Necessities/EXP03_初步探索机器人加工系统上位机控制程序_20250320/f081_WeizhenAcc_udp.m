
clear;
clc;
close all;

u = udpport("datagram", ...
"LocalHost","192.168.88.2", ...
"LocalPort",1600);

u.Timeout=5;
u.OutputDatagramSize = 65500;

disp("Listening on 192.168.88.2:1600...");
disp("Press Ctrl + C to stop.");

data = read(u,u.NumDatagramsAvailable,'string');
disp(data);
