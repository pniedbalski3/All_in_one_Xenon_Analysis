function prep_vida_results(mypath,Subject_Prefix)
%%
parent_path = which('prep_vida_results');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:(idcs(end)-1));%remove file

writepath = fullfile(mypath,'CT_4_XenonAnalysis');
mkdir(writepath);
%%
if nargin < 2
    Subject_Prefix = 0;
end

%%
lobes = 'ZUNU_vida-lobes.img.gz';
lobevessel = 'ZUNU_vida-lobe-vessel.img.gz';
lung = 'ZUNU_vida-lung.img.gz';
sublobes = 'ZUNU_vida-sublobes.img.gz';
vessels = 'ZUNU_vida-vessels.img.gz';
aircolor = 'ZUNU_vida-aircolor.img.gz';
airtree = 'ZUNU_vida-airtree.img.gz';
axialthirds = 'ZUNU_vida-axialthirds.img.gz';
fissureness = 'ZUNU_vida-fissureness.img.gz';
fissures = 'ZUNU_vida-fissures.img.gz';
lac3d856 = 'ZUNU_vida-lac3d-856.img.gz';
lac3d910 = 'ZUNU_vida-lac3d-910.img.gz';
lac3d920 = 'ZUNU_vida-lac3d-920.img.gz';
lac3d950 = 'ZUNU_vida-lac3d-950.img.gz';
lobeair = 'ZUNU_vida-lobe-air.img.gz';

if Subject_Prefix(1) ~= 0
    lobes = strrep(lobes,'ZUNU',Subject_Prefix);
    lobevessel = strrep(lobevessel,'ZUNU',Subject_Prefix);
    lung = strrep(lung,'ZUNU',Subject_Prefix);
    sublobes = strrep(sublobes,'ZUNU',Subject_Prefix);
    vessels = strrep(vessels,'ZUNU',Subject_Prefix);
    aircolor = strrep(aircolor,'ZUNU',Subject_Prefix);
    airtree = strrep(airtree,'ZUNU',Subject_Prefix);
    axialthirds = strrep(axialthirds,'ZUNU',Subject_Prefix);
    fissureness = strrep(fissureness,'ZUNU',Subject_Prefix);
    fissures = strrep(fissures,'ZUNU',Subject_Prefix);
    lac3d856 = strrep(lac3d856,'ZUNU',Subject_Prefix);
    lac3d910 = strrep(lac3d910,'ZUNU',Subject_Prefix);
    lac3d920 = strrep(lac3d920,'ZUNU',Subject_Prefix);
    lac3d950 = strrep(lac3d950,'ZUNU',Subject_Prefix);
    lobeair = strrep(lobeair,'ZUNU',Subject_Prefix);
end

%%
try
    [CT,spat] = dicomreadVolume(fullfile(mypath,'dicom'));
    CT = fliplr(rot90(squeeze(CT),-1));

    info = niftiinfo(fullfile(parent_path,'AncillaryFiles','Empty_Nifti_Template.nii.gz'));
    info.ImageSize = size(CT);
    info.PixelDimensions = [spat.PixelSpacings(1,1) spat.PixelSpacings(1,2) spat.PatientPositions(2,3)-spat.PatientPositions(1,3)];
    info.SpaceUnits = 'Millimeter';
    info.Datatype = 'uint16'; 
    info.raw.qoffset_x = spat.PatientPositions(1,1);
    info.raw.qoffset_y = spat.PatientPositions(1,2);
    info.raw.qoffset_z = spat.PatientPositions(1,3);

    info.raw.pixdim = [1 spat.PixelSpacings(1,1) spat.PixelSpacings(1,2) spat.PatientPositions(2,3)-spat.PatientPositions(1,3) 0 0 0 0];
    info.raw.xyzt_units = 2;
    info.raw.scl_slope = 1;
    info.raw.qform_code = 1;
    info.raw.quatern_d = 1;
    info.raw.dim = [3 size(CT,1) size(CT,2) size(CT,3), 1, 1, 1, 1];

    info.MultiplicativeScaling = 1;
    info.SpatialDimension = 0;

    %info.TransformName = 'Qform';
    %info.Transform.T = [-Vox_Size 0 0 0;0 -Vox_Size 0 0;0 0 Vox_Size 0; -FOV/2 -FOV/2 -FOV/2 1];
    niftiwrite(CT,fullfile(writepath,'CT_Image'),info,'Compressed',true);
catch
    disp('CT image not read')
end
%% 
try
    img = lobes;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(lobes,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'LobeMask'),'Compressed',true);
catch
    disp('Lobes not found')
end

try
    img = lobevessel;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Lobe_Vessel_Mask'),'Compressed',true);
catch
    disp('Lobe Vessel not found')
end

try
    img = lung;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Lung_Mask'),'Compressed',true);
catch
    disp('Lung Masks not found')
end

try
    basic_lung = flip(tmp,3);
    basic_lung(basic_lung>0) = 1;
    niftiwrite(basic_lung,fullfile(writepath,'CT_Lung_Mask'),'Compressed',true);
catch
    disp('Basic Lung Mask not written')
end

try
    img = sublobes;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'SubLobe_Mask),'Compressed',true);
catch
    disp('Sublobes not found')
end

try    
    img = vessels;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Vessel_Mask'),'Compressed',true);
catch
    disp('Vessels not found')
end

try
    img =aircolor;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Air_Color_Mask'),'Compressed',true);
catch
    disp('Aircolor not found')
end

try
    img =airtree;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Airway_Tree_Mask'),'Compressed',true);
catch
    disp('Airway Tree not found')
end

try    
    img =axialthirds;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Axial_Thirds_Mask'),'Compressed',true);
catch
    disp('AxialThirds not found')
end

try    
    img =fissureness;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Fissureness'),'Compressed',true);
catch
    disp('Fissureness not found')
end

try    
    img =fissures;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'Fissures'),'Compressed',true);
catch
    disp('Fissures not found')
end

try    
    img =lac3d856;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'lac3d856'),'Compressed',true);
catch
    disp('Lac3D-856 not found')
end

try    
    img =lac3d910;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'lac3d910'),'Compressed',true);
catch
    disp('Lac3D-910 not found')
end

try    
    img =lac3d920;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'lac3d920'),'Compressed',true);
catch
    disp('Lac3D-920 not found')
end

try    
    img =lac3d950;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'lac3d950'),'Compressed',true);
catch
    disp('Lac3D-950 not found')
end

try
    img =lobeair;
    tmp = niftiread(fullfile(mypath,img));
    myname = img(1:(strfind(img,'.img.gz')-1));
    niftiwrite(flip(tmp,3),fullfile(writepath,'lobeair'),'Compressed',true);
catch
    disp('Lobe Air not found')
end

    

