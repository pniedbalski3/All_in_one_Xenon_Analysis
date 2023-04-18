function write_full_report(write_path,scanDateStr,HealthyDistPresent,HealthyData,VentBins,RBCBins,MemBins,RBC2MemBins,VentBinMontage,VentHistFig,RBCBinMontage,RBCHistFig,MembraneBinMontage,MemHistFig,RBCMemBinMontage,RBCMemHistFig,k0fig,DissolvedNMR,Mask_Fig,VentMontage,GasMontage,DissolvedMontage,RBCMontage,MembraneMontage)

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

%% Write out Reports - Technical
%Technical Report looks great.
% Begin "Technical Report"
idcs = strfind(write_path,filesep);%determine location of file separators
path = write_path(1:idcs(end)-1);
if ~exist(fullfile(path,'All_in_One_Analysis','Analysis_Reports'))
    mkdir(fullfile(path,'All_in_One_Analysis','Analysis_Reports'));
end

Rpttitle = [Subject '_Technical_GX_Report'];
import mlreportgen.report.*
import mlreportgen.dom.*

rpt = Report(fullfile(path,'All_in_One_Analysis','Analysis_Reports',Rpttitle),'pdf');
rpt.Layout.Landscape = true;

try

    chap1 = Chapter(['Gas Exchange Imaging Results, Subject ' Subject ', Imaged ' scanDateStr]);
    chap1.Numbered = false;

    %Ventilation
    h = Heading(1,'Ventilation Imaging Results');
    h.Style = [h.Style {HAlign('center')}];
    add(chap1,h);
    mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
    dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
        OuterMargin('0pt', '0pt', '0pt', '0pt')};
    dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};
    histStyle = {InnerMargin('2pt', '2pt', '2pt', '2pt'), ...
        HAlign('center'), VAlign('bottom'), Width('6in'), Height('6in')};

    dataHeader = {[],'Defect', 'Low', 'Healthy', 'Healthy','High','High'};
    dataBody = {Subject,[num2str(VentBins.VentBin1Percent,'%1.2f') '%'], [num2str(VentBins.VentBin2Percent,'%1.2f'), '%'], [num2str(VentBins.VentBin3Percent,'%1.2f') '%'], [num2str(VentBins.VentBin4Percent,'%1.2f') '%'],[num2str(VentBins.VentBin5Percent,'%1.2f') '%'],[num2str(VentBins.VentBin6Percent,'%1.2f') '%']};

    if HealthyDistPresent
        bodyContent2 = {'Healthy Ref',[num2str(HealthyData.BinPercentMeans.Vent(1),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(1),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Vent(2),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(2),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Vent(3),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(3),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Vent(4),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(4),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Vent(5),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(5),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Vent(6),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(6),'%1.2f')]};
        dataBody = [dataBody;bodyContent2];
    end
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
    Normal1_Entry = entry(table.Body,4,1);
    Normal1_Entry.Style = {BackgroundColor('#66b366'), ...
                Bold(true) };
    Normal2_Entry = entry(table.Body,5,1);
    Normal2_Entry.Style = {BackgroundColor('#00ff00'), ...
                Bold(true) };
    High1_Entry = entry(table.Body,6,1);
    High1_Entry.Style = {BackgroundColor('#0091b5'), ...
                Bold(true) };     
    High2_Entry = entry(table.Body,7,1);
    High2_Entry.Style = {BackgroundColor('#0000ff'), ...
                Bold(true) };  
    table.TableEntriesHAlign = "center";
    imgStyle = {ScaleToFit(true)};
    %Montage Figure
    fig1 = Figure(VentBinMontage);
    fig1.Scaling = 'none';
    fig1.Snapshot.Height = '4in';
    fig1Img = Image(getSnapshotImage(fig1, rpt));
    fig1Img.Style = imgStyle;
    %Histogram Figure
    fig2 = Figure(VentHistFig);
    fig2Img = Image(getSnapshotImage(fig2, rpt));
    fig2Img.Style = imgStyle;
    t = Table(2);
    t.Style = [t.Style mainTableStyle];
    %Put in Summary Figures
    row1 = TableRow;
    row1.Style = [row1.Style {Width('9in')}];
    entry1 = TableEntry;
    append(entry1,fig1Img);
    entry1.RowSpan = 2;
    entry1.Style = [entry1.Style {Width('6in'), Height('5.25in')}];
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

    %Temp for debugging
    % add(rpt,chap1);
    % close(rpt);
