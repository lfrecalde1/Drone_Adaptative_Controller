%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
%XXXXXXXXXXXXXXXXXXX TRAJECTORY CONTROL DJI DRONE XXXXXXXXXXXXXXXXXXXXXXXXX
%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

%% CLEAN VARIABLES
clc,clear all,close all;

%% DEFINITION OF TIME VARIABLES
ts = 0.1;
tf = 100;
to = 0;
t = (to:ts:tf);

%% CONSTANTS VALUES OF THE ROBOT
a = 0.1; 
b = 0.1;
c = 0.0;
L = [a, b, c];

%% INITIAL CONDITIONS
x = 0.0;
y = 0.0;
z = 0;
yaw = 0*(pi/180);

%% DIRECT KINEMATICS
x = x +a*cos(yaw) - b*sin(yaw);
y = y +a*sin(yaw) + b*cos(yaw);
z = z + c;

h = [x;...
     y;...
     z;...
     yaw];
 
%% INITIAL GENERALIZE VELOCITIES
v = [0;...
     0;...
     0;...
     0];

H = [h;v];
%% DESIRED SIGNALS OF THE SYSYEM
[hxd, hyd, hzd, hthd, hxdp, hydp, hzdp, hthdp] = Trajectory(t,ts,4);

%% GENERALIZED DESIRED SIGNALS
hd = [hxd;...
      hyd;...
      hzd;...
      hthd];
  
hdp = [hxdp;...
       hydp;...
       hzdp;...
       hthdp];
      
        
%% LOAD DYAMIC PARAMETERS DRONE
load("parameters.mat");
chi = chi';
%% CONTROL GAINS SYSTEM

k1 = 1;
k2 = 1;
k3 = 1;
k4 = 1;
params_estimados = chi;
params_real = chi*ones(1,length(t));

%% MPC Parameters
N = 7;

bounded = [2.5, 2.5, 2.5, 2.5]; 

[v0, UB, LB] = optimization_parameters(N, bounded);

%% OPTIMIZATION PARAMETERS
options = optimset('Display','off',...
                'TolFun', 1e-8,...
                'MaxIter', 10000,...
                'Algorithm', 'active-set',...
                'FinDiffType', 'forward',...
                'RelLineSrchBnd', [],...
                'RelLineSrchBndDuration', 1,...
                'TolConSQP', 1e-6);    

%% Switch to control adaptative or normal controller
aux = 1;

%% SIMULATION 
for k=1:1:length(t)-N
    tic; 
    %% GENERAL VECTOR OF ERROR SYSTEM
    he(:, k) = hd(:,k)-h(:,k);
    
    %% OPTIMAL CONTROLLER SECTION
    %% STATES OF THE OPTIMAL CONTROLLER
    f_obj1 = @(vc)  Cost_Function_drone(h(:,k), hd, vc, v(:,k), ts, N, L, chi, k);
    control = fmincon(f_obj1,v0,[],[],[],[],LB,UB,[],options);
    %% OBTAIN CONTROL VALUES OF THE VECTOR
    ul(k) = control(1,1);
    um(k) = control(2,1);
    un(k) = control(3,1);
    w(k) = control(4,1);
    
    %% CONTROL VECTOR
    vref = [ul(k);um(k);un(k);w(k)];  
    
    %% GET VALUES OF DRONE
    v(:,k+1) = system_dynamic(params_real(:,k), v(:,k), vref, ts);
    [h(:,k+1)] = system_drone(h(:,k), v(:,k+1), ts, L);
    
    minimo = -0.04;
    maximo =  0.04;
    noise = minimo + (maximo-minimo) .* rand(27,1);
    params_real(:,k+1) = params_real(:,k)+noise;
    
    %% MPC SIGNALS
    v0 = horizonte(control);
    
    %% SAMPLE TIME
    t_sample(k) = toc;
    toc;
