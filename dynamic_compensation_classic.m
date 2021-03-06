function [vref,x] = dynamic_compensation_classic(vcp, vc, v, x, x_init, k3, k4, ts)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
mu_l = v(1);
mu_m = v(2);
mu_n = v(3);
omega = v(4);

%% Gain Matrices
K3 = k3*eye(size(v,1));
K4 = k4*eye(size(v,1));

% INERCIAL MATRIX
M11=x(1);
M12=0;
M13=0;
M14=x(2);
M21=0;
M22=x(3);
M23=0;
M24=0;
M31=0;
M32=0;
M33=x(4);
M34=0;
M41=x(5);
M42=0;
M43=0;
M44=x(6);



M=[M11,M12,M13,M14;...
    M21,M22,M23,M24;...
    M31,M32,M33,M34;...
    M41,M42,M43,M44];

%% CENTRIOLIS MATRIX
C11=x(7);
C12=x(8)+x(9)*omega;
C13=x(10);
C14=x(11);
C21=x(12)+x(13)*omega;
C22=x(14);
C23=x(15);
C24=x(16)+x(17)*omega;
C31=x(18);
C32=x(19);
C33=x(20);
C34=x(21);
C41=x(22);
C42=x(23)+x(24)*omega;
C43=x(25);
C44=x(26);

C=[C11,C12,C13,C14;...
    C21,C22,C23,C24;...
    C31,C32,C33,C34;...
    C41,C42,C43,C44];

%% GRAVITATIONAL MATRIX
G11=0;
G21=0;
G31=x(27);
G41=0;

G=[G11;G21;G31;G41];


%% REGRESOR SYSTEM
mu_ld = vc(1);
mu_md = vc(2);
mu_nd = vc(3);
omega_d = vc(4);

mu_ldp = vcp(1);
mu_mdp = vcp(2);
mu_ndp = vcp(3);
omega_dp = vcp(4);

Y = [ mu_ldp, omega_dp, 0, 0, 0, 0, mu_ld, mu_md, mu_md*omega, mu_nd, omega_d, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;...
      0, 0, mu_mdp, 0, 0, 0, 0, 0, 0, 0, 0, mu_ld, mu_ld*omega, mu_md, mu_nd, omega_d, omega*omega_d, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;...
      0, 0, 0, mu_ndp, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, mu_ld, mu_md, mu_nd, omega_d, 0, 0, 0, 0, 0, 1;...
      0, 0, 0, 0, mu_ldp, omega_dp, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, mu_ld, mu_md, mu_md*omega, mu_nd, omega_d, 0];

%% Control error veclocity
ve = v-vc;

%% Controller gain
Kp = 10*eye(4);
K = 0.8*eye(27);

%% Adaptation Law
xp = -inv(K)*Y'*ve;
x = x + xp*ts;

control =Y*x-Kp*ve;
% control =Y*x_init-Kp*ve;

vref = control;
% 


end
