function [Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,Vent_Im,H1_Image_Vent,H1_Image_Dis,Cal_Raw,Dis_Fid_save,Gas_Fid_save,Params,Dis_Traj_save,Gas_Traj_save] = reco_allinone(xe_file,anat_file,cal_file)

if nargin < 1
    [xe_file,mypath] = uigetfile('*.dat','Select All-in-one Vent/Gas Exchange Data File');
    xe_file = fullfile(mypath,xe_file);
    [anat_file,mypath] = uigetfile('*.dat','Select All-in-one Vent/Gas Exchange Anatomic Data File');
    anat_file = fullfile(mypath,anat_file);
    [cal_file,mypath] = uigetfile('*.dat','Select Calibration Data File');
    cal_file = fullfile(mypath,cal_file);
end

%% Load data
[Dis_Fid,Dis_Traj,Gas_Fid,Gas_Traj] = get_allinone_data(xe_file);
[H1_Raw,H1_Traj,Cal_Raw,Params] = get_anat_cal_params(xe_file,anat_file,cal_file);

%% Remove acheiving steady state:
SS_ind = 20;
Dis_Fid(:,1:SS_ind) = [];
Dis_Traj(:,:,1:SS_ind) = [];
Gas_Fid(:,1:SS_ind) = [];
Gas_Traj(:,:,1:SS_ind) = [];

%% Remove Spiking before recon
%Need to preserve full FIDs for wiggles (timing)
Dis_Fid_save = Dis_Fid;
Gas_Fid_save = Gas_Fid;
Dis_Traj_save = Dis_Traj;
Gas_Traj_save = Gas_Traj;

Dis_k0 = abs(Dis_Fid(1,:));
Gas_k0 = abs(Gas_Fid(1,:));

[~,rm_dis] = rmoutliers(Dis_k0,'movmedian',8);
[~,rm_gas] = rmoutliers(Gas_k0,'movmedian',8);

Dis_Fid(:,rm_dis) = [];
Gas_Fid(:,rm_gas) = [];
Dis_Traj(:,:,rm_dis) = [];
Gas_Traj(:,:,rm_gas) = [];

% %Sanity Check/Debugging
% figure('Name','Test Spike Removal');
% subplot(4,2,1)
% plot(Dis_k0)
% title('Dissolved k0 - No Spike Filter')
% subplot(4,2,2)
% plot(abs(Dis_Fid(1,:)))
% title('Dissolved k0 - After Spike Filter')
% subplot(4,2,3)
% plot(abs(Dis_Fid_save));
% title('Dissolved FIDs - No Spike Filter')
% subplot(4,2,4)
% plot(abs(Dis_Fid));
% title('Dissolved FIDs - With Spike Filter')
% subplot(4,2,5)
% plot(Gas_k0)
% title('Gas k0 - No Spike Filter')
% subplot(4,2,6)
% plot(abs(Gas_Fid(1,:)))
% title('Gas k0 - After Spike Filter')
% subplot(4,2,7)
% plot(abs(Gas_Fid_save));
% title('Gas FIDs - No Spike Filter')
% subplot(4,2,8)
% plot(abs(Gas_Fid));
% title('Gas FIDs - With Spike Filter')

%% Reconstruct
% Get Ventilation Image - Easy
reco_gas = reshape(Gas_Fid,1,[])';
%gas_traj = AllinOne_Tools.column_traj(Gas_Traj);
traj_x = reshape(Gas_Traj(1,:,:),1,[])';
traj_y = reshape(Gas_Traj(2,:,:),1,[])';
traj_z = reshape(Gas_Traj(3,:,:),1,[])';

gas_traj= [-traj_x -traj_z traj_y];
%Remove some of the spikes:
[~,rm_recogas] = rmoutliers(abs(reco_gas),'movmedian',8);
gas_traj(rm_recogas,:) = [];
reco_gas(rm_recogas) = [];

ImSize = 96;
Vent_Im = AllinOne_Recon.base_floret_recon(round(ImSize),reco_gas,gas_traj); %Don't want to Hardcode image size, but palatable for now

% Dissolved Image - Also Easy
reco_dis = reshape(Dis_Fid,1,[])';
% dis_traj = AllinOne_Tools.column_traj(Dis_Traj); 
traj_x = reshape(Dis_Traj(1,:,:),1,[])';
traj_y = reshape(Dis_Traj(2,:,:),1,[])';
traj_z = reshape(Dis_Traj(3,:,:),1,[])';

dis_traj= [-traj_x -traj_y traj_z];

%Remove some of the spikes:
[~,rm_recodis] = rmoutliers(abs(reco_dis),'movmedian',8);
dis_traj(rm_recodis,:) = [];
reco_dis(rm_recodis) = [];

ImSize = 64;
Dis_Image = AllinOne_Recon.Dissolved_Phase_LowResRecon(ImSize,reco_dis,dis_traj); %Don't want to Hardcode image size, but palatable for now

