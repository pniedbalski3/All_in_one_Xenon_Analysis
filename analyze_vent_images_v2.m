function analyze_vent_images_v2(write_path,Vent,Mask,scandate,Params)

Vent = abs(Vent);

vent_nii_name = 'Ventilation';
mask_nii_name = 'HiRes_Anatomic_Mask';
anat_nii_name = 'HiRes_Anatomic';

Anat_Image = Tools.canonical2matlab(niftiread(fullfile(write_path,[anat_nii_name '.nii.gz'])));

parent_path = which('analyze_vent_images_v2');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

V_file = fopen(fullfile(parent_path,'Pipeline_Version.txt'),'r');
Pipeline_Version = fscanf(V_file,'%s');

idcs = strfind(write_path,filesep);%determine location of file separators
try
    Subject = Params.Subject;
catch
    try
        subject_tmp = write_path((idcs(end-1)+1):(idcs(end)-1));
        if contains(subject_tmp,'_')
            uscore = strfind(subject_tmp,'_');
            subject_tmp(1:uscore(1)) = [];
        end
        Subject = subject_tmp;
    catch
        Subject = 'Unknown';
    end
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
% if ispc
%     [Vent_BF,~] = AllinOne_Tools.Vent_BiasCorrection(Vent,Mask);
% end
%If not a PC, we should be able to get Bias Corrected Image from the
%Atropos analysis
%% Atropos, Fuzzy CMeans, El Bicho
try
    AllinOne_Tools.atropos_analysis_docker(fullfile(write_path,[vent_nii_name '.nii.gz']),fullfile(write_path,[mask_nii_name '.nii.gz']));
    Vent_BF = niftiread(write_path,[vent_nii_name '_N4.nii.gz']);
    Vent_BF = Tools.canonical2matlab(Vent_BF);
catch
    disp('Cannot Run atropos Analysis')
end

Vent_BF = Seg.strong_N4(Vent,double(Mask));
info = niftiinfo(fullfile(write_path,[vent_nii_name '.nii.gz']));
niftiwrite(ReadData.mat2canon(double(Vent_BF)),fullfile(write_path,[vent_nii_name '_N4']),info,'Compressed',true);

try
    atropos_seg = niftiread(fullfile(write_path,[vent_nii_name '_atropos.nii.gz']));
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(atropos_seg,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(atropos_seg),fullfile(write_path,[vent_nii_name 'Segmentation']),nifti_info,'Compressed',true)
    Vent = Tools.canonical2matlab(Vent);
    atropos_seg = Tools.canonical2matlab(atropos_seg);
    Atropos_Output = AllinOne_Tools.generic_label_analysis(Vent,atropos_seg);
    AllinOne_Tools.create_vent_report(write_path,Vent,Atropos_Output,SNR,[Subject '_Atropos_VDP'],Subject)
catch
    disp('No atropos Segmentation Found')
    Vent = Tools.canonical2matlab(Vent);
    for i = 1:6
        Atropos_Output(i).BinPct = nan;
    end
end

try
    atropos_seg_N4 = niftiread(fullfile(write_path,[vent_nii_name '_atropos_N4.nii.gz']));
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(atropos_seg,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(atropos_seg),fullfile(write_path,[vent_nii_name 'Segmentation']),nifti_info,'Compressed',true)
    Vent = Tools.canonical2matlab(Vent);
    atropos_seg_N4 = Tools.canonical2matlab(atropos_seg_N4);
    Atropos_Output_N4 = AllinOne_Tools.generic_label_analysis(Vent_BF,atropos_seg_N4);
    AllinOne_Tools.create_vent_report(write_path,Vent,Atropos_Output_N4,SNR,[Subject '_Atropos_N4_VDP'],Subject)
catch
    disp('No N4 atropos Segmentation Found')
    for i = 1:6
        Atropos_Output_N4(i).BinPct = nan;
    end
end

