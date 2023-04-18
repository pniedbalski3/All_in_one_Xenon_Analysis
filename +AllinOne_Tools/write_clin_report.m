function write_clin_report(write_path,scanDateStr,HealthyDistPresent,HealthyData,VentBins,SumVentFig,RBCBins,SumRBCFig,MemBins,SumMemFig,SumRBCMemFig,RBC2MemBins,VentHistFig,MemHistFig,RBCHistFig,RBCMemHistFig,RBC2Mem)

%Get subject from path
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

idcs = strfind(write_path,filesep);%determine location of file separators
path = write_path(1:idcs(end)-1);
if ~exist(fullfile(path,'All_in_One_Analysis','Analysis_Reports'))
    mkdir(fullfile(path,'All_in_One_Analysis','Analysis_Reports'));
end


Seq_Name = '_Gas_Exchange_Report';
%Start "Clinical Report"
Rpttitle = [Subject Seq_Name];

import mlreportgen.report.*
import mlreportgen.dom.*

%Height of table rows
H = '1.85in';
d = Document(fullfile(path,'All_in_One_Analysis','Analysis_Reports',Rpttitle),'pdf');
open(d);

currentLayout = d.CurrentPageLayout;
currentLayout.PageSize.Orientation = "landscape";
currentLayout.PageSize.Height = '8.5in';
currentLayout.PageSize.Width = '11in';

pdfheader = PDFPageHeader;
p = Paragraph(['Gas Exchange Imaging Results, Subject ' Subject ', Imaged ' scanDateStr]);
p.Style = [p.Style, {HAlign('center'), Bold(true), FontSize('12pt')}];
append(pdfheader, p);
currentLayout.PageHeaders = pdfheader;

currentLayout.PageMargins.Top = '0.05in';
currentLayout.PageMargins.Header = '0.25in';
currentLayout.PageMargins.Bottom = '0.0in';
currentLayout.PageMargins.Left = '0.5in';
currentLayout.PageMargins.Right = '0.5in';
currentLayout.PageSize.Orientation = "landscape";

%Ventilation
mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
    OuterMargin('0pt', '0pt', '0pt', '0pt')};
dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};

dataHeader = {[],'Defect', 'Low','High'};
dataBody = {Subject,[num2str(VentBins.VentBin1Percent,'%1.1f') '%'], [num2str(VentBins.VentBin2Percent,'%1.1f'), '%'],[num2str(VentBins.VentBin5Percent+VentBins.VentBin6Percent,'%1.1f') '%']};
if HealthyDistPresent
    bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.Vent(1),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.Vent(1),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.Vent(2),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.Vent(2),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.Vent(5) + HealthyData.BinPercentMeans.Vent(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.Vent(5),HealthyData.BinPercentStds.Vent(6)]),'%1.1f') '%']};
    dataBody = [dataBody;bodyContent2];
end

