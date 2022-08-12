function disp_ct_xenon(mypath)
%Load CT image - will need to fix this path)
CT_Image = double(niftiread(fullfile(mypath,'final_registration','hp_ct.nii.gz')));

RBCMap = [linspace(0,1,256)',linspace(0,0,256)',linspace(0,0,256)'];
MemMap = [linspace(0,185/256,256)',linspace(0,58/256,256)',linspace(0,206/256,256)'];
SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier
VentMap = [linspace(0,0,256)',linspace(0,1,256)',linspace(0,1,256)'];

%Probably will need to do one at a time... These are pretty large images.
%% Membrane/Gas
membrane = double(niftiread(fullfile(mypath,'All_in_One_Analysis','Barrier_to_Gas_warped.nii.gz')));
ct_tiff_write(CT_Image,membrane,MemMap,[0.01 2],0.75,'Membrane',mypath)
clear membrane

%% Membrane Labeled
membrane_labeled = double(niftiread(fullfile(mypath,'All_in_One_Analysis','Barrier_Labeled_warped.nii.gz')));
ct_tiff_write(CT_Image,membrane_labeled,EightBinMap,[0.01 8],0.5,'Binned_Membrane',mypath)
clear membrane_labeled

%% RBC/Gas
RBC = double(niftiread(fullfile(mypath,'All_in_One_Analysis','RBC_to_Gas_warped.nii.gz')));
ct_tiff_write(CT_Image,RBC,RBCMap,[0.01 0.75],0.75,'RBC',mypath)
clear RBC

%% RBC Labeled
RBC_labeled = double(niftiread(fullfile(mypath,'All_in_One_Analysis','RBC_Labeled_warped.nii.gz')));
ct_tiff_write(CT_Image,RBC_labeled,SixBinMap,[0.01 6],0.5,'Binned_RBC',mypath)
clear RBC_labeled