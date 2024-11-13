function disp_ct_xenon(mypath)
%Load CT image - will need to fix this path)
try
    CT_Image = double(niftiread(fullfile(mypath,'All_in_One_Analysis','CT_4_XenonAnalysis','CT_Image.nii.gz')));
catch
    CT_Image = double(niftiread(fullfile(mypath,'CT.nii.gz')));
end

RBCMap = [linspace(0,1,256)',linspace(0,0,256)',linspace(0,0,256)'];
MemMap = [linspace(0,185/256,256)',linspace(0,58/256,256)',linspace(0,206/256,256)'];
SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier
VentMap = [linspace(0,0,256)',linspace(0,1,256)',linspace(0,1,256)'];
MALBMap = [255 0 0;255 192 0; 0 0 255]/255;
ATROPOSMap = [255 0 0; 255 192 0; 0 255 0; 0 0 255]/255;

%Probably will need to do one at a time... These are pretty large images.
%% Membrane/Gas
membrane = double(niftiread(fullfile(mypath,'CT_Registrations','Membrane_warped.nii.gz')));
ct_tiff_write(CT_Image,membrane,MemMap,[0.01 2],0.75,'Membrane_to_Gas',mypath)
clear membrane

%% Membrane Labeled
membrane_labeled = double(niftiread(fullfile(mypath,'CT_Registrations','Membrane_Labeled_warped.nii.gz')));
%ct_tiff_write(CT_Image,membrane_labeled,EightBinMap,[0.01 8],0.75,'Binned_Membrane',mypath)
ct_overlay(CT_Image,membrane_labeled,EightBinMap,[0.01 8],0.75,'Binned_Membrane',72)
clear membrane_labeled

%% RBC/Gas
% RBC = double(niftiread(fullfile(mypath,'CT_Registrations','RBC_warped.nii.gz')));
% ct_tiff_write(CT_Image,RBC,RBCMap,[0.01 0.75],0.75,'RBC_to_Gas',mypath)
% clear RBC

%% RBC Labeled
RBC_labeled = double(niftiread(fullfile(mypath,'CT_Registrations','RBC_Labeled_warped.nii.gz')));
%ct_tiff_write(CT_Image,RBC_labeled,SixBinMap,[0.01 6],0.75,'Binned_RBC',mypath)
ct_overlay(CT_Image,RBC_labeled,EightBinMap,[0.01 8],0.75,'Binned_RBC',72)

clear RBC_labeled

%% RBC/Membrane Labeled
% RBCMem_labeled = double(niftiread(fullfile(mypath,'All_in_One_Analysis','RBC2Bar_Labeled_warped.nii.gz')));
% ct_tiff_write(CT_Image,RBCMem_labeled,SixBinMap,[0.01 6],0.75,'Binned_RBC2Mem',mypath)
% clear RBCMem_labeled

%% Ventilation 
Vent = double(niftiread(fullfile(mypath,'CT_Registrations','Ventilation_warped.nii.gz')));
try
    Vent_Mask = double(niftiread(fullfile(mypath,'CT_Registrations','CT_mask.nii.gz')));
catch
    Vent_Mask = ones(size(Vent));
end
Vent = Vent/prctile(Vent(:),97);
Vent = Vent.*Vent_Mask;
%ct_tiff_write(CT_Image,Vent,VentMap,[0.01 1],0.75,'Ventilation',mypath)
ct_overlay(CT_Image,Vent,VentMap,[0.01 1],0.75,'Ventilation',72)
clear Vent
%% Ventilation Labeled Mask
MALB = double(niftiread(fullfile(mypath,'CT_Registrations','Ventilation_elbicho_warped.nii.gz')));
ct_tiff_write(CT_Image,MALB,ATROPOSMap,[0.01 3],0.75,'Binned_Ventilation',mypath)
clear MALB
% %% LB Ventilation Mask
% LB = double(niftiread(fullfile(mypath,'All_in_One_Analysis','N4_LB_Ventilation_Labeled_warped.nii.gz')));
% ct_tiff_write(CT_Image,LB,SixBinMap,[0.01 6],0.75,'Reference_Distribution_Ventilation_Binning',mypath)
% clear LB
% %% Atropos Ventilation Mask
% Atropos = double(niftiread(fullfile(mypath,'All_in_One_Analysis','N4_LB_Ventilation_Labeled_warped.nii.gz')));
% ct_tiff_write(CT_Image,Atropos,ATROPOSMap,[0.01 4],0.75,'Atropos_Ventilation_Binning',mypath)
% clear Atropos