table = FormalTable([dataHeader',dataBody']);
table.Header.Style = [table.Header.Style {Bold}];
table.Style = dataTableStyle;
table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
table.Header.TableEntriesHAlign = "center";
r = TableRow;
r.Style = [r.Style dataTableEntriesStyle];
p = Paragraph('Ventilation');
p.Style = [p.Style dataTableEntriesStyle];
te = TableEntry(p);
te.ColSpan = 3;
append(r, te);
append(table.Header,r);

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
saveas(SumVentFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumVentFig.png'));
fig1Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumVentFig.png'));
%fig1.Width = 'none';
fig1Img.Height = H;
fig1Img.Width = '6in';
%Histogram Figure
saveas(VentHistFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','VentHistFig.png'));
fig2Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','VentHistFig.png'));
fig2Img.Height = H;
fig2Img.Width = '2in';
%Create Table having 3 columns
t = Table(3);
t.Style = [t.Style mainTableStyle];
%Put in Histogram
row1 = TableRow;
row1.Style = [row1.Style {Width('11in')}];
entry1 = TableEntry;
append(entry1,fig2Img);
entry1.Style = [entry1.Style {Width('2in'), Height(H)}];
append(row1,entry1);
% Put in Summary Figure
entry2 = TableEntry;
append(entry2,fig1Img);
entry2.RowSpan = 1;
entry2.Style = [entry2.Style {Width('6in'), Height(H), HAlign('center')}];
append(row1,entry2);
%entry2.Style = [entry2.Style {Width('3in'), HAlign('center')}];
entry3 = TableEntry;
append(entry3,table);
table.Style = [table.Style {Width('2in'),HAlign('center'),FontSize('12')}];
entry3.Style = [entry3.Style {Width('2in'), HAlign('right'), VAlign('middle')}];
%table.Style = [table.Style {Height('2.5in'),HAlign('center')}];
%entry3.Style = [entry3.Style {Height('2.5in'), HAlign('center')}];
append(row1,entry3);
append(t,row1);
%End Good Ventilation Table Entry

%Membrane
mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
    OuterMargin('0pt', '0pt', '0pt', '0pt')};
dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};

dataHeader = {[],'Defect', 'Low','Elevated','High'};
dataBody = {Subject,[num2str(MemBins.MembraneUptakeBin1Percent,'%1.1f') '%'], [num2str(MemBins.MembraneUptakeBin2Percent,'%1.1f'), '%'],[num2str(MemBins.MembraneUptakeBin5Percent+MemBins.MembraneUptakeBin6Percent,'%1.1f') '%'],[num2str(MemBins.MembraneUptakeBin7Percent+MemBins.MembraneUptakeBin8Percent,'%1.1f') '%']};
if HealthyDistPresent
    bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.Barrier(1),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.Barrier(1),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.Barrier(2),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.Barrier(2),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.Barrier(5) + HealthyData.BinPercentMeans.Barrier(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.Barrier(5),HealthyData.BinPercentStds.Barrier(6)]),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.Barrier(7) + HealthyData.BinPercentMeans.Barrier(8),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.Barrier(5),HealthyData.BinPercentStds.Barrier(8)]),'%1.1f') '%']};
    dataBody = [dataBody;bodyContent2];
end
table = FormalTable([dataHeader',dataBody']);
table.Header.Style = [table.Header.Style {Bold}];
table.Style = dataTableStyle;
table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
table.Header.TableEntriesHAlign = "center";
r = TableRow;
r.Style = [r.Style dataTableEntriesStyle];
p = Paragraph('Membrane Uptake');
p.Style = [p.Style dataTableEntriesStyle];
te = TableEntry(p);
te.ColSpan = 3;
append(r, te);
append(table.Header,r);
Defect_Entry = entry(table.Body,2,1);
Defect_Entry.Style = {BackgroundColor('#ff0000'), ...
            Bold(true) };
Low_Entry = entry(table.Body,3,1);
Low_Entry.Style = {BackgroundColor('#ffb600'), ...
            Bold(true) }; 
High2_Entry = entry(table.Body,4,1);
High2_Entry.Style = {BackgroundColor('#f3cdd5'), ...
            Bold(true) };  
High1_Entry = entry(table.Body,5,1);
High1_Entry.Style = {BackgroundColor('#c51b7d'), ...
            Bold(true) };  
table.TableEntriesHAlign = "center";

