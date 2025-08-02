% Example on how to do a discrete Fourier transform (FFT) from 
% accelerometer data for acceleration, velocity and position
% Author: Mathias Magdowski
% E-Mail: mathias.magdowski@ovgu.de
% Date: 2023-01-05
% Video: https://youtu.be/U0qcDyM6e6w

% clear the workspace
clear all
% clear all open figures
close all

% load the raw data from a text file -> matrix
rawdata=load('test_951.txt');
% time steps (in s) -> vector
t=rawdata(:,1);
% time-dependent acceleration (in m/s²) -> vector
a_t=rawdata(:,2);
% start time for the analysis (in s) -> scalar
t_start=15;
% end time for the analysis (in s) -> scalar
t_end=25;
% index of the start time for the analysis -> integer
t_start_index=find(t>=t_start,1,'first');
% index of the end time for the analysis -> integer
t_end_index=find(t>=t_end,1,'first');
% window the time steps (in s) -> vector
t=t(t_start_index:t_end_index);
% window the time-dependent acceleration (in m/s²) -> vector
a_t=a_t(t_start_index:t_end_index);
% plot the time-dependent acceleration
figure(1)
plot(t,a_t);
xlabel('time in s')
ylabel('acceleration in m/s²')
grid on

% calculate the time-dependent velocity (in m/s) by numerical integration -> vector
v_t=cumtrapz(t,a_t);
% plot the time-dependent velocity
figure(2)
plot(t,v_t);
xlabel('time in s')
ylabel('velocity in m/s')
grid on

% calculate the time-dependent position (in m) by numerical integration -> vector
x_t=cumtrapz(t,v_t);
% detrend the time-dependent position (in m) -> vector
x_t=detrend(x_t,4);
% plot the time-dependent position
figure(3)
plot(t,x_t);
xlabel('time in s')
ylabel('position in m')
grid on

% set the first time step to zero -> vector
t=t-t(1);
% calculate the spectrum and the corresponding frequencies of the periodic change of position using a discrete Fourier transform -> vector
[f,X_f]=fourier(t,x_t,'sinus');
% plot the magnitude spectrum of the periodic change of position
figure(4)
loglog(f,abs(X_f))
xlabel('frequency in Hz')
ylabel('periodic change of position in m')
grid on

% output the numerical results
disp('Results from the FFT of the position:')
disp(['resonant frequency: ',num2str(f(find(abs(X_f)==max(abs(X_f))))),' Hz']);
disp(['periodic change of position: ',num2str(max(abs(X_f))),' m']);

% calculate the spectrum and the corresponding frequencies of the periodic change of acceleration using a discrete Fourier transform -> vector
[~,A_f]=fourier(t,a_t,'sinus');
% plot the magnitude spectrum of the periodic change of acceleration
figure(5)
loglog(f,abs(A_f))
xlabel('frequency in Hz')
ylabel('maximum periodic change of acceleration in m/s²')
grid on

% frequency of the main spectral component (in Hz) -> scalar
f_res=f(find(abs(A_f)==max(abs(A_f))));
% maximum periodic change of acceleration (in m/s²) -> scalar
a_max=max(abs(A_f));
% angular frequency of the main spectral component (in 1/s) -> scalar
omega_res=2*pi*f_res;
% maximum periodic change of velocity (in m/s) -> scalar
v_max=a_max/omega_res;
% maximum periodic change of position (in m) -> scalar
x_max=v_max/omega_res;
% output the numerical results
disp('Results from the FFT of the acceleration:')
disp(['resonant frequency: ',num2str(f_res),' Hz']);
disp(['maximum periodic change of acceleration: ',num2str(a_max),' m/s²']);
disp(['maximum periodic change of velocity: ',num2str(v_max),' m/s']);
disp(['maximum periodic change of position: ',num2str(x_max),' m']);

% calculate the spectrum and the corresponding frequencies of the periodic change of velocity using a discrete Fourier transform -> vector
[~,V_f]=fourier(t,v_t,'sinus');
% plot the magnitude spectrum of the periodic change of velocity
figure(6)
loglog(f,abs(V_f))
xlabel('frequency in Hz')
ylabel('maximum periodic change of velocity in m/s')
grid on
