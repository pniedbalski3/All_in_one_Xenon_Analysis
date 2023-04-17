function atropos_analysis_docker(Image_Path,Mask_Path)

parent_path = which('Xe_Analysis.atropos_analysis');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file


if nargin < 2
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Ventilation Image');
    Image_Path = fullfile(path,filename);
    
    [filename,path] = uigetfile({'*.nii';'*.nii.gz'},'Select Image Mask');
    Mask_Path = fullfile(path,filename);
end

idcs = strfind(Image_Path,filesep);%determine location of file separators
ImPath = Image_Path(1:idcs(end)-1);%remove file
ImName = Image_Path((idcs(end)+1):end);
idcs = strfind(Mask_Path,filesep);%determine location of file separators
MskPath = Mask_Path(1:idcs(end)-1);%remove file
MskName = Mask_Path((idcs(end)+1):end);

Code_Path = '/home/XeAnalysis/Xenon_Pipeline';

mapping = ['-v ' Code_Path ':/mnt/mycode -v ' ImPath ':/mnt/mydata'];

dockercommand = ['docker run ' mapping ' noelmni/antspynet python /mnt/mycode/Analysis_Pipeline/Python_Code/funct_seg.py /mnt/mydata/' ImName ' /mnt/mydata/' MskName];



%systemCommand = ['python ' fullfile(parent_path,'Python_Code','funct_seg.py') ' ' Image_Path ' ' Mask_Path];

status = system(dockercommand);