imgStyle = {ScaleToFit(true)};
%Montage Figure
saveas(SumMemFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumMemFig.png'));
fig1Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumMemFig.png'));
fig1Img.Height = H;
fig1Img.Width = '6in';
%Histogram Figure
saveas(MemHistFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','MemHistFig.png'));
fig2Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','MemHistFig.png'));
fig2Img.Height = H;
fig2Img.Width = '2in';
%Put in Histogram
row3 = TableRow;
row3.Style = [row3.Style {Width('11in')}];
entry1 = TableEntry;
append(entry1,fig2Img);
entry1.Style = [entry1.Style {Width('2in'), Height(H)}];
append(row3,entry1);
% Put in Summary Figure
entry2 = TableEntry;
append(entry2,fig1Img);
entry2.RowSpan = 1;
entry2.Style = [entry2.Style {Width('6in'), Height(H), HAlign('center')}];
append(row3,entry2);
%entry2.Style = [entry2.Style {Width('3in'), HAlign('center')}];
entry3 = TableEntry;
append(entry3,table);
table.Style = [table.Style {Width('2in'),HAlign('center'),FontSize('12')}];
entry3.Style = [entry3.Style {Width('2in'), HAlign('center'),VAlign('middle')}];
append(row3,entry3);
append(t,row3);
%End Membrane Table Entry
%RBC
mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
    OuterMargin('0pt', '0pt', '0pt', '0pt')};
dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};

dataHeader = {[],'Defect', 'Low','High'};
dataBody = {Subject,[num2str(RBCBins.RBCTransferBin1Percent,'%1.1f') '%'], [num2str(RBCBins.RBCTransferBin2Percent,'%1.1f'), '%'],[num2str(RBCBins.RBCTransferBin5Percent+RBCBins.RBCTransferBin6Percent,'%1.1f') '%']};
if HealthyDistPresent
    bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.RBC(1),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.RBC(1),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.RBC(2),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.RBC(2),'%1.1f') '%'],...
                     [num2str(HealthyData.BinPercentMeans.RBC(5) + HealthyData.BinPercentMeans.RBC(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBC(5),HealthyData.BinPercentStds.RBC(6)]),'%1.1f') '%']};
    dataBody = [dataBody;bodyContent2];
