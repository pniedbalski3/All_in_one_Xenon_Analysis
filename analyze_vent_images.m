function analyze_vent_images(write_path,Vent,Anat_Image,Mask,scandate)

Vent = abs(Vent);

parent_path = which('analyze_vent_images');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

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
    [Vent_BF,BiasField] = AllinOne_Tools.Vent_BiasCorrection(Vent,Mask);
end
%If not a PC, we should be able to get Bias Corrected Image from the
%Atropos analysis
%% Need to add K-means clustering - Almost certainly easiest to use ANTs for this
try
    AllinOne_Tools.atropos_analysis(fullfile(write_path,'Vent_Image.nii.gz'),fullfile(write_path,'HiRes_Anatomic_Mask.nii.gz'));
    Vent_BF = niftiread(fullfile(write_path,'Vent_ImageSegmentation0N4.nii.gz'));
catch
    disp('Cannot Run atropos Analysis')
end

try
    atropos_seg = niftiread(fullfile(write_path,'Vent_ImageSegmentation.nii.gz'));
    NT_Output = AllinOne_Tools.atropos_vent_analysis(Vent,atropos_seg);
catch
    disp('No atropos Segmentation Found')
    NT_Output.Incomplete = nan;
    NT_Output.Complete = nan;
    NT_Output.Hyper = nan;
    NT_Output.Normal = nan;
end


%% Start with CCHMC Method (Mean Anchored Linear Binning)
%First do not bias corrected
try
    MALB_Output = AllinOne_Tools.MALB_vent_analysis(Vent,Mask);
catch
    disp('Mean Anchored Linear Binning Analysis Failed - non bias corrected image')
    MALB_Output.VDP = nan;
    MALB_Output.Incomplete = nan;
    MALB_Output.Complete = nan;
    MALB_Output.Hyper = nan;
end
%Now Bias Corrected
try
    MALB_BF_Output = AllinOne_Tools.MALB_vent_analysis(Vent_BF,Mask);
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
    LB_Output = AllinOne_Tools.LB_vent_analysis(Vent,Anat_Image,Mask,0);
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
    LB_BF_Output = AllinOne_Tools.LB_vent_analysis(Vent_BF,Anat_Image,Mask,1);
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
    AllinOne_Tools.create_ventilation_report(write_path,Vent,LB_Output,SNR,Rpttitle);
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

%% Write to Excel
matfile = 'All_in_One_Ventilation.mat';
excel_summary_file = fullfile(parent_path,'AncillaryFiles','AllinOne_Ventilation_Summary.xlsx');
idcs = strfind(write_path,filesep);%determine location of file separators
try
    sub_ind = strfind(write_path,'Xe-');
    sub_end = find(idcs>sub_ind,1,'first');
    sub_end = idcs(sub_end);
    move = true;
    while move
        if write_path(sub_ind-1) ~= '_'
            sub_ind = sub_ind - 1;
        else
            move = false;
        end
    end
    Subject = write_path(sub_ind:(sub_end-1));
catch
    Subject = 'Unknown';
end

SubjectMatch = [];
try 
    load(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary');
    SubjectMatch = find(strcmpi(AllSubjectSummary.Subject{1},Subject) &...
        strcmpi(AllSubjectSummary.Scan_Date{1},scandate));
catch
    headers = {'Subject', 'Scan_Date',...%Subject Info
                'Process_Date',...%Reconstruction Info
                'SNR',...%Acquisition Info
                'MALB_Defect','MALB_Low','MALB_Hyper','MALB_VDP',...
                'BF_MALB_Defect','BF_MALB_Low','BF_MALB_Hyper','BF_MALB_VDP'...
                'LB_Bin1','LB_Bin2','LB_Bin3','LB_Bin4','LB_Bin5','LB_Bin6',...
                'BF_LB_Bin1','BF_LB_Bin2','BF_LB_Bin3','BF_LB_Bin4','BF_LB_Bin5','BF_LB_Bin6',...
                'ATROPOS_Cluster1','ATROPOS_Cluster2','ATROPOS_Cluster3','ATROPOS_Cluster4'};
    AllSubjectSummary = cell2table(cell(0,size(headers,2)));
    AllSubjectSummary.Properties.VariableNames = headers;
end
NewData = {Subject,scandate,...
            datestr(date,29),...
            SNR,...
            MALB_Output.Complete,MALB_Output.Incomplete,MALB_Output.Hyper,MALB_Output.VDP,...
            MALB_BF_Output.Complete,MALB_BF_Output.Incomplete,MALB_BF_Output.Hyper,MALB_BF_Output.VDP,...
            LB_Output.VentBin1Percent,LB_Output.VentBin2Percent,LB_Output.VentBin3Percent,LB_Output.VentBin4Percent,LB_Output.VentBin5Percent,LB_Output.VentBin6Percent,...
            LB_BF_Output.VentBin1Percent,LB_BF_Output.VentBin2Percent,LB_BF_Output.VentBin3Percent,LB_BF_Output.VentBin4Percent,LB_BF_Output.VentBin5Percent,LB_BF_Output.VentBin6Percent,...
            NT_Output.Complete,NT_Output.Incomplete,NT_Output.Normal,NT_Output.Hyper};
if (isempty(SubjectMatch))%if no match
    AllSubjectSummary = [AllSubjectSummary;NewData];%append
else
    AllSubjectSummary(SubjectMatch,:) = NewData;%overwrite
end
save(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary')
writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)


