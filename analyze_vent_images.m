function analyze_vent_images(write_path,Vent,Anat_Image,Mask)

Vent = abs(Vent);

%% Get SNR
SE = 3;
[x,y,z]=meshgrid(-SE:SE,-SE:SE, -SE:SE);
nhood=x.^2+y.^2+z.^2 <=SE^2;                % structuring element size
se1=strel('arbitrary',nhood);
NoiseMask = imdilate(Mask,se1);
NoiseMask = ~NoiseMask;

SNR = (mean(Vent(Mask==1))-mean(Vent(NoiseMask==1)))/std(Vent(NoiseMask==1));

%% Now, need to do some bias correction 
%On a PC, use Matt's code
if ispc
    [Vent_BF,BiasField] = AllinOne_Tools.Vent_BiasCorrection(Vent,Mask);
end
%If not a PC, we should be able to get Bias Corrected Image from the
%Atropos analysis
%% Need to add K-means clustering - Almost certainly easiest to use ANTs for this
try
    AllinOne_Tools.atropos_analysis(fullfile(write_path,'Vent_Image.nii.gz'),fullfile(write_path,'Anatomic_Image_Mask.nii.gz'));
    Vent_BF = niftiread(fullfile(write_path,'Vent_ImageSegmentation0N4.nii.gz'));
catch
    disp('Cannot Run atropos Analysis')
end

try
    atropos_seg = niftiread(fullfile(write_path,'Vent_ImageSegmentation.nii.gz'));
    NT_Output = AllinOne_Tools.atropos_vent_analysis(Vent,atropos_seg);
catch
    disp('No atropos Segmentation Found')
end


%% Start with CCHMC Method (Mean Anchored Linear Binning)
%First do not bias corrected
try
    MALB_Output = AllinOne_Tools.MALB_vent_analysis(Vent,Mask);
catch
    disp('Mean Anchored Linear Binning Analysis Failed - non bias corrected image')
end
%Now Bias Corrected
try
    MALB_BF_Output = AllinOne_Tools.MALB_vent_analysis(Vent_BF,Mask);
catch
    disp('Mean Anchored Linear Binning Analysis Failed - bias corrected image')
end

%% Next, we'll do Linear Binning Method (a la Duke)
%First not bias corrected
try 
    LB_Output = AllinOne_Tools.LB_vent_analysis(Vent,Anat_Image,Mask,0);
catch
    disp('Linear Binning Analysis Failed - non bias corrected image')
end
%Then Bias Corrected
try 
    LB_BF_Output = AllinOne_Tools.LB_vent_analysis(Vent_BF,Anat_Image,Mask,1);
catch
    disp('Linear Binning Analysis Failed - bias corrected image')
end

%% Save the full workspace
save(fullfile(write_path,'Vent_Analysis_Workspace.mat'));
workspace_path = fullfile(write_path,'Vent_Analysis_Workspace.mat');

%% Now Reporting - Individual reports for everything + one Giant Report

idcs = strfind(write_path,filesep);%determine location of file separators
sub_ind = strfind(write_path,'Xe-');
move = true;
while move
    if write_path(sub_ind-1) ~= '_'
        sub_ind = sub_ind - 1;
    else
        move = false;
    end
end
Subject = write_path(sub_ind:(idcs(end)-1));
try
    Rpttitle = ['Subject_' Subject '_Ventilation_Summary_MALB'];
    AllinOne_Tools.create_ventilation_report(write_path,Vent,MALB_Output,SNR,Rpttitle);
catch
    disp('No MALB Summary written')
end
try
    Rpttitle = ['Subject_' Subject '_Ventilation_Summary_MALB_BiasCorrection'];
    AllinOne_Tools.create_ventilation_report(write_path,Vent_BF,MALB_BF_Output,SNR,Rpttitle);
catch
    disp('No MALB-Bias Summary written')
end
try
    Rpttitle = ['Subject_' Subject '_Ventilation_Summary_LB'];
    AllinOne_Tools.create_ventilation_report(write_path,Vent_BF,LB_Output,SNR,Rpttitle);
catch
    disp('No LB Summary written')
end
try
    Rpttitle = ['Subject_' Subject '_Ventilation_Summary_LB_BiasCorrection'];
    AllinOne_Tools.create_ventilation_report(write_path,Vent_BF,LB_BF_Output,SNR,Rpttitle);
catch
    disp('No Bias Corrected LB Summary written')
end

try
    Rpttitle = ['Subject_' Subject '_Ventilation_Summary_atropos_functional_segmentation'];
    AllinOne_Tools.create_ventilation_report(write_path,Vent,NT_Output,SNR,Rpttitle);
catch
    disp('No atropos Functional Segmentation Summary written')

end

try
    AllinOne_Tools.create_full_ventilation_report(write_path,workspace_path);
catch
    disp('No Full Report Written')
end