[CT_Image_File,CT_Image_Path] = uigetfile('*.nii.gz','Select a CT image');
CT_Path = fullfile(CT_Image_Path,CT_Image_File);

xefold = uigetdir();

VMask = fullfile(xefold,'All_in_One_Analysis','HiRes_Anatomic_mask.nii.gz');
V = fullfile(xefold,'All_in_One_Analysis','Ventilation.nii.gz');
VLab = fullfile(xefold,'All_in_One_Analysis','Ventilation_elbicho.nii.gz');

% Mask_inf = niftiinfo(VMask);
% V_inf = niftiinfo(V);
% VLab_inf = niftiinfo(VLab);
% 
% VIm = niftiread(V);
% VLabIm = niftiread(VLab);
% niftiwrite(VIm,strrep(V,'.nii.gz',''),Mask_inf,'Compressed',true)
% niftiwrite(double(VLabIm),strrep(VLab,'.nii.gz',''),Mask_inf,'Compressed',true)

GEMask = fullfile(xefold,'All_in_One_Analysis','LoRes_Anatomic_mask.nii.gz');
Mem = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','Membrane_to_Gas.nii.gz');
MemLab = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','Membrane_Labeled.nii.gz');
RBC = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','RBC_to_Gas.nii.gz');
RBCLab = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','RBC_Labeled.nii.gz');
% 
% Mask_inf = niftiinfo(GEMask);
% 
% MemIm = niftiread(Mem);
% MemLabIm = niftiread(MemLab);
% niftiwrite(MemIm,strrep(Mem,'.nii.gz',''),Mask_inf,'Compressed',true)
% niftiwrite(double(MemLabIm),strrep(MemLab,'.nii.gz',''),Mask_inf,'Compressed',true)
% 
% RBCIm = niftiread(RBC);
% RBCLabIm = niftiread(RBCLab);
% niftiwrite(RBCIm,strrep(RBC,'.nii.gz',''),Mask_inf,'Compressed',true)
% niftiwrite(double(RBCLabIm),strrep(RBCLab,'.nii.gz',''),Mask_inf,'Compressed',true)

docker_reg_xenon_2_ct(CT_Path,VMask,V,VLab);
docker_reg_xenon_2_ct(CT_Path,GEMask,Mem,MemLab,RBC,RBCLab);