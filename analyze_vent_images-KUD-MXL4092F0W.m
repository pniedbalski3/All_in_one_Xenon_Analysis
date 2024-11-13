function analyze_vent_images(write_path,Vent,Anat_Image,Mask,scandate,Params)

Vent = abs(Vent);

parent_path = which('analyze_vent_images');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

V_file = fopen(fullfile(parent_path,'Pipeline_Version.txt'),'r');
Pipeline_Version = fscanf(V_file,'%s');

if ~isfolder(fullfile(write_path,'Ventilation_Output'))
    mkdir(fullfile(write_path,'Ventilation_Output'));
end


%% Get SNR
SE = 7; %Let's get rid of many more points - want to avoid trachea, etc.
[x,y,z]=meshgrid(-SE:SE,-SE:SE, -SE:SE);
nhood=x.^2+y.^2+z.^2 <=SE^2;                % structuring element size
se1=strel('arbitrary',nhood);
NoiseMask = imdilate(Mask,se1);
NoiseMask = ~NoiseMask;

SNR = (mean(Vent(Mask==1))-mean(Vent(NoiseMask==1)))/std(Vent(NoiseMask==1));

%% Now, need to do some bias correction 
%On a PC, use Matt's code
if ispc
    [Vent_BF,~] = AllinOne_Tools.Vent_BiasCorrection(Vent,Mask);
end
%If not a PC, we should be able to get Bias Corrected Image from the
%Atropos analysis
%% Need to add K-means clustering - Almost certainly easiest to use ANTs for this
try
    AllinOne_Tools.atropos_analysis(fullfile(write_path,'Ventilation.nii.gz'),fullfile(write_path,'HiRes_Anatomic_Mask.nii.gz'));
    if ~ispc
        Vent_BF = niftiread(fullfile(write_path,'VentilationSegmentation0N4.nii.gz'));
        %nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
        %niftiwrite(double(Vent_BF),fullfile(write_path,'VentilationSegmentation0N4'),nifti_info,'Compressed',true)
    end
catch
    disp('Cannot Run atropos Analysis')
end

try
    atropos_seg = niftiread(fullfile(write_path,'VentilationSegmentation.nii.gz'));
    
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(atropos_seg,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(atropos_seg),fullfile(write_path,'Vent_ImageSegmentation'),nifti_info,'Compressed',true)
    %Vent = Tools.canonical2matlab(Vent);
    atropos_seg = Tools.canonical2matlab(atropos_seg);
    Atropos_Output = AllinOne_Tools.atropos_vent_analysis(Tools.canonical2matlab(Vent),atropos_seg);
    
catch
    disp('No atropos Segmentation Found')
    Atropos_Output.Incomplete = nan;
    Atropos_Output.Complete = nan;
    Atropos_Output.Hyper = nan;
    Atropos_Output.Normal = nan;
    %Vent = Tools.canonical2matlab(Vent);
end

%After this point, there's no more going to and from nifti, so we can put
%everything in the shape we need for properly oriented images - Vent is
%already there...
%Vent_BF = Tools.canonical2matlab(Vent_BF);
%Anat_Image = Tools.canonical2matlab(Anat_Image);
%Mask = Tools.canonical2matlab(Mask);


%% Start with CCHMC Method (Mean Anchored Linear Binning)
%First do not bias corrected
try
    MALB_Output = AllinOne_Tools.MALB_vent_analysis(Tools.canonical2matlab(Vent),Tools.canonical2matlab(Mask));
catch
    disp('Mean Anchored Linear Binning Analysis Failed - non bias corrected image')
    MALB_Output.VDP = nan;
    MALB_Output.Incomplete = nan;
    MALB_Output.Complete = nan;
    MALB_Output.Hyper = nan;