%Now, need to scale k-space to get lo-res gas image:
gas_traj2 = gas_traj*1.5;
% hold_traj = gas_traj2;
% hold_traj(:,1) = gas_traj2(:,1);
% hold_traj(:,2) = gas_traj2(:,3);
% hold_traj(:,3) = gas_traj2(:,2);
% gas_traj2 = hold_traj;
rad = sqrt(gas_traj2(:,1).^2+gas_traj2(:,2).^2+gas_traj2(:,3).^2);
toobig = find(rad>0.5);
reco_gas(toobig) = [];
gas_traj2(toobig,:) = [];
LoRes_Gas_Image = AllinOne_Recon.Dissolved_Phase_LowResRecon(ImSize,reco_gas,gas_traj2); %Don't want to Hardcode image size, but palatable for now
HiRes_Gas_Image = AllinOne_Recon.Dissolved_HighResRecon(ImSize,reco_gas,gas_traj2); %Don't want to Hardcode image size, but palatable for now
%%
ImSize = Params.imsize;
NPro = size(Dis_Fid,2);
TR = Params.TR;
TE = Params.TE;
ActTE90 = TE;
GasFA = Params.GasFA;
DisFA = Params.DisFA;
Dwell = Params.Dwell;
Params.GE_FOV = 400;
freq_jump = Params.freq_offset;
scanDateStr = Params.scandatestr;
%Now, need to determine how many points to throw away based on flip angle
%SS_ind = 20;

%% Anatomic Images
H1_trajx = reshape(H1_Traj(1,:,:),1,[])';
H1_trajy = reshape(H1_Traj(2,:,:),1,[])';
H1_trajz = reshape(H1_Traj(3,:,:),1,[])';

H1_trajz = -H1_trajz;
% 
H1_traj_r = [-H1_trajy H1_trajz H1_trajx];


%Vent Recon
H1_Image_AllCoils = zeros(Params.imsizeH1,Params.imsizeH1,Params.imsizeH1,size(H1_Raw,3));
for i = 1:size(H1_Raw,3)
    H1_fid_r = reshape(H1_Raw(:,:,i),1,[])';
    %If FLORET - can use higher resolution AllinOne_Recon kernel FLORET
    %will have more than 200 points along radial arm
    if size(H1_Traj,2)>200
        H1_Image_AllCoils(:,:,:,i) = AllinOne_Recon.gasex_floret_recon(Params.imsizeH1,H1_fid_r,H1_traj_r);
    else
        %If not FLORET, need to use a lower resolution kernel
        H1_Image_AllCoils(:,:,:,i) = AllinOne_Recon.gasex_h1radial_recon(Params.imsizeH1,H1_fid_r,H1_traj_r);
    end
end
H1_Image_Vent = AllinOne_Tools.SOS_Coil_Combine(H1_Image_AllCoils);
H1_Image_Vent = H1_Image_Vent/max(H1_Image_Vent(:));
% H1_Image_Vent = rot90(flip(fliplr(rot90(H1_Image_Vent)),3),2);

%ProtonMax = prctile(abs(H1_Image(:)),99.99);


% H1_trajx = reshape(H1_Traj(1,:,:),1,[])';
% H1_trajy = reshape(H1_Traj(2,:,:),1,[])';
% H1_trajz = reshape(H1_Traj(3,:,:),1,[])';
% H1_trajz = -H1_trajz;
% % 
% H1_traj_r = [H1_trajx H1_trajy H1_trajz];

H1_traj_r = H1_traj_r*1.5;

rad = sqrt(H1_traj_r(:,1).^2+H1_traj_r(:,2).^2+H1_traj_r(:,3).^2);
toobig = find(rad>0.5);
H1_traj_r(toobig,:) = [];
%Vent Recon
H1_Image_AllCoils = zeros(Params.imsizeH1*2/3,Params.imsizeH1*2/3,Params.imsizeH1*2/3,size(H1_Raw,3));
for i = 1:size(H1_Raw,3)
    H1_fid_r = reshape(H1_Raw(:,:,i),1,[])';
    H1_fid_r(toobig) = [];
    %If FLORET - can use higher resolution AllinOne_Recon kernel FLORET
    %will have more than 200 points along radial arm
    if size(H1_Traj,2)>200
        H1_Image_AllCoils(:,:,:,i) = AllinOne_Recon.gasex_floret_recon(Params.imsizeH1*2/3,H1_fid_r,H1_traj_r);
    else
        %If not FLORET, need to use a lower resolution kernel
        H1_Image_AllCoils(:,:,:,i) = AllinOne_Recon.gasex_h1radial_recon(Params.imsizeH1*2/3,H1_fid_r,H1_traj_r);
    end
end
H1_Image_Dis = AllinOne_Tools.SOS_Coil_Combine(H1_Image_AllCoils);
H1_Image_Dis = H1_Image_Dis/max(H1_Image_Dis(:));
% H1_Image_Dis = rot90(flip(fliplr(rot90(H1_Image_Dis)),3),2);


