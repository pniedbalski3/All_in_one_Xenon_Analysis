function info = nifti_metadata(Image,Vox_Size,FOV)

%Function to write out imaging metadata based on passed twix file

parent_path = which('AllinOne_Tools.good_nifti_write');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

%Start by reading in a blank nifti template

info = niftiinfo(fullfile(parent_path,'AncillaryFiles','Empty_Nifti_Template.nii.gz'));

ImSize = size(Image,1);

info.ImageSize = size(Image);
info.PixelDimensions = [Vox_Size Vox_Size Vox_Size];
info.SpaceUnits = 'Millimeter';
info.raw.qoffset_x = FOV/2;
info.raw.qoffset_y = FOV/2;
info.raw.qoffset_z = FOV/2;

info.raw.pixdim = [1 Vox_Size Vox_Size Vox_Size 0 0 0 0];
info.raw.xyzt_units = 2;
info.raw.scl_slope = 1;
info.raw.qform_code = 1;
info.raw.quatern_d = 1;

info.MultiplicativeScaling = 1;
info.SpatialDimension = 0;

%info.TransformName = 'Qform';
%info.Transform.T = [-Vox_Size 0 0 0;0 -Vox_Size 0 0;0 0 Vox_Size 0; -FOV/2 -FOV/2 -FOV/2 1];
