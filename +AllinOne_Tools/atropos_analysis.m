function atropos_analysis(Image_Path,Mask_Path)

parent_path = which('Xe_Analysis.atropos_analysis');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

if nargin < 2
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Ventilation Image');
    Image_Path = fullfile(path,filename);
    
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Image Mask');
    Mask_Path = fullfile(path,filename);
end

systemCommand = ['python ' fullfile(parent_path,'Python_Code','funct_seg.py') ' ' Image_Path ' ' Mask_Path];

status = system(systemCommand);
