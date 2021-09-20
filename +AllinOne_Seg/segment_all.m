function segment_all(path,MaskFlag)

%Function to look at reconstruction summary and segment all anatomic images
%found therein.

if nargin < 1
    path = uigetdir([],'Select Subject Data Folder');
    MaskFlag = 'All';
elseif nargin == 1
    MaskFlag = 'All';
end

%Open the library file

recon_file = fopen(char(fullfile(path,'Reconstruction_Summary.txt')));
recon_file_read = textscan(recon_file,'%s','delimiter','\n');
recon_file_read = recon_file_read{1};

%Library file is written to have "$$" in lines that are important
recon_file_foldername_index = find(contains(recon_file_read,'$$'));

Error_Count = 1; 
Error_List = {};

%Gas Exchange images are already segmented - Only need to segment
%ventilation and diffusion images
for i = 1:length(recon_file_foldername_index)
    foldername = recon_file_read{recon_file_foldername_index(i)}(3:end);
    %Check if QC or Gas exchange folder
    if contains(foldername,'QC') || contains(foldername,'Gas_Exchange')
        continue;
    end
    %Check Flags to see if what needs to be done
    if ~strcmpi(MaskFlag,'All') && ~contains(foldername,MaskFlag)
        continue;
    end
    %Check if a manual mask exists already
    if isfile(fullfile(path,foldername,'Manual_Mask.nii.gz'))
        continue;
    end
    %All anatomic images are given the same name -
    anatomic_file = fullfile(path,foldername,'Anatomic_Image.nii.gz');
    if exist(anatomic_file)
        try
            Segmentation.CNN_Seg(anatomic_file);
        catch
            disp('Unable to run Deep Learning Segmentation');
            Error_List{Error_Count} = ['For Folder, ' foldername ', Deep Learning Segmentation Failed'];
            Error_Count = Error_Count + 1;
        end
    else
        Error_List{Error_Count} = ['For Folder, ' foldername ', No Anatomic Image Present'];
        Error_Count = Error_Count + 1;
    end
    % Check if the segmentation was created. If not, flag it 
    if ~exist(fullfile(foldername,'Anatomic_Image_Mask.nii.gz')) 
        Error_List{Error_Count} = ['For Folder, ' foldername ', No Mask Exists at end of segmentation'];
        Error_Count = Error_Count + 1;
    end    
    
end
%Handle Errors
if ~isempty(Error_List)
    %If analysis error log doesn't exist, create it here
    if ~exist(fullfile(path,'Analysis_Error_Log.txt'))
        fileID = fopen(fullfile(path,'Analysis_Error_Log.txt'),'w');
    else
        fileID = fopen(fullfile(path,'Analysis_Error_Log.txt'),'at');
    end
    fprintf(fileID,'***************************************************************\n');
    fprintf(fileID,['Analysis Attempted ' datestr(now) '\n']);
    fprintf(fileID,'\n');
    fprintf(fileID,'*****************Segmentation Error Log**********************\n');    
    for i = 1:length(Error_List)
        fprintf(fileID,[Error_List{i} '\n']);
    end
    fclose(fileID);
end