try
    cmeans_seg = niftiread(fullfile(write_path,[vent_nii_name '_cmeans.nii.gz']));
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(cmeans_seg,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(cmeans_seg),fullfile(write_path,[vent_nii_name '_cmeans']),nifti_info,'Compressed',true)
    cmeans_seg = Tools.canonical2matlab(cmeans_seg);
    CMeans_Output = AllinOne_Tools.generic_label_analysis(Vent,cmeans_seg);
    AllinOne_Tools.create_vent_report(write_path,Vent,CMeans_Output,SNR,[Subject '_CMeans_VDP'],Subject)
catch
    disp('No cmeans Segmentation Found')
    for i = 1:6
        CMeans_Output(i).BinPct = nan;
    end
end

try
    cmeans_seg_BF = niftiread(fullfile(write_path,[vent_nii_name '_cmeans_N4.nii.gz']));
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(cmeans_seg_BF,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(cmeans_seg_BF),fullfile(write_path,[vent_nii_name '_cmeans_BF']),nifti_info,'Compressed',true)
    cmeans_seg_BF = Tools.canonical2matlab(cmeans_seg_BF);
    CMeans_BF_Output = AllinOne_Tools.generic_label_analysis(Vent_BF,cmeans_seg_BF);
    AllinOne_Tools.create_vent_report(write_path,Vent_BF,CMeans_BF_Output,SNR,[Subject '_N4_CMeans_VDP'],Subject)
catch
    disp('No cmeans Segmentation Found')
    for i = 1:6
        CMeans_BF_Output(i).BinPct = nan;
    end
end

try
    elbicho_seg = niftiread(fullfile(write_path,[vent_nii_name '_elbicho.nii.gz']));
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(elbicho_seg,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(elbicho_seg),fullfile(write_path,[vent_nii_name '_elbicho']),nifti_info,'Compressed',true)
    elbicho_seg = Tools.canonical2matlab(elbicho_seg);
    ElBicho_Output = AllinOne_Tools.generic_label_analysis(Vent,elbicho_seg);
    AllinOne_Tools.create_vent_report(write_path,Vent,ElBicho_Output,SNR,[Subject '_ElBicho_VDP'],Subject)
catch
    disp('No el bicho Segmentation Found')
    for i = 1:6
        ElBicho_Output(i).BinPct = nan;
    end
end

try
    elbicho_seg_BF = niftiread(fullfile(write_path,[vent_nii_name '_elbicho_N4.nii.gz']));
    %Write this right back out to get the correct orientation
    %nifti_info = AllinOne_Tools.nifti_metadata(elbicho_seg_BF,Params.Vent_Voxel,Params.GE_FOV);
    %niftiwrite(double(elbicho_seg_BF),fullfile(write_path,[vent_nii_name '_elbicho_BF']),nifti_info,'Compressed',true)
    elbicho_seg_BF = Tools.canonical2matlab(elbicho_seg_BF);
    ElBicho_BF_Output = AllinOne_Tools.generic_label_analysis(Vent_BF,elbicho_seg_BF);
    AllinOne_Tools.create_vent_report(write_path,Vent_BF,ElBicho_BF_Output,SNR,[Subject '_N4_ElBicho_VDP'],Subject)
catch
    disp('No el bicho Segmentation Found')
    for i = 1:6
        ElBicho_BF_Output(i).BinPct = nan;
    end
end

%After this point, there's no more going to and from nifti, so we can put
%everything in the shape we need for properly oriented images - Vent is
%already there...
%Vent_BF = Tools.canonical2matlab(Vent_BF);
%Anat_Image = Tools.canonical2matlab(Anat_Image);
Mask = Tools.canonical2matlab(Mask);


%% Start with CCHMC Method (Mean Anchored Linear Binning)
%First do not bias corrected
try
    MALB_Segmentation = AllinOne_Tools.MALB_analysis(Vent,Mask);
    MALB_Output = AllinOne_Tools.generic_label_analysis(Vent,MALB_Segmentation);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(MALB_Segmentation),fullfile(write_path,'MALB_Ventilation_Labeled'),nifti_info,'Compressed',true)
    AllinOne_Tools.create_vent_report(write_path,Vent,MALB_Output,SNR,[Subject '_60PctThreshold_VDP'],Subject)
