function [Dis_Fid,Dis_Traj,Gas_Fid,Gas_Traj] = get_allinone_data(file)

parent_path = which('get_allinone_data');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file
%Function to read in all_in_one data
%%

Xe_Dat_twix = DataImport.mapVBVD(file,'ignoreSeg');
Xe_Dat_twix.flagIgnoreSeg = 1;
Xe_Dat_twix.image.flagIgnoreSeg = 1;
Xe_Dat_twix.image.flagAverageReps = 1;
Xe_Dat_twix.flagAverageReps = 1;
Seq_Name = Xe_Dat_twix.hdr.Config.SequenceFileName;

Xe_Raw = DataImport.ReadSiemensMeasVD13_idea(file);
fid = Xe_Raw.rawdata;
loop = Xe_Raw.loopcounters;

%I could do something more elegant, but really, this is just every other,
%starting with Dis
Dis_Fid = fid(1:2:(end-1),:);
%Again could do something more elegant, but start with easy
Dis_Fid(:,65:end) = [];
Dis_Fid = Dis_Fid';

Gas_Fid = fid(2:2:end,:);
Gas_Fid = Gas_Fid';


%% Getting Dissolved Trajectories:
%Hardcode radial Parameters - awful.

gamma = 11.777953;
RUT = 100*1e3; %in ns
MaxGrad = 9.475937;
ADC_Dur = 716.8*1e3;%in ns

Resolution = [0.00625 0.00625 0.00625];

%Dwell = 22.4/2;

Dur = ADC_Dur-RUT;
Grad = linspace(0,1,RUT);
Grad((RUT):ADC_Dur) = 1;
Grad = Grad * MaxGrad;

Pts = size(Dis_Fid,1);
ADC_Dur = ADC_Dur*1e-9; %Convert from ns to s
RUT = RUT*1e-9; %Convert from ns to s
Dw = ADC_Dur/Pts;

Arm_untimed = cumtrapz(Grad);
Grad_Time = 0:1e-9:(ADC_Dur-1e-9); %in s

Time = 0:Dw:(ADC_Dur-Dw);
Arm = interp1(Grad_Time,Arm_untimed,Time); %Now we are in mT*s/m

Arm = Arm*gamma/1000;
k_loc = Arm;
% RU = 100;
% Dw = Xe_Dat_twix.hdr.MeasYaps.sRXSPEC.alDwellTime{1,1}/1000; %Dwell is in nanoseconds in twix. Need us    
% FT = 10000;%Doesn't matter how long flat time is - it will only be sampled for the correct number of points.
% 
% Ramp_Shape = linspace(0,1,RU);
% Flat_Shape = linspace(1,1,FT);
% 
% Grad_Shape = [Ramp_Shape Flat_Shape];

%% Resample at the dwell time
NPts = size(Dis_Fid,1);
NPro = size(Dis_Fid,2);
% Dw_Pts = 0:Dw:((NPts-1)*Dw);

% re_Grad_Shape = interp1((1:length(Grad_Shape)),Grad_Shape,Dw_Pts);
% 
% re_Grad_Shape(isnan(re_Grad_Shape)) = 0;
%% Integrate to get k-space location for one radial projection
%k_loc = cumtrapz(Dw_Pts,re_Grad_Shape);

%Angs = Reconstruction.duke_halton_random_mex(NPro,3);

ind = zeros(1,NPro);
for i = 1:NPro
    ind(i) = AllinOne_Tools.Halton_rand(i-1,2);
end
[~,newind] = sort(ind);

l_kz = ((2*(newind-1))+1-NPro)/NPro;
l_alph = sqrt(NPro*pi)*asin(l_kz);

traj = zeros(3,NPts,NPro);
for i = 1:NPro
%     traj(1,:,i) = k_loc*sin(Angs(i,2))*cos(Angs(i,1));
%     traj(2,:,i) = k_loc*sin(Angs(i,2))*sin(Angs(i,1));
%     traj(3,:,i) = k_loc*cos(Angs(i,2));
    traj(1,:,i) = k_loc*sqrt(1-(l_kz(i))^2)*cos(l_alph(i));
    traj(2,:,i) = k_loc*sqrt(1-(l_kz(i))^2)*sin(l_alph(i));
    traj(3,:,i) = k_loc*l_kz(i);
end

kFOV_desired = 1./(Resolution);
kMax_desired = kFOV_desired/2;
max_k = max(kMax_desired); %Here, we are in 1/m
Dis_Traj = traj/max_k/2;
Dis_Traj = Dis_Traj/1000;

rad = sqrt(Dis_Traj(1,:,:).^2 + Dis_Traj(2,:,:).^2 + Dis_Traj(3,:,:).^2);
%Dis_Traj = traj/max(rad(:))/2;
hold_traj = Dis_Traj;
hold_traj(1,:,:) = Dis_Traj(2,:,:);
hold_traj(2,:,:) = Dis_Traj(3,:,:);
hold_traj(3,:,:) = Dis_Traj(1,:,:);

Dis_Traj = hold_traj;

%Dis_Traj = rotate_radial(k_loc,NPts,NPro);
%% Get Gas Traj:
traj_file = [parent_path '/Traj_Files/Vent_GasExchange_20210819_Traj.dat'];
traj_twix = AllinOne_DataImport.mapVBVD(traj_file);

Gas_Traj = Tools.spiral_coords_from_dat(traj_twix,Xe_Dat_twix);

hold_traj = Gas_Traj;
hold_traj(1,:,:) = Gas_Traj(2,:,:);
hold_traj(2,:,:) = Gas_Traj(1,:,:);
hold_traj(3,:,:) = Gas_Traj(3,:,:);
Gas_Traj = hold_traj;
