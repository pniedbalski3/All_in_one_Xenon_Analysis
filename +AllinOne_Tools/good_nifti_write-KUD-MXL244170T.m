function info = good_nifti_write(Image,Vox_Size)

%Function to write out imaging metadata based on passed twix file

parent_path = which('AllinOne_Tools.good_nifti_write');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

%Start by reading in a blank nifti template

info = niftiinfo(fullfile(parent_path,'AncillaryFiles','Empty_Nifti_Template.nii.gz'));

info.ImageSize = size(Image);
info.PixelDimensions = [Vox_Size Vox_Size Vox_Size];

