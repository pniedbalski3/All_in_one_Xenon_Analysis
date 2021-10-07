function traj = spiral_coords_from_dat(file,Ordering,Dim,Alpha,Hubs,NPro)

% if nargin < 1
%     file = uigetfile();
% end
%Function to calculate spiral coordinates from measured trajectories

Dat = AllinOne_DataImport.ReadSiemensMeasVD13_idea(file);

raw = Dat.rawdata';

coil1 = raw(:,1:2:end);
coil2 = raw(:,2:2:end);

npts = size(coil1,1);

grad_a = zeros(size(coil1,1),9);
grad_b = zeros(size(coil1,1),9);

count = 1;
for i = 1:2:size(coil1,2)
    count2 = 1;
    ang = angle(coil1(:,i));
    for k = 1:(npts-1)
        if (ang(k+1) - ang(k)) > 5
            ang((k+1):end) = ang((k+1):end) - 2*pi;
        elseif (ang(k+1) - ang(k)) < -5
            ang((k+1):end) = ang((k+1):end) + 2*pi;
        end
    end
    C1_Grad_Phase = ang;

    ang = angle(coil1(:,i+1));
    for k = 1:(npts-1)
        if (ang(k+1) - ang(k)) > 5
            ang((k+1):end) = ang((k+1):end) - 2*pi;
        elseif (ang(k+1) - ang(k)) < -5
            ang((k+1):end) = ang((k+1):end) + 2*pi;
        end
    end
    C1_NoGrad_Phase = ang;

    ang = angle(coil2(:,i));
    for k = 1:(npts-1)
        if (ang(k+1) - ang(k)) > 5
            ang((k+1):end) = ang((k+1):end) - 2*pi;
        elseif (ang(k+1) - ang(k)) < -5
            ang((k+1):end) = ang((k+1):end) + 2*pi;
        end
    end
    C2_Grad_Phase = ang;

    ang = angle(coil2(:,i+1));
    for k = 1:(npts-1)
        if (ang(k+1) - ang(k)) > 5
            ang((k+1):end) = ang((k+1):end) - 2*pi;
        elseif (ang(k+1) - ang(k)) < -5
            ang((k+1):end) = ang((k+1):end) + 2*pi;
        end
    end
    C2_NoGrad_Phase = ang;
    
%     figure;plot(C1_NoGrad_Phase)
%     hold on
%     plot(C1_Grad_Phase)
%     
%     figure;plot(C2_NoGrad_Phase)
%     hold on
%     plot(C2_Grad_Phase)
%     
%     C1_Phase_Offset = C1_Grad_Phase(1) - C1_NoGrad_Phase(1);
%     C2_Phase_Offset = C2_Grad_Phase(1) - C2_NoGrad_Phase(1);
%     
%     C1_NoGrad_Phase_B = C1_NoGrad_Phase+C1_Phase_Offset;
%     C2_NoGrad_Phase_B = C2_NoGrad_Phase+C2_Phase_Offset;
%     
%     GradTest1 = C1_Grad_Phase-C1_NoGrad_Phase_B;
%     GradTest2 = C2_Grad_Phase-C2_NoGrad_Phase_B;
%     
%     grad_a(:,count) = GradTest1;
%     grad_b(:,count) = GradTest2;
    %To avoid phase wrap, do things this way
    for j = 2:size(coil1,1)
        
                
       % phasediffa(count2) = angle(coil1(j,i)) - angle(coil1(j-1,i));
       % phasediffb(count2) = angle(coil1(j,i+1)) - angle(coil1(j-1,i+1));
        
        phasediffa(count2) = C1_Grad_Phase(j) - C1_Grad_Phase(j-1);
        phasediffb(count2) = C1_NoGrad_Phase(j) - C1_NoGrad_Phase(j-1);
        
        grad_a(count2,count) = phasediffa(count2) - phasediffb(count2);
        
       % phasediffa1(count2) = angle(coil2(j,i)) - angle(coil2(j-1,i));
       % phasediffb1(count2) = angle(coil2(j,i+1)) - angle(coil2(j-1,i+1));
        phasediffa1(count2) = C2_Grad_Phase(j) - C2_Grad_Phase(j-1);
        phasediffb1(count2) = C2_NoGrad_Phase(j) - C2_NoGrad_Phase(j-1); 
       
        grad_b(count2,count) = phasediffa1(count2) - phasediffb1(count2);
        count2 = count2+1;
    end
