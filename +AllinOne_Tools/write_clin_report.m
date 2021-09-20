function write_clin_report(write_path,scanDateStr,HealthyData,VentBins,SumVentFig,RBCBins,SumRBCFig,BarBins,SumRBCBarFig,RBC2BarBins)

%Get subject from path
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

idcs = strfind(write_path,filesep);%determine location of file separators
path = write_path(1:idcs(end)-1);
if ~exist(fullfile(path,'Analysis_Reports_allinone'))
    mkdir(fullfile(path,'Analysis_Reports_allinone'));
end

num = str2num(write_path(end)); %The number of the gas exchange scan should be the last character in the write path

Seq_Name = 'All_in_One_Gas_Exchange_';
%Start "Clinical Report"
Rpttitle = [Seq_Name num2str(num) '_Report_Subject_' Subject];

import mlreportgen.report.*
import mlreportgen.dom.*

%Height of table rows
H = '1.85in';
d = Document(fullfile(path,'Analysis_Reports_allinone',Rpttitle),'pdf');
open(d);
try
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
    saveas(SumVentFig,fullfile(path,'Analysis_Reports_allinone','SumVentFig.png'));
    fig1Img = Image(fullfile(path,'Analysis_Reports_allinone','SumVentFig.png'));
    %fig1.Width = 'none';
    fig1Img.Height = H;
    fig1Img.Width = '6in';
    %Histogram Figure
    saveas(VentHistFig,fullfile(path,'Analysis_Reports_allinone','VentHistFig.png'));
    fig2Img = Image(fullfile(path,'Analysis_Reports_allinone','VentHistFig.png'));
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
    saveas(SumRBCFig,fullfile(path,'Analysis_Reports_allinone','SumRBCFig.png'));
    fig1Img = Image(fullfile(path,'Analysis_Reports_allinone','SumRBCFig.png'));
    fig1Img.Height = H;
    fig1Img.Width = '6in';
    %Histogram Figure
    saveas(RBCHistFig,fullfile(path,'Analysis_Reports_allinone','RBCHistFig.png'));
    fig2Img = Image(fullfile(path,'Analysis_Reports_allinone','RBCHistFig.png'));
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
    %Barrier
    mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
    dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
        OuterMargin('0pt', '0pt', '0pt', '0pt')};
    dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};

    dataHeader = {[],'Defect', 'Low','Elevated','High'};
    dataBody = {Subject,[num2str(BarBins.BarrierUptakeBin1Percent,'%1.1f') '%'], [num2str(BarBins.BarrierUptakeBin2Percent,'%1.1f'), '%'],[num2str(BarBins.BarrierUptakeBin5Percent+BarBins.BarrierUptakeBin6Percent,'%1.1f') '%'],[num2str(BarBins.BarrierUptakeBin7Percent+BarBins.BarrierUptakeBin8Percent,'%1.1f') '%']};
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
    p = Paragraph('Barrier Uptake');
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
    saveas(SumBarrFig,fullfile(path,'Analysis_Reports_allinone','SumBarrFig.png'));
    fig1Img = Image(fullfile(path,'Analysis_Reports_allinone','SumBarrFig.png'));
    fig1Img.Height = H;
    fig1Img.Width = '6in';
    %Histogram Figure
    saveas(BarHistFig,fullfile(path,'Analysis_Reports_allinone','BarHistFig.png'));
    fig2Img = Image(fullfile(path,'Analysis_Reports_allinone','BarHistFig.png'));
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
    %End Barrier Table Entry
    %RBC/Barrier
    mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
    dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
        OuterMargin('0pt', '0pt', '0pt', '0pt')};
    dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};

    dataHeader = {[],'High Bar', 'High RBC'};
    dataBody = {Subject,[num2str(RBC2BarBins.RBCBarrierBin1Percent+RBC2BarBins.RBCBarrierBin2Percent,'%1.1f') '%'],[num2str(RBC2BarBins.RBCBarrierBin5Percent+RBC2BarBins.RBCBarrierBin6Percent,'%1.1f') '%']};
    if HealthyDistPresent
        bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.RBCBar(1)+HealthyData.BinPercentMeans.RBCBar(2),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBCBar(1),HealthyData.BinPercentStds.RBCBar(2)]),'%1.1f') '%'],...
                         [num2str(HealthyData.BinPercentMeans.RBCBar(5) + HealthyData.BinPercentMeans.RBCBar(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBCBar(5),HealthyData.BinPercentStds.RBCBar(6)]),'%1.2f') '%']};
        dataBody = [dataBody;bodyContent2];
    end
    table = FormalTable([dataHeader',dataBody']);
    table.Header.Style = [table.Header.Style {Bold}];
    table.Footer.Style = [table.Footer.Style {Bold}];
    table.Style = dataTableStyle;
    table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
    table.Header.TableEntriesHAlign = "center";

    r = TableRow;
    r.Style = [r.Style dataTableEntriesStyle];
    p = Paragraph('RBC/Barrier');
    p.Style = [p.Style dataTableEntriesStyle];
    te = TableEntry(p);
    te.ColSpan = 3;
    append(r, te);
    append(table.Header,r);

    r = TableRow;
    r.Style = [r.Style dataTableEntriesStyle];
    p = Paragraph('Mean RBC/Barrier');
    p.Style = [p.Style dataTableEntriesStyle];
    te = TableEntry(p);
    te.ColSpan = 2;
    append(r,te);
    te = TableEntry(num2str(RBC2Bar,'%.2f'));
    append(r,te);
    append(table.Footer,r);

    Defect_Entry = entry(table.Body,2,1);
    Defect_Entry.Style = {BackgroundColor('#c51b7d'), ...
                Bold(true) };
    Low_Entry = entry(table.Body,3,1);
    Low_Entry.Style = {BackgroundColor('#ff0000'), ...
                Bold(true) }; 
    table.TableEntriesHAlign = "center";

    imgStyle = {ScaleToFit(true)};
    %Montage Figure
    saveas(SumRBCBarFig,fullfile(path,'Analysis_Reports_allinone','SumRBCBarFig.png'));
    fig1Img = Image(fullfile(path,'Analysis_Reports_allinone','SumRBCBarFig.png'));
    fig1Img.Height = H;
    fig1Img.Width = '6in';
    %Histogram Figure
    saveas(RBCBarHistFig,fullfile(path,'Analysis_Reports_allinone','RBCBarHistFig.png'));
    fig2Img = Image(fullfile(path,'Analysis_Reports_allinone','RBCBarHistFig.png'));
    fig2Img.Height = H;
    fig2Img.Width = '2in';
    row4 = TableRow;
    row4.Style = [row4.Style {Width('11in')}];
    entry1 = TableEntry;
    append(entry1,fig2Img);
    entry1.Style = [entry1.Style {Width('2in'), Height(H)}];
    append(row4,entry1);
    % Put in Summary Figure
    entry2 = TableEntry;
    append(entry2,fig1Img);
    entry2.RowSpan = 1;
    entry2.Style = [entry2.Style {Width('6in'), Height(H), HAlign('center'), VAlign('middle')}];
    append(row4,entry2);
    entry3 = TableEntry;
    append(entry3,table);
    table.Style = [table.Style {Width('2in'),HAlign('center'),FontSize('12')}];
    entry3.Style = [entry3.Style {Width('2in'), HAlign('center'),VAlign('middle')}];
    append(row4,entry3);
    append(t,row4);
    % End RBC/Barrier
    append(d,t);
    close(d);

    %Delete image files that were written exclusively for reporting.
    delete(fullfile(path,'Analysis_Reports_allinone','SumVentFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','VentHistFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','SumRBCFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','RBCHistFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','SumBarrFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','BarHistFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','SumRBCBarFig.png'));
    delete(fullfile(path,'Analysis_Reports_allinone','RBCBarHistFig.png'));
catch
    disp('No Clinical Report Written')
    close(d);
end
