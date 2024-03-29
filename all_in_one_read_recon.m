function [Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,Vent_Im,H1_Image_Vent,H1_Image_Dis,Cal_Raw,Dis_Fid,Gas_Fid,Params,Dis_Traj] = all_in_one_read_recon()

try 
    files = dir(fullfile(pwd,'Raw'));
    Cell_files = struct2cell(files);
    file_names = Cell_files(1,:);
    folder_names = Cell_files(2,:);
    xeprot = 'Vent_GasExchange_20210819';
    h1prot = 'Vent_GasEx_Anatomic_20210819';
    calprot = 'XeCal_ShortTR_20210827';
    
    xe_file = file_names{find(contains(file_names,xeprot),1,'last')};
    anat_file = file_names{find(contains(file_names,h1prot),1,'last')};
    cal_file = file_names{find(contains(file_names,calprot),1,'last')};
    
    xe_file = fullfile(pwd,'Raw',xe_file);
    anat_file = fullfile(pwd,'Raw',anat_file);
    cal_file = fullfile(pwd,'Raw',cal_file);
    %Assume that raw data is in a folder called "Raw"
    write_path = pwd;
    %write_path((end-3):end) = [];
    write_path = fullfile(write_path,'All_in_One_Analysis');
    if ~isfolder(write_path)
        mkdir(write_path);
    end
catch
    xe_file = uigetfile('.dat','Select Xenon File');
    anat_file = uigetfile('.dat','Select Anatomic File');
    cal_file = uigetfile('.dat','Select Calibration File');
    write_path = uigetdir(pwd,'Select Output Folder');
end

%% Reconstruct
[Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,Vent_Im,H1_Image_Vent,H1_Image_Dis,Cal_Raw,Dis_Fid,Gas_Fid,Params,Dis_Traj] = AllinOne_Tools.reco_allinone(xe_file,anat_file,cal_file);

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