%        
    %Need to smooth out points that are bad
%     for j = 2:(size(coil1,1)-1)
%         if abs(grad_a(j,count)-grad_a(j-1,count)) > .5*abs(grad_a(j-1,count))
%             grad_a(j,count) = mean([grad_a(j-1,count) grad_a(j+1,count)]);
%         end
%         if abs(grad_b(j,count)-grad_b(j-1,count)) > .5*abs(grad_b(j-1,count))
%             grad_b(j,count) = mean([grad_b(j-1,count) grad_b(j+1,count)]);
%         end
%     end
%     
%     [~,TF1] = rmoutliers(grad_a(:,count),'movmedian',20,'SamplePoints',1:npts);
%     [~,TF] = rmoutliers(grad_b(:,count),'movmedian',20,'SamplePoints',1:npts);
% 
%     out1 = find(TF1);
%     if out1(end) ==length(TF1)
%         out1(end) = [];
%     end
%     if out1(1) == 1
%         out1(1) = [];
%     end
%     for q = 1:length(out1)
%         ind = out1(q);
%         grad_a(ind,count) = mean( [grad_a(ind-1,count) grad_a(ind+1,count)] );
%     end
%     out2 = find(TF);
%     if out2(end) ==length(TF)
%         out2(end) = [];
%     end
%     if out2(1) == 1
%         out2(1) = [];
%     end
% 
%     for q = 1:length(out2)
%         ind = out2(q);
%         grad_b(ind,count) = mean( [grad_b(ind-1,count) grad_b(ind+1,count)] );
%     end
%     
%      figure('Name','Phase Difference')
%      subplot(2,2,1)
%      plot(1:size(coil1,1),grad_a(:,count))
%      title('Coil 1')
% %     
%      subplot(2,2,2)
%      plot(1:size(coil1,1),grad_b(:,count))
%      title('Coil 1')
%      
%      subplot(2,2,3)
%      plot(GradTest1)
%      title('Coil 1')
% %     
%      subplot(2,2,4)
%      plot(GradTest2)
%      title('Coil 1')
%     
    count = count+1;
end

%Take some averages
fin_grad = (grad_a + grad_b)/2;

Gx = (fin_grad(:,1)+fin_grad(:,4)+fin_grad(:,7))/3;
Gy = (fin_grad(:,2)+fin_grad(:,5)+fin_grad(:,8))/3;
Gz = (fin_grad(:,3)+fin_grad(:,6)+fin_grad(:,9))/3;

%time = 0:Dwell:((length(Gx)-1)*Dwell);
%time = time/1e6;
%PJN - make this correct in the units we need
% Gx = Gx/0.04;
% Gy = Gy/0.04;
% Gz = Gz/0.04;
Gx = cumtrapz(Gx);%/0.04/42.575575*1000;
Gy = cumtrapz(Gy);%/0.04/42.575575*1000;
Gz = cumtrapz(Gz);%/0.04/42.575575*1000;

% figure('Name','Final Trajectories');
% subplot(1,3,1);
% plot(Gx)
% subplot(1,3,2);
% plot(Gy)
% subplot(1,3,3);
% plot(Gz)

%% Rotate Trajectories
Rx = zeros(1,NPro);
Ry = zeros(1,NPro);
Rz = zeros(1,NPro);
Px = zeros(1,NPro);
Py = zeros(1,NPro);
Pz = zeros(1,NPro);
Sx = zeros(1,NPro);
Sy = zeros(1,NPro);
Sz = zeros(1,NPro);

if Dim == 0
    for i = 1:NPro
        RotAngle = 2*pi/NPro;
        ang = (i-1)*RotAngle;
        ca = cos(ang);
        sa = sin(ang);
        Rx(i) = ca;
        Ry(i) = -1*sa;
        Px(i) = sa;
        Py(i) = ca;
        %PJN - Zeros are already present, so don't need to set the others
    end
