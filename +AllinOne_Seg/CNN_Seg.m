function CNN_Seg(Image_Path)

parent_path = which('Segmentation.CNN_Seg');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

if nargin < 1
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Anatomic File to Segment');
    Image_Path = fullfile(path,filename);
end

%Image_Path = '/media/sf_Tmp_Share_VM_Folder/Anatomic.nii';
%Try 2D model, if it fails, try 3D model: Chase says 2D model is better,
%but this actually did a terrible job. Switch back to 3D until I figure
%that out.
%model_path_3D = fullfile(parent_path,'Deep_Learning_Models','proton_3D_UNET_v2.h5');
%systemCommand = ['python ' fullfile(parent_path,'Python_Code','segment_lungs.py') ' ' Image_Path ' ''All'' ''True'' ''Fals''' ];
%Use new system command that uses executable 
systemCommand = [fullfile(parent_path,'Python_Code','segment_lungs') ' ' Image_Path];

status = system(systemCommand);

% if status ~= 0
%     %model_path_2D = fullfile(parent_path,'Deep_Learning_Models','proton_seg_Unet2D_v2.h5');
%     systemCommand = ['python ' fullfile(parent_path,'Python_Code','Segment_lungs.py') ' ' Image_Path];
%     status = system(systemCommand);
% end