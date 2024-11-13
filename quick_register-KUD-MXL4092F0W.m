[CT_Image_File,CT_Image_Path] = uigetfile('*.nii.gz','Select a CT image');
CT_Path = fullfile(CT_Image_Path,CT_Image_File);

xefold = uigetdir();

VMask = fullfile(xefold,'All_in_One_Analysis','HiRes_Anatomic_mask.nii.gz');
V = fullfile(xefold,'All_in_One_Analysis','Ventilation.nii.gz');
VLab = fullfile(xefold,'All_in_One_Analysis','Ventilation_elbicho.nii.gz');

GEMask = fullfile(xefold,'All_in_One_Analysis','LoRes_Anatomic_mask.nii.gz');
Mem = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','Membrane.nii.gz');
MemLab = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','Membrane_Labeled.nii.gz');
RBC = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','RBC.nii.gz');
RBCLab = fullfile(xefold,'All_in_One_Analysis','Gas_Exchange_Outputs','RBC_Labeled.nii.gz');

docker_reg_xenon_2_ct(CT_Path,VMask,V,VLab);
docker_reg_xenon_2_ct(CT_Path,GEMask,Mem,MemLab,RBC,RBCLab);