end
table = FormalTable([dataHeader',dataBody']);
table.Header.Style = [table.Header.Style {Bold}];
table.Style = dataTableStyle;
table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
table.Header.TableEntriesHAlign = "center";
r = TableRow;
r.Style = [r.Style dataTableEntriesStyle];
p = Paragraph('RBC Transfer');
p.Style = [p.Style dataTableEntriesStyle];
te = TableEntry(p);
te.ColSpan = 3;
append(r, te);
append(table.Header,r);

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
saveas(SumRBCFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumRBCFig.png'));
fig1Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumRBCFig.png'));
fig1Img.Height = H;
fig1Img.Width = '6in';
%Histogram Figure
saveas(RBCHistFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','RBCHistFig.png'));
fig2Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','RBCHistFig.png'));
fig2Img.Height = H;
fig2Img.Width = '2in';
%Put in Histogram
row2 = TableRow;
row2.Style = [row2.Style {Width('11in')}];
entry1 = TableEntry;
append(entry1,fig2Img);
entry1.Style = [entry1.Style {Width('2in'), Height(H)}];
append(row2,entry1);
% Put in Summary Figure
entry2 = TableEntry;
append(entry2,fig1Img);
entry2.RowSpan = 1;
entry2.Style = [entry2.Style {Width('6in'), Height(H), HAlign('center')}];
append(row2,entry2);
entry3 = TableEntry;
append(entry3,table);
table.Style = [table.Style {Width('2in'),HAlign('center'),FontSize('12')}];
entry3.Style = [entry3.Style {Width('2in'), HAlign('center'),VAlign('middle')}];
append(row2,entry3);
append(t,row2);
%End RBC Table Entry
%RBC/Membrane
% mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
% dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
%     OuterMargin('0pt', '0pt', '0pt', '0pt')};
% dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};
% 
% dataHeader = {[],'High Mem', 'High RBC'};
% dataBody = {Subject,[num2str(RBC2MemBins.RBCMembraneBin1Percent+RBC2MemBins.RBCMembraneBin2Percent,'%1.1f') '%'],[num2str(RBC2MemBins.RBCMembraneBin5Percent+RBC2MemBins.RBCMembraneBin6Percent,'%1.1f') '%']};
% if HealthyDistPresent
%     bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.RBCBar(1)+HealthyData.BinPercentMeans.RBCBar(2),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBCBar(1),HealthyData.BinPercentStds.RBCBar(2)]),'%1.1f') '%'],...
%                      [num2str(HealthyData.BinPercentMeans.RBCBar(5) + HealthyData.BinPercentMeans.RBCBar(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBCBar(5),HealthyData.BinPercentStds.RBCBar(6)]),'%1.2f') '%']};
%     dataBody = [dataBody;bodyContent2];
% end
% table = FormalTable([dataHeader',dataBody']);
% table.Header.Style = [table.Header.Style {Bold}];
% table.Footer.Style = [table.Footer.Style {Bold}];
% table.Style = dataTableStyle;
% table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
% table.Header.TableEntriesHAlign = "center";
% 
% r = TableRow;
% r.Style = [r.Style dataTableEntriesStyle];
% p = Paragraph('RBC/Membrane');
% p.Style = [p.Style dataTableEntriesStyle];
% te = TableEntry(p);
% te.ColSpan = 3;
% append(r, te);
% append(table.Header,r);
% 
% r = TableRow;
% r.Style = [r.Style dataTableEntriesStyle];
% p = Paragraph('Mean RBC/Membrane');
% p.Style = [p.Style dataTableEntriesStyle];
% te = TableEntry(p);
% te.ColSpan = 2;
% append(r,te);
% te = TableEntry(num2str(RBC2Mem,'%.2f'));
% append(r,te);
% append(table.Footer,r);
% 
% Defect_Entry = entry(table.Body,2,1);
% Defect_Entry.Style = {BackgroundColor('#c51b7d'), ...
%             Bold(true) };
% Low_Entry = entry(table.Body,3,1);
% Low_Entry.Style = {BackgroundColor('#ff0000'), ...
%             Bold(true) }; 
% table.TableEntriesHAlign = "center";
% 
% imgStyle = {ScaleToFit(true)};
% %Montage Figure
% saveas(SumRBCMemFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumRBCMemFig.png'));
% fig1Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumRBCMemFig.png'));
% fig1Img.Height = H;
% fig1Img.Width = '6in';
% %Histogram Figure
% saveas(RBCMemHistFig,fullfile(path,'All_in_One_Analysis','Analysis_Reports','RBCMemHistFig.png'));
% fig2Img = Image(fullfile(path,'All_in_One_Analysis','Analysis_Reports','RBCMemHistFig.png'));
% fig2Img.Height = H;
% fig2Img.Width = '2in';
% row4 = TableRow;
% row4.Style = [row4.Style {Width('11in')}];
% entry1 = TableEntry;
% append(entry1,fig2Img);
% entry1.Style = [entry1.Style {Width('2in'), Height(H)}];
% append(row4,entry1);
% % Put in Summary Figure
% entry2 = TableEntry;
% append(entry2,fig1Img);
% entry2.RowSpan = 1;
% entry2.Style = [entry2.Style {Width('6in'), Height(H), HAlign('center'), VAlign('middle')}];
% append(row4,entry2);
% entry3 = TableEntry;
% append(entry3,table);
% table.Style = [table.Style {Width('2in'),HAlign('center'),FontSize('12')}];
% entry3.Style = [entry3.Style {Width('2in'), HAlign('center'),VAlign('middle')}];
% append(row4,entry3);
% append(t,row4);
% End RBC/Membrane
append(d,t);
close(d);

%Delete image files that were written exclusively for reporting.
delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumVentFig.png'));
delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','VentHistFig.png'));
delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumRBCFig.png'));
delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','RBCHistFig.png'));
delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumMemFig.png'));
delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','MemHistFig.png'));
%delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','SumRBCMemFig.png'));
%delete(fullfile(path,'All_in_One_Analysis','Analysis_Reports','RBCMemHistFig.png'));