end
%Now Bias Corrected
try
    MALB_BF_Output = AllinOne_Tools.MALB_vent_analysis(Tools.canonical2matlab(Vent_BF),Tools.canonical2matlab(Mask));
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(MALB_BF_Output.VentBinMap),fullfile(write_path,'N4_MALB_Ventilation_Labeled'),nifti_info,'Compressed',true)
catch
    disp('Mean Anchored Linear Binning Analysis Failed - bias corrected image')
    MALB_BF_Output.VDP = nan;
    MALB_BF_Output.Incomplete = nan;
    MALB_BF_Output.Complete = nan;
    MALB_BF_Output.Hyper = nan;
end

%% Next, we'll do Linear Binning Method (a la Duke)
%First not bias corrected
try 
    LB_Output = AllinOne_Tools.LB_vent_analysis(Tools.canonical2matlab(Vent),Tools.canonical2matlab(Anat_Image),Tools.canonical2matlab(Mask),0);
catch
    disp('Linear Binning Analysis Failed - non bias corrected image')
    LB_Output.VentBin1Percent = nan;
    LB_Output.VentBin2Percent = nan;
    LB_Output.VentBin3Percent = nan;
    LB_Output.VentBin4Percent = nan;
    LB_Output.VentBin5Percent = nan;
    LB_Output.VentBin6Percent = nan;
end
%Then Bias Corrected
try 
    LB_BF_Output = AllinOne_Tools.LB_vent_analysis(Tools.canonical2matlab(Vent_BF),Tools.canonical2matlab(Anat_Image),Tools.canonical2matlab(Mask),1);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(LB_BF_Output.VentBinMap),fullfile(write_path,'N4_LB_Ventilation_Labeled'),nifti_info,'Compressed',true)
catch
    disp('Linear Binning Analysis Failed - bias corrected image')
    LB_BF_Output.VentBin1Percent = nan;
    LB_BF_Output.VentBin2Percent = nan;
    LB_BF_Output.VentBin3Percent = nan;
    LB_BF_Output.VentBin4Percent = nan;
    LB_BF_Output.VentBin5Percent = nan;
    LB_BF_Output.VentBin6Percent = nan;
end

%% Save the full workspace
save(fullfile(write_path,'Vent_Analysis_Workspace.mat'));
workspace_path = fullfile(write_path,'Vent_Analysis_Workspace.mat');

%% Now Reporting - Individual reports for everything + one Giant Report

idcs = strfind(write_path,filesep);%determine location of file separators
try
    subject_tmp = write_path((idcs(end-1)+1):(idcs(end)-1));
    if contains(subject_tmp,'_')
        uscore = strfind(subject_tmp,'_');
        if length(uscore) == 1 && (length(subject_tmp)-uscore(1)) < 3
            subject_tmp(1:uscore(1)) = [];
        else
            subject_tmp(1:uscore(1)) = [];
        end
    end
    Subject = subject_tmp;
catch
    Subject = 'Unknown';
end

try
    Rpttitle = [Subject '_VDP_Summary_MALB'];
    AllinOne_Tools.create_ventilation_report(write_path,Tools.canonical2matlab(Vent),MALB_Output,SNR,Rpttitle);
catch
    disp('No MALB Summary written')
end
try
    Rpttitle = [Subject '_VDP_Summary_N4MALB'];
    AllinOne_Tools.create_ventilation_report(write_path,Vent_BF,MALB_BF_Output,SNR,Rpttitle);
catch
    disp('No MALB-Bias Summary written')
end
try
    Rpttitle = [Subject '_VDP_Summary_LB'];
    AllinOne_Tools.create_ventilation_report(write_path,Tools.canonical2matlab(Vent),LB_Output,SNR,Rpttitle);
catch
    disp('No LB Summary written')
end
try
    Rpttitle = [Subject '_VDP_Summary_N4LB'];
    AllinOne_Tools.create_ventilation_report(write_path,Tools.canonical2matlab(Vent_BF),LB_BF_Output,SNR,Rpttitle);
catch
    disp('No Bias Corrected LB Summary written')
end

try
    Rpttitle = [Subject '_VDP_Summary_Atropos'];
    AllinOne_Tools.create_ventilation_report(write_path,Tools.canonical2matlab(Vent),Atropos_Output,SNR,Rpttitle);