end
% 
% %% AVERAGE TIME
trms = sum(t_sample)/(length(t_sample))
xnorm = norm(he(1,:),2)
ynorm = norm(he(2,:),2)
znorm = norm(he(3,:),2)
psinorm = norm(he(4,:),2)
%%
%%
close all; paso=1; 
%a) Par??metros del cuadro de animaci??n
figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 8 3]);
luz = light;
luz.Color=[0.65,0.65,0.65];
luz.Style = 'infinite';
%b) Dimenciones del Robot
   Drone_Parameters(0.02);
%c) Dibujo del Robot    
    G2=Drone_Plot_3D(h(1,1),h(2,1),h(3,1),0,0,h(4,1));hold on

    plot3(h(1,1),h(2,1),h(3,11),'--','Color',[56,171,217]/255,'linewidth',1.5);hold on,grid on   
    plot3(hxd(1),hyd(1),hzd(1),'Color',[32,185,29]/255,'linewidth',1.5);


view(20,15);
for k = 1:30:length(t)-N
    drawnow
    delete(G2);
   
    G2=Drone_Plot_3D(h(1,k),h(2,k),h(3,k),0,0,h(4,k));hold on
    
    plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.5);
    plot3(h(1,1:k),h(2,1:k),h(3,1:k),'--','Color',[56,171,217]/255,'linewidth',1.5);
    
    legend({'$\mathbf{h}$','$\mathbf{h}_{des}$'},'Interpreter','latex','FontSize',11,'Location','northwest','Orientation','horizontal');
    legend('boxoff')
    title('$\textrm{Movement Executed by the Aerial Robot}$','Interpreter','latex','FontSize',11);
    xlabel('$\textrm{X}[m]$','Interpreter','latex','FontSize',9); ylabel('$\textrm{Y}[m]$','Interpreter','latex','FontSize',9);zlabel('$\textrm{Z}[m]$','Interpreter','latex','FontSize',9);
    
end
print -dpng SIMULATION_1;
print -depsc SIMULATION_1;

figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);
plot(t(1:length(he)),he(1,:),'Color',[226,76,44]/255,'linewidth',1); hold on;
plot(t(1:length(he)),he(2,:),'Color',[46,188,89]/255,'linewidth',1); hold on;
plot(t(1:length(he)),he(3,:),'Color',[26,115,160]/255,'linewidth',1);hold on;
plot(t(1:length(he)),he(4,:),'Color',[83,57,217]/255,'linewidth',1);hold on;
grid('minor')
grid on;
legend({'$\tilde{h_{x}}$','$\tilde{h_{y}}$','$\tilde{h_{z}}$','$\tilde{h_{\psi}}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend('boxoff')
title('$\textrm{Evolution of Control Errors}$','Interpreter','latex','FontSize',9);
ylabel('$[m]$','Interpreter','latex','FontSize',9);

figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);
plot(t(1:length(ul)),ul,'Color',[226,76,44]/255,'linewidth',1); hold on
plot(t(1:length(ul)),um,'Color',[46,188,89]/255,'linewidth',1); hold on
plot(t(1:length(ul)),un,'Color',[26,115,160]/255,'linewidth',1); hold on
plot(t(1:length(ul)),w,'Color',[83,57,217]/255,'linewidth',1); hold on

% plot(t(1:length(v)),v(1,:),'--','Color',[226,76,44]/255,'linewidth',1); hold on
% plot(t(1:length(v)),v(2,:),'--','Color',[46,188,89]/255,'linewidth',1); hold on
% plot(t(1:length(v)),v(3,:),'--','Color',[26,115,160]/255,'linewidth',1); hold on
% plot(t(1:length(v)),v(4,:),'--','Color',[83,57,217]/255,'linewidth',1); hold on
grid('minor')
grid on;
legend({'$\mu_{lc}$','$\mu_{mc}$','$\mu_{nc}$','$\omega_{c}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
% legend({'$\mu_{lc}$','$\mu_{mc}$','$\mu_{nc}$','$\omega_{c}$','$\mu_{l}$','$\mu_{m}$','$\mu_{n}$','$\omega$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend('boxoff')
title('$\textrm{Control Values}$','Interpreter','latex','FontSize',9);
ylabel('$[rad/s]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time}[s]$','Interpreter','latex','FontSize',9);