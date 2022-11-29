function save_raw_4_Duke(mypath,outpath)

%% Find Files

files = dir(fullfile(mypath,'Raw'));
Cell_files = struct2cell(files);
file_names = Cell_files(1,:);
folder_names = Cell_files(2,:);
xeprot = 'Vent_GasExchange_20210819';
h1prot = 'Vent_GasEx_Anatomic_20210819';
calprot = 'XeCal_ShortTR_20210827';
try
    xe_file = file_names{find(contains(file_names,xeprot),1,'last')};
catch
    xeprot = 'Vent_GasEx_20220628';
    xe_file = file_names{find(contains(file_names,xeprot),1,'last')};
end
anat_file = file_names{find(contains(file_names,h1prot),1,'last')};
cal_file = file_names{find(contains(file_names,calprot),1,'last')};

xe_file = fullfile(mypath,'Raw',xe_file);
anat_file = fullfile(mypath,'Raw',anat_file);
cal_file = fullfile(mypath,'Raw',cal_file);

%% Pull Data
[Dis_Fid,Dis_Traj,Vent_Fid,Vent_Traj] = get_allinone_data(xe_file);
[H1_Fid_Vent,H1_Traj_Vent,Cal_Raw,Params] = get_anat_cal_params(xe_file,anat_file,cal_file);

disData_avg = Cal_Raw.data;
t = double((0:(length(disData_avg)-1))*Cal_Raw.dwell);
disfitObj = Spectroscopy.NMR_TimeFit_v(disData_avg,t,[1 1 1],[0 -700  -7400],[250 200 30],[0 200 0],[0 0 0],0,length(t)); % first widths lorenzian, 2nd are gauss
disfitObj = disfitObj.fitTimeDomainSignal();
%AppendedDissolvedFit = Cal_Raw.dwell*fftshift(fft(disfitObj.calcComponentTimeDomainSignal(t),[],1),1);
RBC2Bar = disfitObj.area(1)/disfitObj.area(2);

Cal_Fid = Cal_Raw.data;
Cal_Dwell = Cal_Raw.dwell;
%% Fix orientations
my_hold = Vent_Traj;
Vent_Traj(1,:,:) = -my_hold(3,:,:);
Vent_Traj(2,:,:) = -my_hold(1,:,:);
Vent_Traj(3,:,:) = my_hold(2,:,:);

my_hold = Dis_Traj;
Dis_Traj(1,:,:) = -my_hold(2,:,:);
Dis_Traj(2,:,:) = -my_hold(1,:,:);
Dis_Traj(3,:,:) = my_hold(3,:,:);

my_hold = H1_Traj_Vent;
%%
H1_Traj_Vent(1,:,:) = -my_hold(3,:,:);
H1_Traj_Vent(2,:,:) = -my_hold(2,:,:);
H1_Traj_Vent(3,:,:) = my_hold(1,:,:);

%% Edit Data as needed
%Now, need to scale k-space to get lo-res gas image:
Gas_Traj = Vent_Traj*1.5;
hold_traj = Gas_Traj;
hold_traj(:,1) = Gas_Traj(:,1);
hold_traj(:,2) = Gas_Traj(:,3);
hold_traj(:,3) = Gas_Traj(:,2);
Gas_Traj = hold_traj;
rad = squeeze(sqrt(Gas_Traj(:,1).^2+Gas_Traj(:,2).^2+Gas_Traj(:,3).^2));
toobig = find(rad(:,1)>0.5);
Gas_Fid = Vent_Fid;
Gas_Fid(toobig,:) = [];
Gas_Traj(toobig,:) = [];



H1_Traj_Dis = H1_Traj_Vent*1.5;
rad = squeeze(sqrt(H1_Traj_Vent(:,1).^2+H1_Traj_Vent(:,2).^2+H1_Traj_Vent(:,3).^2));
toobig = find(rad(:,1)>0.5);
H1_Traj_Dis(:,toobig,:) = [];
H1_Fid_Dis = H1_Fid_Vent;
H1_Fid_Dis(toobig,:) = [];

%% Pull parameters that might be needed for recon
ImSize_Dis = Params.imsize;
ImSize_Vent = 96;
NPro = size(Dis_Fid,2);
TR = Params.TR;
TE = Params.TE;
ActTE90 = TE;
GasFA = Params.GasFA;
DisFA = Params.DisFA;
Dwell = Params.Dwell;
freq_jump = Params.freq_offset;
scanDateStr = Params.scandatestr;
FOV = Params.GE_FOV;


%% Load Niftis

nii_path = fullfile(mypath,'All_in_One_Analysis');
Anat_Vent = niftiread(fullfile(nii_path,'HiRes_Anatomic.nii.gz'));
Vent_Mask = niftiread(fullfile(nii_path,'HiRes_Anatomic_mask.nii.gz'));
Anat_Dis = niftiread(fullfile(nii_path,'LoRes_Anatomic.nii.gz'));
Dis_Mask = niftiread(fullfile(nii_path,'LoRes_Anatomic_mask.nii.gz'));
Vent_Image = niftiread(fullfile(nii_path,'Vent_Image.nii.gz'));

%% Save everything
save(fullfile(outpath,'Raw_Dissolved.mat'),'DisFA','GasFA','Dwell','scanDateStr','TR','TE','NPro','Dis_Fid','Dis_Traj','Gas_Fid','Gas_Traj','H1_Fid_Dis','H1_Traj_Dis','ImSize_Dis','FOV');
save(fullfile(outpath,'Raw_Vent.mat'),'ImSize_Vent','Vent_Fid','Vent_Traj','H1_Fid_Vent','H1_Traj_Vent');
save(fullfile(outpath,'Raw_Cal.mat'),'Cal_Fid','Cal_Dwell','RBC2Bar');
save(fullfile(outpath,'Recon_Dis.mat'),'Anat_Dis','Dis_Mask');
save(fullfile(outpath,'Recon_Vent.mat'),'Anat_Vent','Vent_Mask','Vent_Image');

save(fullfile(outpath,'All_Raw.mat'),'DisFA','GasFA','Dwell','scanDateStr','TR','TE','NPro','Dis_Fid','Dis_Traj','Gas_Fid','Gas_Traj','H1_Fid_Dis','H1_Traj_Dis','ImSize_Dis','FOV','ImSize_Vent','Vent_Fid','Vent_Traj','H1_Fid_Vent','H1_Traj_Vent','Cal_Fid','Cal_Dwell','RBC2Bar','Anat_Dis','Dis_Mask','Anat_Vent','Vent_Mask','Vent_Image');
copyfile(cal_file,outpath);

%% Orientation Check
% As far as I can tell, everything matches the mask files loaded from nifti
%Temporary Check to make sure things are ordered correctly
% figure; montage(Anat_Vent/max(Anat_Vent(:)));
% reco_gas = reshape(H1_Fid_Vent(:,:,1),1,[])';
% 
% gas_traj = AllinOne_Tools.column_traj(H1_Traj_Vent);
% Vent_Im = AllinOne_Recon.base_floret_recon(96,reco_gas,gas_traj); %Don't want to Hardcode image size, but palatable for now
% 
% figure; montage(abs(Vent_Im)/max(abs(Vent_Im(:))));
