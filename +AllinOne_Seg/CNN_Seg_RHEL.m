function CNN_Seg_RHEL(Image_Path)

parent_path = which('Segmentation.CNN_Seg');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

%user = getenv('USER');


%docker run -v /home/XeAnalysis:/mnt/mycode -v /home/pniedbalski@kumc.edu/P-Drive/IRB_STUDY00146119_Xe_Imaging/20230407_Xe-056:/mnt/mydata noelmni/antspynet python /mnt/mycode/Xenon_Pipeline/Analysis_Pipeline/Python_Code/segment_lungs.py /mnt/mydata/LoRes_Anatomic.nii.gz

if nargin < 1
    [filename,Impath] = uigetfile({'*.nii';'*.nii.gz'},'Select Anatomic File to Segment');
    Image_Path = fullfile(Impath,filename);
end

idcs = strfind(Image_Path,filesep);%determine location of file separators
ImPath = Image_Path(1:idcs(end)-1);%remove file
ImName = Image_Path((idcs(end)+1):end);
Code_Path = '/home/XeAnalysis/Xenon_Pipeline';

mapping = ['-v ' Code_Path ':/mnt/mycode -v ' ImPath ':/mnt/mydata'];

dockercommand = ['docker run ' mapping ' noelmni/antspynet /mnt/mycode/Analysis_Pipeline/Python_Code/segment_lungs.py /mnt/mydata/' ImName];

status = system(dockercommand);
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