else
    Alph = zeros(1,NPro/Hubs);
    Beta = zeros(1,NPro/Hubs);
    Alpha0 = Alpha*pi/180;
    for i = 1:(NPro/Hubs)
        Alph(i) = Alpha0-Alpha0*2*(i-1)/(NPro/Hubs-1);
        Beta(i) = (i-1)*pi*(3-sqrt(5));
        ca = cos(Alph(i));
        sa = sin(Alph(i));
        cb = cos(Beta(i));
        sb = sin(Beta(i));
        Rx(i) = ca*cb;
        Ry(i) = -1*ca*sb;
        Px(i) = ca*sb;
        Py(i) = ca*cb;
        Sz(i) = sa;
    end
    if Hubs>1
        for i = 1:(NPro/Hubs)
            Alph(i) = Alpha0-Alpha0*2*(i-1)/(NPro/Hubs-1);
            Beta(i) = (i-1)*pi*(3-sqrt(5));
            ca = cos(Alph(i));
            sa = sin(Alph(i));
            cb = cos(Beta(i));
            sb = sin(Beta(i));
            Px(i+NPro/Hubs) = ca*cb;
            Py(i+NPro/Hubs) = -1*ca*sb;
            Sx(i+NPro/Hubs) = ca*sb;
            Sy(i+NPro/Hubs) = ca*cb;
            Rz(i+NPro/Hubs) = sa;
        end
    end
    if Hubs>2
        for i = 1:(NPro/Hubs)
            Alph(i) = Alpha0-Alpha0*2*(i-1)/(NPro/Hubs-1);
            Beta(i) = (i-1)*pi*(3-sqrt(5));
            ca = cos(Alph(i));
            sa = sin(Alph(i));
            cb = cos(Beta(i));
            sb = sin(Beta(i));
            Sx(i+2*NPro/Hubs) = ca*cb;
            Sy(i+2*NPro/Hubs) = -1*ca*sb;
            Rx(i+2*NPro/Hubs) = ca*sb;
            Ry(i+2*NPro/Hubs) = ca*cb;
            Pz(i+2*NPro/Hubs) = sa;
        end
    end
end
%% Reorder projections
if Ordering == 1
    vals = zeros(1,NPro);
    for i = 1:NPro
        vals(i) = Halton_rand(i-1,2);
    end
    [~,sort_ind] = sort(vals);
    Rx = Rx(sort_ind);
    Ry = Ry(sort_ind);
    Rz = Rz(sort_ind);
    Px = Px(sort_ind);
    Py = Py(sort_ind);
    Pz = Pz(sort_ind);
    Sx = Sx(sort_ind);
    Sy = Sy(sort_ind);
    Sz = Sz(sort_ind);
elseif Ordering == 2 && Dim == 1
    seed = 0.46557123;
    nums = 0:(NPro-1);
    vals = (nums*seed - floor(nums*seed));
    [~,sort_ind] = sort(vals);
    Rx = Rx(sort_ind);
    Ry = Ry(sort_ind);
    Rz = Rz(sort_ind);
    Px = Px(sort_ind);
    Py = Py(sort_ind);
    Pz = Pz(sort_ind);
    Sx = Sx(sort_ind);
    Sy = Sy(sort_ind);
    Sz = Sz(sort_ind);
elseif Ordering == 2 && Dim == 0
    seed = pi*(3-sqrt(5));
    nums = 0:(NPro-1);
    vals = (nums*seed - floor(nums*seed));
    [~,sort_ind] = sort(vals);
    Rx = Rx(sort_ind);
    Ry = Ry(sort_ind);
    Rz = Rz(sort_ind);
    Px = Px(sort_ind);
    Py = Py(sort_ind);
    Pz = Pz(sort_ind);
    Sx = Sx(sort_ind);
    Sy = Sy(sort_ind);
    Sz = Sz(sort_ind);
end
            
%% Fill Trajectory matrix
traj = zeros(3,npts,NPro);
for i = 1:NPro            
    traj(1,:,i) = Rx(i)*Gx+Ry(i)*Gy+Rz(i)*Gz;
    traj(2,:,i) = Px(i)*Gx+Py(i)*Gy+Pz(i)*Gz;
    traj(3,:,i) = Sx(i)*Gx+Sy(i)*Gy+Sz(i)*Gz;
end

rad = sqrt(traj(1,:,:).^2+traj(2,:,:).^2+traj(3,:,:).^2);
traj = traj/max(rad(:))/2;