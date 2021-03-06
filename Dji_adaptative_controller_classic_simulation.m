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


%% SIMULATION 
for k=1:1:length(t)
    tic; 
    %% GENERAL VECTOR OF ERROR SYSTEM
    he(:, k) = hd(:,k)-h(:,k);
    
    %% OPTIMAL CONTROLLER SECTION
    %% STATES OF THE OPTIMAL CONTROLLER
    control =  inverse_controller(h(:,k), hd(:,k), hdp(:,k), k1, k2, L);
    
    %% OBTAIN CONTROL VALUES OF THE VECTOR
    ul(k) = control(1,1);
    um(k) = control(1,2);
    un(k) = control(1,3);
    w(k) = control(1,4);
    
    %% DERIVATIES OF THE CONTROL SIGNALS
    if k==1
        ulp = ul(k)/ts;
        ump = um(k)/ts;
        unp= un(k)/ts;
        wp= w(k)/ts;

    else
        ulp = (ul(k)-ul(k-1))/ts;
        ump = (um(k)-um(k-1))/ts;
        unp = (un(k)-un(k-1))/ts;
        wp = (w(k)-w(k-1))/ts;

    end
    vcp = [ulp;ump;unp;wp];
    
    %% DYNAMIC COMPENSATION
    [vref,params_estimados(:,k+1)] = dynamic_compensation_classic(vcp, control(1,:)', v(:,k),params_estimados(:,k), chi, k3, k4, ts);
    
    %% GET VALUES OF DRONE
    v(:,k+1) = system_dynamic(params_real(:,k), v(:,k), vref, ts);
    [h(:,k+1)] = system_drone(h(:,k), v(:,k+1), ts, L);
    
    %% CHANGE DYNAMIC PARAMETETS
    minimo = -0.02;
    maximo =  0.02;
    r = minimo + (maximo-minimo) .* rand(27,1);
    params_real(:,k+1) = params_real(:,k)+r;
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
close all; paso=1; 
%a) Par??metros del cuadro de animaci??n
figure
% set(gcf, 'PaperUnits', 'inches');
% set(gcf, 'PaperSize', [2 2]);
% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperPosition', [0 0 10 4]);
myVideo = VideoWriter('myVideoFile'); %open video file
myVideo.FrameRate = 10;  %can adjust this, 5 - 10 works well for me
open(myVideo)
luz = light;
luz.Color=[0.65,0.65,0.65];
luz.Style = 'infinite';
%b) Dimenciones del Robot
   Drone_Parameters(0.02);
%c) Dibujo del Robot    
    G2=Drone_Plot_3D(h(1,1),h(2,1),h(3,1),0,0,h(4,1));hold on

    plot3(h(1,1),h(2,1),h(3,11),'--','Color',[56,171,217]/255,'linewidth',1.3);hold on,grid on   
    plot3(hxd(1),hyd(1),hzd(1),'Color',[32,185,29]/255,'linewidth',1.3);
    
    
view(20,15);
for k = 1:10:length(t)
    drawnow
    delete(G2);

   
    G2=Drone_Plot_3D(h(1,k),h(2,k),h(3,k),0,0,h(4,k));hold on
   
    grid('minor')
    grid on;
    plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.3);
    plot3(h(1,1:k),h(2,1:k),h(3,1:k),'--','Color',[56,171,217]/255,'linewidth',1.3);
    
    legend({'$\eta$','$\eta_{ref}$'},'Interpreter','latex','FontSize',11,'Location','northwest','Orientation','horizontal');
    legend('boxoff')
    %title('$\textrm{Movement Executed by the Aerial Robot}$','Interpreter','latex','FontSize',11);
    xlabel('$\textrm{X}[m]$','Interpreter','latex','FontSize',9); ylabel('$\textrm{Y}[m]$','Interpreter','latex','FontSize',9);zlabel('$\textrm{Z}[m]$','Interpreter','latex','FontSize',9);
    frame = getframe(gcf); %get frame
    writeVideo(myVideo, frame);
end
close(myVideo)
print -dpng SIMULATION_1
print -depsc SIMULATION_1

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
legend({'$\tilde{\eta_{x}}$','$\tilde{\eta_{y}}$','$\tilde{\eta_{z}}$','$\tilde{\eta_{\psi}}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend('boxoff')
%title('$\textrm{Evolution of Control Errors}$','Interpreter','latex','FontSize',9);
ylabel('$[m]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time}[s]$','Interpreter','latex','FontSize',9);

figure
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);
plot(t(1:length(ul)),ul,'Color',[226,76,44]/255,'linewidth',1); hold on
plot(t(1:length(ul)),um,'Color',[46,188,89]/255,'linewidth',1); hold on
plot(t(1:length(ul)),un,'Color',[26,115,160]/255,'linewidth',1); hold on
plot(t(1:length(ul)),w,'Color',[83,57,217]/255,'linewidth',1); hold on

plot(t,v(1,1:length(t)),'--','Color',[226,76,44]/255,'linewidth',1); hold on
plot(t,v(2,1:length(t)),'--','Color',[46,188,89]/255,'linewidth',1); hold on
plot(t,v(3,1:length(t)),'--','Color',[26,115,160]/255,'linewidth',1); hold on
plot(t,v(4,1:length(t)),'--','Color',[83,57,217]/255,'linewidth',1); hold on
grid('minor')
grid on;
% legend({'$\mu_{lref}$','$\mu_{mref}$','$\mu_{nref}$','$\omega_{ref}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend({'$\mu_{lc}$','$\mu_{mc}$','$\mu_{nc}$','$\omega_{c}$','$\mu_{l}$','$\mu_{m}$','$\mu_{n}$','$\omega$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend('boxoff')
%title('$\textrm{Control Values}$','Interpreter','latex','FontSize',9);
ylabel('$[m/s][rad/s]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time}[s]$','Interpreter','latex','FontSize',9);