%Membrane Imaging
    h = Heading(1,'Membrane Imaging Results');
    h.Style = [h.Style {HAlign('center')}];
    add(chap1,h);
    mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
    dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
        OuterMargin('0pt', '0pt', '0pt', '0pt')};
    dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};
    histStyle = {InnerMargin('2pt', '2pt', '2pt', '2pt'), ...
        HAlign('center'), VAlign('bottom'), Width('6in'), Height('6in')};

    headerContent = {[],'Defect', 'Low', 'Healthy', 'Healthy','Elevated','Elevated','High','High'};
    bodyContent = {Subject,[num2str(MemBins.MembraneUptakeBin1Percent,'%1.2f') '%'], [num2str(MemBins.MembraneUptakeBin2Percent,'%1.2f'), '%'], [num2str(MemBins.MembraneUptakeBin3Percent,'%1.2f') '%'], [num2str(MemBins.MembraneUptakeBin4Percent,'%1.2f') '%'],[num2str(MemBins.MembraneUptakeBin5Percent,'%1.2f') '%'],[num2str(MemBins.MembraneUptakeBin6Percent,'%1.2f') '%'],[num2str(MemBins.MembraneUptakeBin7Percent,'%1.2f') '%'],[num2str(MemBins.MembraneUptakeBin8Percent,'%1.2f') '%']};
    if HealthyDistPresent
        bodyContent2 = {'Healthy Ref',[num2str(HealthyData.BinPercentMeans.Barrier(1),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(1),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(2),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(2),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(3),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(3),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(4),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(4),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(5),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(5),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(6),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(6),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(7),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(7),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.Barrier(8),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Barrier(8),'%1.2f')]};
        bodyContent = [bodyContent;bodyContent2];
    end
    table = FormalTable([headerContent',bodyContent']);
    table.Header.Style = [table.Header.Style {Bold}];
    table.Style = dataTableStyle;
    table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
    table.Header.TableEntriesHAlign = "center";
    %table.Header.Style = headerStyle;
    Defect_Entry = entry(table.Body,2,1);
    Defect_Entry.Style = {BackgroundColor('#ff0000'), ...
                Bold(true) };
    Low_Entry = entry(table.Body,3,1);
    Low_Entry.Style = {BackgroundColor('#ffb600'), ...
                Bold(true) };
    Normal1_Entry = entry(table.Body,4,1);
    Normal1_Entry.Style = {BackgroundColor('#66b366'), ...
                Bold(true) };
    Normal2_Entry = entry(table.Body,5,1);
    Normal2_Entry.Style = {BackgroundColor('#00ff00'), ...
                Bold(true) };
    High1_Entry = entry(table.Body,6,1);
    High1_Entry.Style = {BackgroundColor('#b8e291'), ...
                Bold(true) };     
    High2_Entry = entry(table.Body,7,1);
    High2_Entry.Style = {BackgroundColor('#f3cdd5'), ...
                Bold(true) };  
    High3_Entry = entry(table.Body,8,1);
    High3_Entry.Style = {BackgroundColor('#e181a2'), ...
                Bold(true) };     
    High4_Entry = entry(table.Body,9,1);
    High4_Entry.Style = {BackgroundColor('#c51b7d'), ...
                Bold(true) }; 
    table.TableEntriesHAlign = "center";
    imgStyle = {ScaleToFit(true)};
    %Montage Figure
    fig1 = Figure(MembraneBinMontage);
    fig1.Scaling = 'none';
    fig1.Snapshot.Height = '4in';
    fig1Img = Image(getSnapshotImage(fig1, rpt));
    fig1Img.Style = imgStyle;
    %Histogram Figure
    fig2 = Figure(MemHistFig);
    fig2Img = Image(getSnapshotImage(fig2, rpt));
    fig2Img.Style = imgStyle;
    t = Table(2);
    t.Style = [t.Style mainTableStyle];
    %Put in Summary Figures
    row1 = TableRow;
    row1.Style = [row1.Style {Width('9in')}];
    entry1 = TableEntry;
    append(entry1,fig1Img);
    entry1.RowSpan = 2;
    entry1.Style = [entry1.Style {Width('6in'), Height('5.25in')}];
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
    %End Good Membrane Image
    %RBC
    h = Heading(1,'RBC Imaging Results');
    h.Style = [h.Style {HAlign('center')}];
    add(chap1,h);
    mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
    dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
        OuterMargin('0pt', '0pt', '0pt', '0pt')};
    dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};
    histStyle = {InnerMargin('2pt', '2pt', '2pt', '2pt'), ...
        HAlign('center'), VAlign('bottom'), Width('6in'), Height('6in')};

    dataHeader = {[],'Defect', 'Low', 'Healthy', 'Healthy','High','High'};
    dataBody = {Subject,[num2str(RBCBins.RBCTransferBin1Percent,'%1.2f') '%'], [num2str(RBCBins.RBCTransferBin2Percent,'%1.2f'), '%'], [num2str(RBCBins.RBCTransferBin3Percent,'%1.2f') '%'], [num2str(RBCBins.RBCTransferBin4Percent,'%1.2f') '%'],[num2str(RBCBins.RBCTransferBin5Percent,'%1.2f') '%'],[num2str(RBCBins.RBCTransferBin6Percent,'%1.2f') '%']};

    if HealthyDistPresent
        bodyContent2 = {'Healthy Ref',[num2str(HealthyData.BinPercentMeans.RBC(1),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBC(1),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBC(2),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBC(2),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBC(3),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBC(3),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBC(4),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBC(4),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBC(5),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBC(5),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBC(6),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBC(6),'%1.2f')]};
        dataBody = [dataBody;bodyContent2];
    end
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
    Normal1_Entry = entry(table.Body,4,1);
    Normal1_Entry.Style = {BackgroundColor('#66b366'), ...
                Bold(true) };
    Normal2_Entry = entry(table.Body,5,1);
    Normal2_Entry.Style = {BackgroundColor('#00ff00'), ...
                Bold(true) };
    High1_Entry = entry(table.Body,6,1);
    High1_Entry.Style = {BackgroundColor('#0091b5'), ...
                Bold(true) };     
    High2_Entry = entry(table.Body,7,1);
    High2_Entry.Style = {BackgroundColor('#0000ff'), ...
                Bold(true) };  
    table.TableEntriesHAlign = "center";
    imgStyle = {ScaleToFit(true)};
    %Montage Figure
    fig1 = Figure(RBCBinMontage);
    fig1.Scaling = 'none';
    fig1.Snapshot.Height = '4in';
    fig1Img = Image(getSnapshotImage(fig1, rpt));
    fig1Img.Style = imgStyle;
    %Histogram Figure
    fig2 = Figure(RBCHistFig);
    fig2Img = Image(getSnapshotImage(fig2, rpt));
    fig2Img.Style = imgStyle;
    t = Table(2);
    t.Style = [t.Style mainTableStyle];
    %Put in Summary Figures
    row1 = TableRow;
    row1.Style = [row1.Style {Width('9in')}];
    entry1 = TableEntry;
    append(entry1,fig1Img);
    entry1.RowSpan = 2;
    entry1.Style = [entry1.Style {Width('6in'), Height('5.25in')}];
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
    %End Good RBC Page

    

    %RBC/Membrane
    h = Heading(1,'RBC/Membrane Imaging Results');
    h.Style = [h.Style {HAlign('center')}];
    add(chap1,h);
    mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
    dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
        OuterMargin('0pt', '0pt', '0pt', '0pt')};
    dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};
    histStyle = {InnerMargin('2pt', '2pt', '2pt', '2pt'), ...
        HAlign('center'), VAlign('bottom'), Width('6in'), Height('6in')};

    dataHeader = {[],'High Mem', 'High Mem', 'Healthy', 'Healthy','High RBC','High RBC'};
    dataBody = {Subject,[num2str(RBC2MemBins.RBCMembraneBin1Percent,'%1.2f') '%'], [num2str(RBC2MemBins.RBCMembraneBin2Percent,'%1.2f'), '%'], [num2str(RBC2MemBins.RBCMembraneBin3Percent,'%1.2f') '%'], [num2str(RBC2MemBins.RBCMembraneBin4Percent,'%1.2f') '%'],[num2str(RBC2MemBins.RBCMembraneBin5Percent,'%1.2f') '%'],[num2str(RBC2MemBins.RBCMembraneBin6Percent,'%1.2f') '%']};

    if HealthyDistPresent
        bodyContent2 = {'Healthy Ref',[num2str(HealthyData.BinPercentMeans.RBCBar(1),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBCBar(1),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBCBar(2),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBCBar(2),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBCBar(3),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBCBar(3),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBCBar(4),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBCBar(4),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBCBar(5),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBCBar(5),'%1.2f')],...
                         [num2str(HealthyData.BinPercentMeans.RBCBar(6),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.RBCBar(6),'%1.2f')]};
        dataBody = [dataBody;bodyContent2];
    end
    table = FormalTable([dataHeader',dataBody']);
    table.Header.Style = [table.Header.Style {Bold}];
    table.Style = dataTableStyle;
    table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
    table.Header.TableEntriesHAlign = "center";
    Defect_Entry = entry(table.Body,2,1);
    Defect_Entry.Style = {BackgroundColor('#c51b7d'), ...
                Bold(true) };
    Low_Entry = entry(table.Body,3,1);
    Low_Entry.Style = {BackgroundColor('#e181a2'), ...
                Bold(true) };
    Normal1_Entry = entry(table.Body,4,1);
    Normal1_Entry.Style = {BackgroundColor('#66b366'), ...
                Bold(true) };
    Normal2_Entry = entry(table.Body,5,1);
    Normal2_Entry.Style = {BackgroundColor('#00ff00'), ...
                Bold(true) };
    High1_Entry = entry(table.Body,6,1);
    High1_Entry.Style = {BackgroundColor('#ffb600'), ...
                Bold(true) };     
    High2_Entry = entry(table.Body,7,1);
    High2_Entry.Style = {BackgroundColor('#ff0000'), ...
                Bold(true) };  
    table.TableEntriesHAlign = "center";
    imgStyle = {ScaleToFit(true)};
    %Montage Figure
    fig1 = Figure(RBCMemBinMontage);
    fig1.Scaling = 'none';
    fig1.Snapshot.Height = '4in';
    fig1Img = Image(getSnapshotImage(fig1, rpt));
    fig1Img.Style = imgStyle;
    %Histogram Figure
    fig2 = Figure(RBCMemHistFig);
    fig2Img = Image(getSnapshotImage(fig2, rpt));
    fig2Img.Style = imgStyle;
    t = Table(2);
    t.Style = [t.Style mainTableStyle];
    %Put in Summary Figures
    row1 = TableRow;
    row1.Style = [row1.Style {Width('9in')}];
    entry1 = TableEntry;
    append(entry1,fig1Img);
    entry1.RowSpan = 2;
    entry1.Style = [entry1.Style {Width('6in'), Height('5.25in')}];
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
    %End Good RBC/Membrane Page

    % Now a Quality Control Section
    newsect = Section('Quality Control');
    %First Spectral information - k0 and spectral fitting
    h = Heading(1,'Spectrum Analysis and k0 Decay');
    h.Style = [h.Style {HAlign('center')}];
    add(newsect,h);
    fig1 = Figure(DissolvedNMR);
    fig1Img = Image(getSnapshotImage(fig1,rpt));
    fig1Img.Style = imgStyle;
    fig2 = Figure(k0fig);
    fig2Img = Image(getSnapshotImage(fig2,rpt));
    fig2Img.Style = imgStyle;
    lo_table = Table({fig1Img, ' ', fig2Img});
    lo_table.entry(1,1).Style = {Width('4.5in'), Height('6in'),VAlign('middle')};
    lo_table.entry(1,2).Style = {Width('.2in'), Height('6in'),VAlign('middle')};
    lo_table.entry(1,3).Style = {Width('4.5in'), Height('6in'),VAlign('middle')};
    add(newsect,lo_table);

    %Now we just want Anatomic with Mask and Ventilation with Mask outlines
    h = Heading(1,'Masking Quality Control');
    h.Style = [h.Style {HAlign('center')}];
    add(newsect,h);
    fig1 = Figure(Mask_Fig);
    fig1Img = Image(getSnapshotImage(fig1,rpt));
    fig1Img.Style = imgStyle;
    fig2 = Figure(VentMontage);
    fig2Img = Image(getSnapshotImage(fig2,rpt));
    fig2Img.Style = imgStyle;
    lo_table = Table({fig1Img; ' '; fig2Img});
    lo_table.entry(1,1).Style = {Width('8in'), Height('2.5in')};
    lo_table.entry(2,1).Style = {Width('8in'), Height('0.2in')};
    lo_table.entry(3,1).Style = {Width('8in'), Height('2.5in')};
    add(newsect,lo_table);

    %Gas and Dissolved Raw Images
    h = Heading(1,'Raw Images - Gas and Dissolved');
    h.Style = [h.Style {HAlign('center')}];
    add(newsect,h);
    fig1 = Figure(GasMontage);
    fig1Img = Image(getSnapshotImage(fig1,rpt));
    fig1Img.Style = imgStyle;
    fig2 = Figure(DissolvedMontage);
    fig2Img = Image(getSnapshotImage(fig2,rpt));
    fig2Img.Style = imgStyle;
    lo_table = Table({fig1Img; ' '; fig2Img});
    lo_table.entry(1,1).Style = {Width('8in'), Height('2.5in')};
    lo_table.entry(2,1).Style = {Width('8in'), Height('0.2in')};
    lo_table.entry(3,1).Style = {Width('8in'), Height('2.5in')};
    add(newsect,lo_table);

    %RBC and Membrane Raw Images
    h = Heading(1,'Raw Images - RBC and Membrane');
    h.Style = [h.Style {HAlign('center')}];
    add(newsect,h);
    fig1 = Figure(RBCMontage);
    fig1Img = Image(getSnapshotImage(fig1,rpt));
    fig1Img.Style = imgStyle;
    fig2 = Figure(MembraneMontage);
    fig2Img = Image(getSnapshotImage(fig2,rpt));
    fig2Img.Style = imgStyle;
    lo_table = Table({fig1Img; ' '; fig2Img});
    lo_table.entry(1,1).Style = {Width('8in'), Height('2.5in')};
    lo_table.entry(2,1).Style = {Width('8in'), Height('0.2in')};
    lo_table.entry(3,1).Style = {Width('8in'), Height('2.5in')};
    add(newsect,lo_table);

    %Finish up Report
    add(chap1,newsect);
    add(rpt,chap1);
    close(rpt);
catch
    disp('No Technical Report Written')
    close(rpt);
end