function docker_reg_xenon_2_ct(CT_Image_Path,Xe_Mask_path,varargin)

% parent_path = which('docker');
% idcs = strfind(parent_path,filesep);%determine location of file separators
% parent_path = parent_path(1:idcs(end-1)-1);%remove file

%user = getenv('USER');


%docker run -v /home/XeAnalysis:/mnt/mycode -v /home/pniedbalski@kumc.edu/P-Drive/IRB_STUDY00146119_Xe_Imaging/20230407_Xe-056:/mnt/mydata noelmni/antspynet python /mnt/mycode/Xenon_Pipeline/Analysis_Pipeline/Python_Code/segment_lungs.py /mnt/mydata/LoRes_Anatomic.nii.gz

% if nargin < 1
%     [filename,Impath] = uigetfile({'*.nii';'*.nii.gz'},'Select Anatomic File to Segment');
%     Image_Path = fullfile(Impath,filename);
% end

idcs = strfind(CT_Image_Path,filesep);%determine location of file separators
ImPath = CT_Image_Path(1:idcs(end)-1);%remove file
ImName = CT_Image_Path((idcs(end)+1):end);

idcs = strfind(Xe_Mask_path,filesep);%determine location of file separators
maskPath = Xe_Mask_path(1:idcs(end)-1);%remove file
maskName = Xe_Mask_path((idcs(end)+1):end);

for i = 1:length(varargin)
    idcs = strfind(varargin{i},filesep);%determine location of file separators
    XeImPath{i} = varargin{i}(1:idcs(end)-1);%remove file
    XeImName{i} = varargin{i}((idcs(end)+1):end);
end



Code_Path = '/home/XeAnalysis/Xenon_Pipeline';
if ispc
    Orig_ImPath = ImPath;
    if ~isfolder(fullfile(Orig_ImPath,'CT_Registrations'))
        mkdir(fullfile(Orig_ImPath,'CT_Registrations'));
    end
    local_path = 'C:/Users/pniedbalski/OneDrive - University of Kansas Medical Center/Documents/local_tmp';
    Code_Path = '"C:/Users/pniedbalski/OneDrive - University of Kansas Medical Center/Documents/GitHub/Xenon_Pipeline"';
    copyfile(CT_Image_Path,local_path);
    copyfile(Xe_Mask_path,local_path);
    for i = 1:length(varargin)
        copyfile(varargin{i},local_path);
    end
    ImPath = '"C:/Users/pniedbalski/OneDrive - University of Kansas Medical Center/Documents/local_tmp"';
end

mapping = ['-v ' Code_Path ':/mnt/mycode -v ' ImPath ':/mnt/mydata'];

%Get CT mask
dockermaskcommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/Analysis_Pipeline/Python_Code/segment_lungs.py /mnt/mydata/' ImName];
status = system(dockermaskcommand);

%Register Mask to CT
dockerregistercommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/Analysis_Pipeline/Python_Code/register_xenon_CT.py /mnt/mydata/' ImName ' /mnt/mydata/' maskName];
status = system(dockerregistercommand);

for i = 1:length(varargin)
    if contains(varargin{i},'Ventilation.nii.gz') || contains(varargin{i},'Membrane.nii.gz') || contains(varargin{i},'RBC.nii.gz') || contains(varargin{i},'Membrane_to_Gas.nii.gz') || contains(varargin{i},'RBC_to_Gas.nii.gz') 
        dockerregistercommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/Analysis_Pipeline/Python_Code/warp_linear.py /mnt/mydata/' ImName ' /mnt/mydata/' maskName ' /mnt/mydata/' XeImName{i}];
    else
        dockerregistercommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/Analysis_Pipeline/Python_Code/warp_label.py /mnt/mydata/' ImName ' /mnt/mydata/' maskName ' /mnt/mydata/' XeImName{i}];
    end
    status = system(dockerregistercommand);
end

if ispc
    Mask_name = strrep(ImName,'.nii.gz','_mask.nii.gz');
    copyfile(fullfile(local_path,Mask_name),fullfile(Orig_ImPath,'CT_Registrations'));
    for i = 1:length(varargin)
        copyfile(fullfile(local_path,strrep(XeImName{i},'.nii.gz','_warped.nii.gz')),fullfile(Orig_ImPath,'CT_Registrations'));
    end
end
%Image_Path = '/media/sf_Tmp_Share_VM_Folder/Anatomic.nii';
%Try 2D model, if it fails, try 3D model: Chase says 2D model is better,
%but this actually did a terrible job. Switch back to 3D until I figure
%that out.
%model_path_3D = fullfile(parent_path,'Deep_Learning_Models','proton_3D_UNET_v2.h5');
%systemCommand = ['python ' fullfile(parent_path,'Python_Code','segment_lungs.py') ' ' Image_Path ' ''All'' ''True'' ''Fals''' ];
%Use new system command that uses executable 
%systemCommand = [fullfile(parent_path,'Python_Code','segment_lungs') ' ' Image_Path];

%status = system(systemCommand);

% if status ~= 0
%     %model_path_2D = fullfile(parent_path,'Deep_Learning_Models','proton_seg_Unet2D_v2.h5');
%     systemCommand = ['python ' fullfile(parent_path,'Python_Code','Segment_lungs.py') ' ' Image_Path];
%     status = system(systemCommand);
% end