catch
    disp('Mean Anchored Linear Binning Analysis Failed - non bias corrected image')
    for i = 1:6
        MALB_Output(i).BinPct = nan;
    end
end
%Now Bias Corrected
try
    MALB_BF_Segmentation = AllinOne_Tools.MALB_analysis(Vent_BF,Mask);
    MALB_BF_Output = AllinOne_Tools.generic_label_analysis(Vent_BF,MALB_BF_Segmentation);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(MALB_BF_Segmentation),fullfile(write_path,'MALB_Ventilation_Labeled_N4'),nifti_info,'Compressed',true)
    AllinOne_Tools.create_vent_report(write_path,Vent_BF,MALB_BF_Output,SNR,[Subject '_N4_60PctThreshold_VDP'],Subject)
catch
    disp('Mean Anchored Linear Binning Analysis Failed - bias corrected image')
    for i = 1:6
        MALB_BF_Output(i).BinPct = nan;
    end
end

%% Next, we'll do Linear Binning Method (a la Duke)
%First not bias corrected
try 
    LB_Segmentation = AllinOne_Tools.LB_analysis(Vent,Mask,0);
    LB_Output = AllinOne_Tools.generic_label_analysis(Vent,LB_Segmentation);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(LB_Segmentation),fullfile(write_path,'LB_Ventilation_Labeled'),nifti_info,'Compressed',true)
    AllinOne_Tools.create_vent_report(write_path,Vent,LB_Output,SNR,[Subject '_LinearBinning_VDP'],Subject)
catch
    disp('Linear Binning Analysis Failed - non bias corrected image')
    for i = 1:6
        LB_Output(i).BinPct = nan;
    end
end
%Then Bias Corrected
try 
    LB_BF_Segmentation = AllinOne_Tools.LB_analysis(Vent_BF,Mask,1);
    LB_BF_Output = AllinOne_Tools.generic_label_analysis(Vent_BF,LB_BF_Segmentation);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(LB_BF_Segmentation),fullfile(write_path,'LB_Ventilation_Labeled_N4'),nifti_info,'Compressed',true)
    AllinOne_Tools.create_vent_report(write_path,Vent_BF,LB_BF_Output,SNR,[Subject '_N4_LinearBinning_VDP'],Subject)
catch
    disp('Linear Binning Analysis Failed - bias corrected image')
    for i = 1:6
        LB_BF_Output(i).BinPct = nan;
    end
end

%% Kmeans clustering
try
    [~,KMeans_Segmentation] = API.VDP_calculation(Vent,Mask);
    KMeans_Output = AllinOne_Tools.generic_label_analysis(Vent,KMeans_Segmentation);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(KMeans_Segmentation),fullfile(write_path,'KMeans_Ventilation_Labeled'),nifti_info,'Compressed',true)
    AllinOne_Tools.create_vent_report(write_path,Vent,KMeans_Output,SNR,[Subject '_KMeans_VDP'],Subject)
    if length(KMeans_Output)<5
        KMeans_Output(5).BinPct = 0;
    end
catch
    disp('K Means Clustering Analysis Failed - bias corrected image');
    for i = 1:6
        KMeans_Output(i).BinPct = nan;
    end
end

try
    [~,KMeans_BF_Segmentation] = API.VDP_calculation(Vent_BF,Mask);
    KMeans_BF_Output = AllinOne_Tools.generic_label_analysis(Vent_BF,KMeans_BF_Segmentation);
    nifti_info = AllinOne_Tools.nifti_metadata(Vent_BF,Params.Vent_Voxel,Params.GE_FOV);
    niftiwrite(AllinOne_Tools.all_in_one_canonical_orientation(KMeans_BF_Segmentation),fullfile(write_path,'KMeans_Ventilation_Labeled_N4'),nifti_info,'Compressed',true)
    AllinOne_Tools.create_vent_report(write_path,Vent_BF,KMeans_BF_Output,SNR,[Subject '_N4_KMeans_VDP'],Subject)
    if length(KMeans_BF_Output)<5
        KMeans_BF_Output(5).BinPct = 0;
    end
