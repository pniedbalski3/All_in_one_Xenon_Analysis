function create_vent_report(mypath,Vent,Output_Struct,SNR,Title,Subject)
% Import report API classes (optional) for creating report at end
import mlreportgen.report.*
import mlreportgen.dom.*

parent_path = which('Report.create_ventilation_report');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

% sub_ind = strfind(mypath,'Xe-');
% Subject = mypath(sub_ind:end);
%  Rpttitle = ['Subject_' Subject '_Ventilation_Summary_MALB'];
Rpttitle = Title;
if ~exist(fullfile(mypath,'Analysis_Reports'))
    mkdir(fullfile(mypath,'Analysis_Reports'));
end

rpt = Report(fullfile(mypath,'Analysis_Reports',Rpttitle),'pdf');
rpt.Layout.Landscape = true;
%% Write out 5 slice figure
chap1 = Chapter(['Ventilation Imaging Results, Subject ' Subject]);
chap1.Numbered = false;
chap1.Layout.Landscape = true;

% fig = Figure(Output_Struct.ClinFig);
% fig.Snapshot.Caption = ['5 select slices of Ventilation Images with Masked Defects. SNR = ' num2str(SNR)];
% add(newsect,fig);

%% Need to do make table specific to analysis type

mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
    OuterMargin('0pt', '0pt', '0pt', '0pt')};
dataTableEntriesStyle = {OuterMargin('4pt', '4pt', '4pt', '4pt'), VAlign('middle'),HAlign('center')};

dataHeader = {[]};
dataBody = {[]};
for i = length(Output_Struct)
    dataHeader = [dataHeader ['Bin ' num2str(i)]];
    dataBody = [dataBody [num2str(Output_Struct(i).BinPct,'%1.1f') '%']];
end
%     if HealthyDistPresent
%         bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.Vent(1),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.Vent(1),'%1.1f') '%'],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(2),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.Vent(2),'%1.1f') '%'],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(5) + HealthyData.BinPercentMeans.Vent(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.Vent(5),HealthyData.BinPercentStds.Vent(6)]),'%1.1f') '%']};
%         dataBody = [dataBody;bodyContent2];
%     end
table = FormalTable([dataHeader',dataBody']);
table.Header.Style = [table.Header.Style {Bold}];
table.Style = dataTableStyle;
table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
table.Header.TableEntriesHAlign = "center";
    Defect_Entry = entry(table.Body,2,1);
Defect_Entry.Style = {BackgroundColor('#ff0000'), ...
            Bold(true) };
Low_Entry = entry(table.Body,3,1);
Low_Entry.Style = {BackgroundColor('#ffb600'), ...
            Bold(true) }; 
High2_Entry = entry(table.Body,4,1);
High2_Entry.Style = {BackgroundColor('#0000ff'), ...
            Bold(true) };  
table.TableEntriesHAlign = "center";
imgStyle = {ScaleToFit(true)};
%Montage Figure
fig1 = Figure(Output_Struct(1).AllFig);
fig1.Scaling = 'none';
%fig1.Snapshot.Height = '4in';
fig1Img = Image(getSnapshotImage(fig1, rpt));
fig1Img.Style = imgStyle;
%Histogram Figure
fig2 = Figure(Output_Struct(1).HistFig);
fig2Img = Image(getSnapshotImage(fig2, rpt));
fig2Img.Style = imgStyle;
t = Table(2);
t.Style = [t.Style mainTableStyle];
%Put in Summary Figures
row1 = TableRow;
% row1.Style = [row1.Style {Width('9in')}];
entry1 = TableEntry;
append(entry1,fig1Img);
entry1.RowSpan = 2;
entry1.Style = [entry1.Style {Width('6in'), Height('5.75in')}];
append(row1,entry1);
% Put in Histogram
entry2 = TableEntry;
append(entry2,fig2Img);
entry2.RowSpan = 1;
entry2.Style = [entry2.Style {Width('3in'), Height('3in'), HAlign('center')}];
%entry2.Style = [entry2.Style {Width('3in'), HAlign('center')}];
append(row1,entry2);
entry2.ColSpan = 1;
append(t,row1);
%Put in Table with Data
row2 = TableRow;
entry3 = TableEntry;
append(entry3,table);
table.Style = [table.Style {Width('3in'),HAlign('center')}];
entry3.Style = [entry3.Style {Width('3in'), HAlign('center')}];
append(row2,entry3);
append(t,row2);
add(chap1,t);
%End Good Ventilation Page

%% Finally, need to display histogram
% fig = Figure(Output_Struct.HistFig);
% fig.Snapshot.Caption = 'Histogram of Ventilation Values within Masked Volume';
% add(newsect,fig);

add(rpt,chap1);
% Close the report (required)
close(rpt);

