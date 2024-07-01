
function Create_Reduced_Excel(write_path,scandate)
% Creates an additional excel file that contains the important values.
% Makes it so you don;t have to search for these values in the other two
% excel sheets.

%load needed variable
load(fullfile(write_path,'Reduced_Excel_Variable'))

% find the parent path
parent_path = which('Create_Reduced_Excel');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file


matfile = 'AllinOne_Important_Values.mat';
excel_summary_file = fullfile(parent_path,'AncillaryFiles','AllinOne_Important_Values_Summary.xlsx');

idcs = strfind(write_path,filesep);%determine location of file separators
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

SubjectMatch = [];

try 
    load(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary');
    SubjectMatch = find(strcmpi(AllSubjectSummary.Subject,Subject) &...
        strcmpi(AllSubjectSummary.Scan_Date,scandate));
catch
    headers = {'Subject','Scan_Date',...%Subject Info
                'Process_Date','Lung_Volume','RBC_Barrier_Ratio',...
                'Barrier_Uptake_Mean','Barrier_Uptake_Std_Dev',...%Quantitative Distributions - Membrane
                'RBC_Transfer_Mean','RBC_Transfer_Std_Dev',...%Quantitative Distributions 
                'Barrier_Uptake_Bin1_Percent','Barrier_Uptake_Bin2_Percent','Barrier_Uptake_Bin6_Percent','Barrier_Uptake_Bin7_Percent','Barrier_Uptake_Bin8_Percent',...%Binning Results - Membrane
                'RBC_Transfer_Bin1_Percent','RBC_Transfer_Bin2_Percent','RBC_Transfer_Bin5_Percent','RBC_Transfer_Bin6_Percent',...%Binning Results - RBC
                'ElBicho_VDP'};
    AllSubjectSummary = cell2table(cell(0,size(headers,2)));
    AllSubjectSummary.Properties.VariableNames = headers;
end

NewData = {Subject,scandate,...
            datestr(date,29),Lung_Volume,RBC2Mem,...
            MemBins.MembraneUptakeMean, MemBins.MembraneUptakeStd,...%Quantitative Distributions - Membrane
            RBCBins.RBCTransferMean, RBCBins.RBCTransferStd,...%Quantitative Distributions - RBC
            MemBins.MembraneUptakeBin1Percent, MemBins.MembraneUptakeBin2Percent, MemBins.MembraneUptakeBin6Percent, MemBins.MembraneUptakeBin7Percent, MemBins.MembraneUptakeBin8Percent,...%Binning Results - Membrane
            RBCBins.RBCTransferBin1Percent, RBCBins.RBCTransferBin2Percent, RBCBins.RBCTransferBin5Percent, RBCBins.RBCTransferBin6Percent,...%Binning Results - RBC
            ElBicho_BF_Output(1).BinPct};
if (isempty(SubjectMatch))%if no match
    AllSubjectSummary = [AllSubjectSummary;NewData];%append
else
    AllSubjectSummary(SubjectMatch,:) = NewData;%overwrite
end
AllSubjectSummary = sortrows(AllSubjectSummary);

save(fullfile(parent_path,'AncillaryFiles',matfile),'AllSubjectSummary')
writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)
