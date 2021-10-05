function [Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,Vent_Im,H1_Image_Vent,H1_Image_Dis,Cal_Raw,Dis_Fid,Gas_Fid,Params,Dis_Traj] = reco_allinone(xe_file,anat_file,cal_file)

if nargin < 1
    [path,xe_file] = uigetfile('*.dat','Select All-in-one Vent/Gas Exchange Data File');
    xe_file = fullfile(path,xe_file);
end

%% Load data
[Dis_Fid,Dis_Traj,Gas_Fid,Gas_Traj] = get_allinone_data(xe_file);
[H1_Raw,H1_Traj,Cal_Raw,Params] = get_anat_cal_params(xe_file,anat_file,cal_file);

%% Remove acheiving steady state:
SS_ind = 50;
Dis_Fid(:,1:SS_ind) = [];
Dis_Traj(:,:,1:SS_ind) = [];
Gas_Fid(:,1:SS_ind) = [];
Gas_Traj(:,:,1:SS_ind) = [];

%% Reconstruct
% Get Ventilation Image - Easy
reco_gas = reshape(Gas_Fid,1,[])';
gas_traj = AllinOne_Tools.column_traj(Gas_Traj);
% hold_traj = gas_traj;
% hold_traj(:,1) = gas_traj(:,1);
% hold_traj(:,2) = gas_traj(:,3);
% hold_traj(:,3) = gas_traj(:,2);
% gas_traj = hold_traj;
Vent_Im = AllinOne_Recon.base_floret_recon(96,reco_gas,gas_traj); %Don't want to Hardcode image size, but palatable for now

% Dissolved Image - Also Easy
reco_dis = reshape(Dis_Fid,1,[])';
dis_traj = AllinOne_Tools.column_traj(Dis_Traj); 
Dis_Image = AllinOne_Recon.Dissolved_Phase_LowResRecon(64,reco_dis,dis_traj); %Don't want to Hardcode image size, but palatable for now

%Now, need to scale k-space to get lo-res gas image:
gas_traj2 = gas_traj*1.5;
hold_traj = gas_traj2;
hold_traj(:,1) = gas_traj2(:,1);
hold_traj(:,2) = gas_traj2(:,3);
hold_traj(:,3) = gas_traj2(:,2);
gas_traj2 = hold_traj;
rad = sqrt(gas_traj2(:,1).^2+gas_traj2(:,2).^2+gas_traj2(:,3).^2);
toobig = find(rad>0.5);
reco_gas(toobig) = [];
gas_traj2(toobig,:) = [];
LoRes_Gas_Image = AllinOne_Recon.Dissolved_Phase_LowResRecon(64,reco_gas,gas_traj2); %Don't want to Hardcode image size, but palatable for now
HiRes_Gas_Image = AllinOne_Recon.Dissolved_HighResRecon(64,reco_gas,gas_traj2); %Don't want to Hardcode image size, but palatable for now
%%
ImSize = Params.imsize;
NPro = size(Dis_Fid,2);
TR = Params.TR;
TE = Params.TE;
ActTE90 = TE;
GasFA = Params.GasFA;
DisFA = Params.DisFA;
Dwell = Params.Dwell;
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
H1_traj_r = [H1_trajx H1_trajy H1_trajz];


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
H1_Image_Vent = rot90(flip(fliplr(rot90(H1_Image_Vent)),3),2);

%ProtonMax = prctile(abs(H1_Image(:)),99.99);


H1_trajx = reshape(H1_Traj(1,:,:),1,[])';
H1_trajy = reshape(H1_Traj(2,:,:),1,[])';
H1_trajz = reshape(H1_Traj(3,:,:),1,[])';
H1_trajz = -H1_trajz;
% 
H1_traj_r = [H1_trajx H1_trajy H1_trajz];

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
H1_Image_Dis = rot90(flip(fliplr(rot90(H1_Image_Dis)),3),2);


