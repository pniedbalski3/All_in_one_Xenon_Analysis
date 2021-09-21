function allinone_recon()
%% Identify Image files - done in kind of a lazy way
try 
    files = dir(pwd);
    Cell_files = struct2cell(files);
    file_names = Cell_files(1,:);

    xeprot = 'Vent_GasExchange_20210819';
    h1prot = 'Vent_GasEx_Anatomic_20210819';
    calprot = 'XeCal_ShortTR_20210827';
    
    xe_file = file_names{find(contains(file_names,xeprot),1,'last')};
    anat_file = file_names{find(contains(file_names,h1prot),1,'last')};
    cal_file = file_names{find(contains(file_names,calprot),1,'last')};
    %Assume that raw data is in a folder called "Raw"
    write_path = pwd;
    write_path((end-3):end) = [];
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
[Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,Vent_Im,H1_Image_Vent,H1_Image_Dis,Cal_Raw,Dis_Fid,Gas_Fid,Params] = reco_allinone(xe_file,anat_file,cal_file);

%% Images are reconstructed - Write out:
niftiwrite(Dis_Image,fullfile(write_path,'Dissolved_Image'),'Compressed',true);
niftiwrite(LoRes_Gas_Image,fullfile(write_path,'LoRes_Gas_Image'),'Compressed',true);
niftiwrite(Vent_Im,fullfile(write_path,'Vent_Image'),'Compressed',true);
niftiwrite(H1_Image_Vent,fullfile(write_path,'HiRes_Anatomic'),'Compressed',true);
niftiwrite(H1_Image_Dis,fullfile(write_path,'LoRes_Anatomic'),'Compressed',true);

%% Masking
[VentMask,DisMask] = all_in_one_masking(write_path);

if isnan(VentMask)
    VentMask = AllinOne_Tools.erode_dilate(Vent_Im,1,5);
end
if isnan(DisMask) 
    DisMask = AllinOne_Tools.erode_dilate(Dis_Image,1,5);
end

VentMask = logical(VentMask);
DisMask = logical(DisMask);

%% Gas Exchange Analysis
analyze_ge_images(Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,H1_Image_Dis,Cal_Raw,DisMask,write_path,Dis_Fid,Gas_Fid,Params)

%% Ventilation Analysis
analyze_vent_images(write_path,Vent_Im,H1_Image_Vent,VentMask)

%% Clean up
close all
fclose all