catch
    disp('No atropos Functional Segmentation Summary written')

end

try
    AllinOne_Tools.create_full_ventilation_report(write_path,workspace_path);
catch
    disp('No Full Report Written')
end

%% Get Ventilation Heterogeneity
[H_Map,H_Index] = xe_vent_heterogeneity(Vent_BF,Mask,5);
save(fullfile(write_path,'Ventilation_Heterogeneity.mat'),'H_Map','H_Index');
CV = std(Vent(Mask(:)))/mean(Vent(Mask(:)));
CV_BF = std(Vent_BF(Mask(:)))/mean(Vent(Mask(:)));

%% Write to Excel
matfile = 'All_in_One_Ventilation.mat';
excel_summary_file = fullfile(parent_path,'AncillaryFiles','AllinOne_Ventilation_Summary.xlsx');
idcs = strfind(write_path,filesep);%determine location of file separators
try
    subject_tmp = write_path((idcs(end-1)+1):(idcs(end)-1));
    if contains(subject_tmp,'_')
        uscore = strfind(subject_tmp,'_');
        if length(uscore) == 1 && (length(subject_tmp)-uscore(1)) < 3
            subject_tmp(1:uscore(1)) = [];
        else
            subject_tmp(1:uscore(1)) = [];
        end
    end
    Subject = subject_tmp;
catch
    Subject = 'Unknown';
end

SubjectMatch = [];
try 
    load(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary');
    SubjectMatch = find(strcmpi(AllSubjectSummary.Subject,Subject) &...
        strcmpi(AllSubjectSummary.Scan_Date,scandate));
catch
    headers = {'Subject', 'Analysis_Version','Scan_Date',...%Subject Info
                'Process_Date',...%Reconstruction Info
                'SNR',...%Acquisition Info
                'MALB_Defect','MALB_Low','MALB_Hyper','MALB_VDP',...
                'BF_MALB_Defect','BF_MALB_Low','BF_MALB_Hyper','BF_MALB_VDP'...
                'LB_Bin1','LB_Bin2','LB_Bin3','LB_Bin4','LB_Bin5','LB_Bin6',...
                'BF_LB_Bin1','BF_LB_Bin2','BF_LB_Bin3','BF_LB_Bin4','BF_LB_Bin5','BF_LB_Bin6',...
                'ATROPOS_Cluster1','ATROPOS_Cluster2','ATROPOS_Cluster3','ATROPOS_Cluster4',...
                'H_Index','CV','CV_BF'};
    AllSubjectSummary = cell2table(cell(0,size(headers,2)));
    AllSubjectSummary.Properties.VariableNames = headers;
end
NewData = {Subject,Pipeline_Version,scandate,...
            datestr(date,29),...
            SNR,...
            MALB_Output.Complete,MALB_Output.Incomplete,MALB_Output.Hyper,MALB_Output.VDP,...
            MALB_BF_Output.Complete,MALB_BF_Output.Incomplete,MALB_BF_Output.Hyper,MALB_BF_Output.VDP,...
            LB_Output.VentBin1Percent,LB_Output.VentBin2Percent,LB_Output.VentBin3Percent,LB_Output.VentBin4Percent,LB_Output.VentBin5Percent,LB_Output.VentBin6Percent,...
            LB_BF_Output.VentBin1Percent,LB_BF_Output.VentBin2Percent,LB_BF_Output.VentBin3Percent,LB_BF_Output.VentBin4Percent,LB_BF_Output.VentBin5Percent,LB_BF_Output.VentBin6Percent,...
            Atropos_Output.Complete,Atropos_Output.Incomplete,Atropos_Output.Normal,Atropos_Output.Hyper,...
            H_Index,CV,CV_BF};
if (isempty(SubjectMatch))%if no match
    AllSubjectSummary = [AllSubjectSummary;NewData];%append
else
    AllSubjectSummary(SubjectMatch,:) = NewData;%overwrite
end
save(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary')
writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)



