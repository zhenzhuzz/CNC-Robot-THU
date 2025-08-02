%% 半离散法求解稳定性叶瓣图（质量）
%% From： Updated semi-discretization method for periodic delay-differential equations with discrete delay
clc;clear
tic
%%  parameters
N=2; % number of teeth
Kt=6e8; % tangential cutting force coefficient(N/m2)
Kn=2e8; % normal cutting force coefficient(N/m2)
w0x=922*2*pi; % angular natural frequency x (rad/s)
zetax=0.011; % relative damping x (1)
w0y=922*2*pi; % angular natural frequency y (rad/s)
zetay=0.011; % relative damping y (1)
m_tx=0.03993; % mass x (kg)
m_ty=0.03993; % mass y (kg)
aD=0.5; % radial depth of cut

%% Up or down milling
up_or_down=-1; % 1: up-milling, -1: down-milling
if up_or_down == 1 % up-milling
    fist=0; % start angle
    fiex=acos(1-2*aD); % exit anlge
elseif up_or_down == -1 % down-milling
    fist=acos(2*aD -1); % start angle
    fiex=pi; % exit angle
end
stx=50; % steps of spindle speed
sty=20; % steps of depth of cut
w_st=0e-3; % starting depth of cut (m)
w_fi=10e-3; % final depth of cut (m)
o_st=5e3; % starting spindle speed (rpm)
o_fi=25e3; % final spindle speed (rpm)
%% computational parameters
k=20; % number of discretization interval over one
intk=20; % number of numerical integration steps forEquation (37)
m=k; % since time delay=time period
wa=0.5; % since time delay=time period
wb=0.5; % since time delay=time period
D=zeros(2*m+4, 2*m+4); % matrix D
d=ones(2*m+2,1);
d(1:4)=0;
D=D+diag(d,-2);
D(5, 1)=1;
D(6, 2)=1;
% numerical integration of specific cutting force coefficient according to Equations (40)–(43)
for i=1:k
    dtr=2*pi/N/k; %dtrt, if tao=2/N
    hxx(i)=0;
    hxy(i)=0;
    hyx(i)=0;
    hyy(i)=0;
    for j=1:N % loop for tooth j
        for h=1:intk; % loop for numerical integration of hi
            fi(h) = i*dtr +(j-1)*2*pi/N + h*dtr / intk;
            if (fi(h)>=fist)*(fi(h)<=fiex)
                g(h)=1; % tooth is in the cut
            else
                g(h)=0; % tooth is out of cut
            end
        end
        hxx(i)=hxx(i)+sum(g.*(Kt.* cos(fi)+Kn.* sin(fi)).* sin(fi))/intk;
        hxy(i)=hxy(i)+sum(g.*(Kt.* cos(fi)+Kn.* sin(fi)).* cos(fi))/intk;
        hyx(i)=hyx(i)+sum(g.*(-Kt* sin(fi)+Kn.* cos(fi)).* sin(fi))/intk;
        hyy(i)=hyy(i)+sum(g.*(-Kt* sin(fi)+Kn.* cos(fi)).* cos(fi))/intk;
    end
end
%% start of computation
for x=1:stx+1 % loop for spindle speeds
    o=o_st +(x -1)*(o_fi-o_st)/stx; % spindle speed
    tau=60/o/N; % time delay
    dt=tau/(m); % time step
    for y=1:sty+1 % loop for depth of cuts
        w=w_st+(y-1)*(w_fi-w_st)/sty; % depth of cut
        % construct transition matrix Fi
        Fi=eye(2*m+4, 2*m+4);
        for i=1:m
            A=zeros(4, 4); % matrix Ai
            A(1, 3)=1;
            A(2, 4)=1;
            A(3, 1)=-w0x^2-hxx(i)*w/m_tx;
            A(3, 2)=-hxy(i)*w/m_tx;
            A(3, 3)=-2*zetax*w0x;
            A(4, 1)=-hyx(i)*w/m_ty;
            A(4, 2)=-w0y^2-hyy(i)*w/m_ty;
            A(4, 4)=-2*zetay*w0y;
            B=zeros(4, 4); % matrix Bi
            B(3, 1)=hxx(i)*w/m_tx;
            B(3, 2)=hxy(i)*w/m_tx;
            B(4, 1)=hyx(i)*w/m_ty;
            B(4, 2)=hyy(i)*w/m_ty;
            P=expm(A*dt); % matrix Pi
            R=(expm(A*dt)-eye(4))*inv(A)*B; % matrix Ri
            D(1:4, 1:4)=P;
            D(1:4, (2*m+1):(2*m+2))=wa*R(1:4, 1:2);
            D(1:4, (2*m+3):(2*m+4))=wb*R(1:4, 1:2);
            Fi=D*Fi; % transition matrix 
        end
        ss(x, y)=o; % matrix of spindle speeds
        dc(x, y)=w*1000; % matrix of depth of cuts
        ei(x, y)=max(abs(eig(Fi))); % matrix of eigenvalues
    end
    stx+1-x
end
toc
SLD = figure;
contour(ss,dc,ei,[1, 1],'k');
xlabel('Spindle speed \Omega (rpm)');
ylabel('Depth of cut a_p (mm)');
title('SemiDM-2DOF');