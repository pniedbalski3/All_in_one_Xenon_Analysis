function allinone_recon_wiggle_only(mypath,force_recon)
%% Identify Image files - done in kind of a lazy way
if nargin < 1
    mypath = uigetdir([],'Select folder containing xenon data');
    force_recon = true;
end
if nargin < 2
    force_recon = true;
end

%% Read Data
try 
    files = dir(fullfile(mypath,'Raw'));
    Cell_files = struct2cell(files);
    file_names = Cell_files(1,:);
    folder_names = Cell_files(2,:);
    
    h1prot = 'Vent_GasEx_Anatomic_20210819';
    calprot = 'XeCal_ShortTR_20210827';
    try
        xeprot = 'Vent_GasExchange_20210819';
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
    %Assume that raw data is in a folder called "Raw"
    write_path = mypath;
    %write_path((end-3):end) = [];
    write_path = fullfile(write_path,'All_in_One_Analysis');
    if ~isfolder(write_path)
        mkdir(write_path);
    end
catch
    disp('Something is broken');
  %  xe_file = uigetfile('.dat','Select Xenon File');
  %  anat_file = uigetfile('.dat','Select Anatomic File');
  %  cal_file = uigetfile('.dat','Select Calibration File');
  %  write_path = uigetdir(mypath,'Select Output Folder');
  %This isn't the best possible way to do this, but let's just return if
  %this fails.
  return;
end

%% Reconstruct
if force_recon
    [Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,Vent_Im,H1_Image_Vent,H1_Image_Dis,Cal_Raw,Dis_Fid,Gas_Fid,Params,Dis_Traj,Gas_Traj] = AllinOne_Tools.reco_allinone(xe_file,anat_file,cal_file);
    
    %% Rotate Images
    %We need Matlab and NIFTI to line up, so make sure all the images are
    %properly oriented. We'll have to change orientation in images
    Dis_Image = AllinOne_Tools.all_in_one_canonical_orientation(Dis_Image);
    LoRes_Gas_Image = AllinOne_Tools.all_in_one_canonical_orientation(LoRes_Gas_Image);
    HiRes_Gas_Image = AllinOne_Tools.all_in_one_canonical_orientation(HiRes_Gas_Image);
    Vent_Im = AllinOne_Tools.all_in_one_canonical_orientation(Vent_Im);
    H1_Image_Vent = AllinOne_Tools.all_in_one_canonical_orientation(H1_Image_Vent);
    H1_Image_Dis = AllinOne_Tools.all_in_one_canonical_orientation(H1_Image_Dis);

    %% Images are reconstructed - Write out:
    Dis_info = AllinOne_Tools.nifti_metadata(Dis_Image,Params.GE_Voxel,Params.GE_FOV);
    niftiwrite(abs(Dis_Image),fullfile(write_path,'Dissolved_Image'),Dis_info,'Compressed',true);
    Gas_info = AllinOne_Tools.nifti_metadata(LoRes_Gas_Image,Params.GE_Voxel,Params.GE_FOV);
    niftiwrite(abs(LoRes_Gas_Image),fullfile(write_path,'LoRes_Gas_Image'),Gas_info,'Compressed',true);
    Vent_info = AllinOne_Tools.nifti_metadata(Vent_Im,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(abs(Vent_Im),fullfile(write_path,'Vent_Image'),Vent_info,'Compressed',true);
    H1_Vent_info = AllinOne_Tools.nifti_metadata(H1_Image_Vent,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(abs(H1_Image_Vent),fullfile(write_path,'HiRes_Anatomic'),H1_Vent_info,'Compressed',true);
    H1_GE_info = AllinOne_Tools.nifti_metadata(LoRes_Gas_Image,Params.GE_Voxel,Params.GE_FOV);
    niftiwrite(abs(H1_Image_Dis),fullfile(write_path,'LoRes_Anatomic'),H1_GE_info,'Compressed',true);

    save(fullfile(write_path,'Post_Recon_Images.mat'),'Dis_Image','LoRes_Gas_Image','HiRes_Gas_Image','Vent_Im','H1_Image_Vent','H1_Image_Dis','Cal_Raw','Dis_Fid','Gas_Fid','Params','Dis_Traj','Gas_Traj');
else
    load(fullfile(write_path,'Post_Recon_Images.mat'),'Dis_Image','LoRes_Gas_Image','HiRes_Gas_Image','Vent_Im','H1_Image_Vent','H1_Image_Dis','Cal_Raw','Dis_Fid','Gas_Fid','Params','Dis_Traj','Gas_Traj');
end
%% Masking
[VentMask,DisMask] = all_in_one_masking(write_path);

if isnan(VentMask)
    VentMask = AllinOne_Tools.erode_dilate(Vent_Im,1,5);
end
if isnan(DisMask) 
    DisMask = AllinOne_Tools.erode_dilate(HiRes_Gas_Image,1,5);
end

VentMask = logical(VentMask);
DisMask = logical(DisMask);

%% Gas Exchange Analysis
%analyze_ge_images(Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,H1_Image_Dis,Cal_Raw,DisMask,write_path,Dis_Fid,Gas_Fid,Params,Dis_Traj,Gas_Traj)

%% Ventilation Analysis
%analyze_vent_images(write_path,Vent_Im,H1_Image_Vent,VentMask,Params.scandatestr)

%% Wiggle Analysis
analyze_wiggles(Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,H1_Image_Dis,Cal_Raw,DisMask,write_path,Dis_Fid,Gas_Fid,Params,Dis_Traj,Gas_Traj);

%% Clean up
close all;
fclose all;