function imdisplay_allinone(infolder,slice_vent,slice_GE)

if nargin < 2
    slice_GE = nan;
    slice_vent = nan;
end
if nargin < 3
    slice_GE = nan;
end

sub1 = 'All_in_One_Analysis';

%% Load in ventilation data
vent_nii = 'Vent_Image.nii.gz';
vent_nii = 'Vent_ImageSegmentation0N4.nii.gz';
vent_anat_nii = 'HiRes_Anatomic.nii.gz';
vent_mask_nii = 'HiRes_Anatomic_mask.nii.gz';

vent = double(niftiread(fullfile(infolder,sub1,vent_nii)));
vent_anat = double(niftiread(fullfile(infolder,sub1,vent_anat_nii)));
vent_mask = double(niftiread(fullfile(infolder,sub1,vent_mask_nii)));

vent = Tools.canonical2matlab(vent);
vent_anat = Tools.canonical2matlab(vent_anat);
vent_mask = Tools.canonical2matlab(vent_mask);

if isnan(slice_vent)
    [slice_vent,~,~] = AllinOne_Tools.getimcenter(vent_mask);
end

vent = vent/prctile(vent(vent_mask==1),95);
ProtonMax = max(vent_anat(:));

%% Display slice of ventilation data
my_slice_vent = squeeze(vent(:,:,slice_vent));
my_slice_anat = squeeze(vent_anat(:,:,slice_vent));
my_slice_mask = squeeze(vent_mask(:,:,slice_vent));

CMap = [linspace(0,0,256)',linspace(0,1,256)',linspace(0,1,256)'];

figure('Name','Representative Slice of Vent Image');
[~,~] = Tools.imoverlay(my_slice_anat,my_slice_vent.*my_slice_mask,[0.1,1],[0,0.99*ProtonMax],gray,1,gca);
colormap(gca,CMap);

%% Load Gas Exchange Data
anat_nii = 'LoRes_Anatomic.nii.gz';
mask_nii = 'LoRes_Anatomic_mask.nii.gz';
rbc_nii = 'RBC_to_Gas.nii.gz';
mem_nii = 'Barrier_to_Gas.nii.gz';
vent_lab_nii = 'Vent_Labeled.nii.gz';
rbc_lab_nii = 'RBC_Labeled.nii.gz';
mem_lab_nii ='Barrier_Labeled.nii.gz';

anat = double(niftiread(fullfile(infolder,sub1,anat_nii)));
mask = double(niftiread(fullfile(infolder,sub1,mask_nii)));
rbc = double(niftiread(fullfile(infolder,sub1,rbc_nii)));
mem = double(niftiread(fullfile(infolder,sub1,mem_nii)));
vl = double(niftiread(fullfile(infolder,sub1,vent_lab_nii)));
rbcl = double(niftiread(fullfile(infolder,sub1,rbc_lab_nii)));
meml = double(niftiread(fullfile(infolder,sub1,mem_lab_nii)));

anat = Tools.canonical2matlab(anat);
mask = Tools.canonical2matlab(mask);
rbc = Tools.canonical2matlab(rbc);
mem = Tools.canonical2matlab(mem);
vl = Tools.canonical2matlab(vl);
rbcl = Tools.canonical2matlab(rbcl);
meml = Tools.canonical2matlab(meml);

if isnan(slice_GE)
    [slice_GE,~,~] = AllinOne_Tools.getimcenter(mask);
end
ProtonMax = max(anat(:));

%% Display the slice I want:
vMask = vl;
vMask(vl<2) = 0;
vMask(vl>1) = 1;

my_slice_rbc = squeeze(rbc(:,:,slice_GE));
my_slice_mem = squeeze(mem(:,:,slice_GE));
my_slice_rbcl = squeeze(rbcl(:,:,slice_GE));
my_slice_meml = squeeze(meml(:,:,slice_GE));
my_slice_anat = squeeze(anat(:,:,slice_GE));
my_slice_mask = squeeze(vMask(:,:,slice_GE));

RBCMap = [linspace(0,1,256)',linspace(0,0,256)',linspace(0,0,256)'];
MemMap = [linspace(0,185/256,256)',linspace(0,58/256,256)',linspace(0,206/256,256)'];
SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier
% figure('Name','Representative Slice of Membrane Image');
% [~,~] = Tools.imoverlay(my_slice_anat,my_slice_mem.*my_slice_mask,[0.01,1.5],[0,0.99*ProtonMax],gray,1,gca);
% colormap(gca,MemMap);
% 
% figure('Name','Representative Slice of RBC Image');
% [~,~] = Tools.imoverlay(my_slice_anat,my_slice_rbc.*my_slice_mask,[0.01,0.75],[0,0.99*ProtonMax],gray,1,gca);
% colormap(gca,RBCMap);

figure('Name','Representative Slice of Membrane Image Labeled');
[~,~] = Tools.imoverlay(my_slice_anat,my_slice_meml.*my_slice_mask,[0.01,8],[0,0.99*ProtonMax],gray,1,gca);
colormap(gca,EightBinMap);

figure('Name','Representative Slice of RBC Image Labeled');
[~,~] = Tools.imoverlay(my_slice_anat,my_slice_rbcl.*my_slice_mask,[0.01,6],[0,0.99*ProtonMax],gray,1,gca);
colormap(gca,SixBinMap);