catch
    disp('K Means Clustering Analysis Failed - bias corrected image');
    for i = 1:6
        KMeans_BF_Output(i).BinPct = nan;
    end
end
%% Save the segmentations
try
    save(fullfile(write_path,'Vent_Analysis_Segmentations.mat'),'Vent','Vent_BF','Mask','atropos_seg','cmeans_seg','elbicho_seg','cmeans_seg_BF','elbicho_seg_BF','MALB_Segmentation','MALB_BF_Segmentation','LB_Segmentation','LB_BF_Segmentation','KMeans_Segmentation','KMeans_BF_Segmentation');
catch
    save(fullfile(write_path,'Vent_Analysis_Segmentations.mat'),'Vent','Vent_BF','Mask','MALB_Segmentation','MALB_BF_Segmentation','LB_Segmentation','LB_BF_Segmentation','KMeans_Segmentation','KMeans_BF_Segmentation');
end

%% Save Outputs
try
    save(fullfile(write_path,'Vent_Outputs.mat'),'Atropos_Output','CMeans_Output','ElBicho_Output','MALB_Output','LB_Output','KMeans_Output');
catch
    save(fullfile(write_path,'Vent_Outputs.mat'),'MALB_Output','LB_Output','KMeans_Output');
end
%% Get Ventilation Heterogeneity
[H_Map_BF,H_Index_BF] = xe_vent_heterogeneity(Vent_BF,Mask,5);
[H_Map,H_Index] = xe_vent_heterogeneity(Vent,Mask,5);
save(fullfile(write_path,'Ventilation_Heterogeneity.mat'),'H_Map','H_Index','H_Map_BF','H_Index_BF');
Mask = logical(Mask);
CV = std(Vent(Mask(:)))/mean(Vent(Mask(:)));
CV_BF = std(Vent_BF(Mask(:)))/mean(Vent(Mask(:)));

%workspace_path = fullfile(write_path,'Vent_Analysis_Workspace.mat');


%% Write to Excel
matfile = 'All_in_One_Ventilation_V2.mat';
excel_summary_file = fullfile(parent_path,'AncillaryFiles','AllinOne_Ventilation_Summary_V2.xlsx');


