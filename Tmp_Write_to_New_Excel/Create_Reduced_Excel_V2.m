%Updated 12/04/2024  
function Create_Reduced_Excel(write_path,scandate)
% Creates an additional excel file that contains the important values.
% Makes it so you don;t have to search for these values in the other two
% excel sheets.

%load needed variable
load(fullfile(write_path,'Reduced_Excel_Variable'))

% GET INDICES OF THE FILE SEPARATORS 
idcs = strfind(write_path,filesep); %determine location of file separators

%EXTRACT THE BASE DIRECTORY UP TO THE SECOND DIRECTORY LEVEL(IRB folder)
base_path = write_path(1:idcs(2)-1); % extracting upto the second file separator

%SPECIFY THE EXCEL FILE PATH IN THE 'Summary_excels' FOLDER
excel_summary_file = fullfile(base_path,'Summary_excels', 'Xe_Summary.xlsx');

%CHECK IF THE 'Summary_excel_files' directory EXISTS; IF NOT, CREATE IT
if ~exist(fullfile(base_path,'Summary_excels'), 'dir')
    mkdir(fullfile(base_path,'Summary_excels')); 
end

%Find suject name from the write_path
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
    load(fullfile(base_path,'Summary_excels',matfile),'AllSubjectSummary');
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

save(fullfile(base_path,'Summary_excels',matfile),'AllSubjectSummary')
writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)