SubjectMatch = [];
try 
    load(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary');
    SubjectMatch = find(strcmpi(AllSubjectSummary.Subject,Subject) &...
        strcmpi(AllSubjectSummary.Scan_Date,scandate));
catch
    headers = {'Subject', 'Analysis_Version','Scan_Date',...%Subject Info
                'Process_Date',...%Reconstruction Info
                'SNR',...%Acquisition Info
                'MALB_Defect','MALB_Low','MALB_Normal','MALB_Hyper','MALB_VDP',...
                'BF_MALB_Defect','BF_MALB_Low','BF_MALB_Normal','BF_MALB_Hyper','BF_MALB_VDP'...
                'LB_Bin1','LB_Bin2','LB_Bin3','LB_Bin4','LB_Bin5','LB_Bin6',...
                'BF_LB_Bin1','BF_LB_Bin2','BF_LB_Bin3','BF_LB_Bin4','BF_LB_Bin5','BF_LB_Bin6',...
                'ATROPOS_Cluster1','ATROPOS_Cluster2','ATROPOS_Cluster3','ATROPOS_Cluster4',...
                'KMeans_Cluster1','KMeans_Cluster2','KMeans_Cluster3','KMeans_Cluster4','KMeans_Cluster5',...
                'KMeans_BF_Cluster1','KMeans_BF_Cluster2','KMeans_BF_Cluster3','KMeans_BF_Cluster4','KMeans_BF_Cluster5',...
                'CMeans_Cluster1','CMeans_Cluster2','CMeans_Cluster3','CMeans_Cluster4',...
                'CMeans_BF_Cluster1','CMeans_BF_Cluster2','CMeans_BF_Cluster3','CMeans_BF_Cluster4',...
                'ElBicho_Cluster1','ElBicho_Cluster2','ElBicho_Cluster3','ElBicho_Cluster4',...
                'ElBicho_BF_Cluster1','ElBicho_BF_Cluster2','ElBicho_BF_Cluster3','ElBicho_BF_Cluster4',...
                'H_Index','H_Index_BF','CV','CV_BF'};
    AllSubjectSummary = cell2table(cell(0,size(headers,2)));
    AllSubjectSummary.Properties.VariableNames = headers;
end
NewData = {Subject,Pipeline_Version,scandate,...
            datestr(date,29),...
            SNR,...
            MALB_Output(1).BinPct,MALB_Output(2).BinPct,MALB_Output(3).BinPct,MALB_Output(4).BinPct,MALB_Output(1).BinPct+MALB_Output(2).BinPct,...
            MALB_BF_Output(1).BinPct,MALB_BF_Output(2).BinPct,MALB_BF_Output(3).BinPct,MALB_BF_Output(4).BinPct,MALB_BF_Output(1).BinPct+MALB_BF_Output(2).BinPct,...
            LB_Output(1).BinPct,LB_Output(2).BinPct,LB_Output(3).BinPct,LB_Output(4).BinPct,LB_Output(5).BinPct,LB_Output(6).BinPct,...
            LB_BF_Output(1).BinPct,LB_BF_Output(2).BinPct,LB_BF_Output(3).BinPct,LB_BF_Output(4).BinPct,LB_BF_Output(5).BinPct,LB_BF_Output(6).BinPct,...
            Atropos_Output(1).BinPct,Atropos_Output(2).BinPct,Atropos_Output(3).BinPct,Atropos_Output(4).BinPct,...
            KMeans_Output(1).BinPct,KMeans_Output(2).BinPct,KMeans_Output(3).BinPct,KMeans_Output(4).BinPct,KMeans_Output(5).BinPct,...
            KMeans_BF_Output(1).BinPct,KMeans_BF_Output(2).BinPct,KMeans_BF_Output(3).BinPct,KMeans_BF_Output(4).BinPct,KMeans_BF_Output(5).BinPct,...
            CMeans_Output(1).BinPct,CMeans_Output(2).BinPct,CMeans_Output(3).BinPct,CMeans_Output(4).BinPct,...
            CMeans_BF_Output(1).BinPct,CMeans_BF_Output(2).BinPct,CMeans_BF_Output(3).BinPct,CMeans_BF_Output(4).BinPct,...
            ElBicho_Output(1).BinPct,ElBicho_Output(2).BinPct,ElBicho_Output(3).BinPct,ElBicho_Output(4).BinPct,...
            ElBicho_BF_Output(1).BinPct,ElBicho_BF_Output(2).BinPct,ElBicho_BF_Output(3).BinPct,ElBicho_BF_Output(4).BinPct,...
            H_Index,H_Index_BF,CV,CV_BF};
if (isempty(SubjectMatch))%if no match
    AllSubjectSummary = [AllSubjectSummary;NewData];%append
else
    AllSubjectSummary(SubjectMatch,:) = NewData;%overwrite
end
AllSubjectSummary = sortrows(AllSubjectSummary);
save(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary')
writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)

%% Write to Excel - VDP only
matfile = 'VDP_6ways.mat';
excel_summary_file = fullfile(parent_path,'AncillaryFiles','VDP_6ways.xlsx');

SubjectMatch = [];
try 
    load(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary');
    SubjectMatch = find(strcmpi(AllSubjectSummary.Subject,Subject));
catch
    headers = {'Subject',...
                'MALB_VDP',...
                'LB_VDP',...
                'KMeans_VDP',...
                'ATROPOS_VDP',...
                'CMeans_VDP',...
                'ElBicho_VDP',...
                'MALB_N4_VDP',...
                'LB_N4_VDP',...
                'KMeans_N4_VDP',...
                'CMeans_N4_VDP',...
                'ElBicho_N4_VDP',...
                };
    AllSubjectSummary = cell2table(cell(0,size(headers,2)));
    AllSubjectSummary.Properties.VariableNames = headers;
end
NewData = {Subject,...
            MALB_Output(1).BinPct+MALB_Output(2).BinPct,...
            LB_Output(1).BinPct,...
            KMeans_Output(1).BinPct,...
            Atropos_Output(1).BinPct,...
            CMeans_Output(1).BinPct,...
            ElBicho_Output(1).BinPct,...
            MALB_BF_Output(1).BinPct+MALB_BF_Output(2).BinPct,...
            LB_BF_Output(1).BinPct,...
            KMeans_BF_Output(1).BinPct,...
            CMeans_BF_Output(1).BinPct,...
            ElBicho_BF_Output(1).BinPct,...
};
if (isempty(SubjectMatch))%if no match
    AllSubjectSummary = [AllSubjectSummary;NewData];%append
else
    AllSubjectSummary(SubjectMatch,:) = NewData;%overwrite
end
AllSubjectSummary = sortrows(AllSubjectSummary);
save(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary')
writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)

%% Now Reporting - Individual reports for everything + one Giant Report
% 
% idcs = strfind(write_path,filesep);%determine location of file separators
% try
%     subject_tmp = write_path((idcs(end-1)+1):(idcs(end)-1));
%     if contains(subject_tmp,'_')
%         uscore = strfind(subject_tmp,'_');
%         if length(uscore) == 1 && (length(subject_tmp)-uscore(1)) < 3
%             subject_tmp(1:uscore(1)) = [];
%         else
%             subject_tmp(1:uscore(1)) = [];
%         end
%     end
%     Subject = subject_tmp;
% catch
%     Subject = 'Unknown';
% end
% 
% try
%     Rpttitle = ['Subject_' Subject '_Ventilation_Summary_MALB'];
%     AllinOne_Tools.create_ventilation_report(write_path,Vent,MALB_Output,SNR,Rpttitle);
% catch
%     disp('No MALB Summary written')
% end
% try
%     Rpttitle = ['Subject_' Subject '_Ventilation_Summary_MALB_BiasCorrection'];
%     AllinOne_Tools.create_ventilation_report(write_path,Vent_BF,MALB_BF_Output,SNR,Rpttitle);
% catch
%     disp('No MALB-Bias Summary written')
% end
% try
%     Rpttitle = ['Subject_' Subject '_Ventilation_Summary_LB'];
%     AllinOne_Tools.create_ventilation_report(write_path,Vent,LB_Output,SNR,Rpttitle);
% catch
%     disp('No LB Summary written')
% end
% try
%     Rpttitle = ['Subject_' Subject '_Ventilation_Summary_LB_BiasCorrection'];
%     AllinOne_Tools.create_ventilation_report(write_path,Vent_BF,LB_BF_Output,SNR,Rpttitle);
% catch
%     disp('No Bias Corrected LB Summary written')
% end
% 
% try
%     Rpttitle = ['Subject_' Subject '_Ventilation_Summary_atropos_functional_segmentation'];
%     AllinOne_Tools.create_ventilation_report(write_path,Vent,Atropos_Output,SNR,Rpttitle);
% catch
%     disp('No atropos Functional Segmentation Summary written')
% 
% end
% 
try
   % AllinOne_Tools.create_full_ventilation_report(write_path,workspace_path);
    AllinOne_Tools.vdp_qc_report(write_path,Vent,Mask,Vent_BF,Anat_Image,SNR);
catch
    disp('No Full Report Written')
end

%% save variable need for the reduced excel sheet that has the more important values in it.

save(fullfile(write_path,'Reduced_Excel_Variable'),'ElBicho_BF_Output','-append');
