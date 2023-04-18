function vdp_qc_report(write_path,Vent,Mask,Vent_BF,Anat_Image,SNR)

% Import report API classes (optional) for creating report at end
import mlreportgen.report.*
import mlreportgen.dom.*


%% Start by looking at anatomic, mask, and ventilation images
[centerslice,firstslice,lastslice] = Tools.getimcenter(Mask);

try
    Anat_tiled = Tools.tile_image(Anat_Image(:,:,(firstslice-2):(lastslice+2)),3);
    Mask_tiled = Tools.tile_image(Mask(:,:,(firstslice-2):(lastslice+2)),3);
    Vent_tiled = Tools.tile_image(Vent(:,:,(firstslice-2):(lastslice+2)),3);
    Vent_BF_tiled = Tools.tile_image(Vent_BF(:,:,(firstslice-2):(lastslice+2)),3);
catch
    Anat_tiled = Tools.tile_image(Anat_Image,3);
    Mask_tiled = Tools.tile_image(Mask,3);
    Vent_tiled = Tools.tile_image(Vent,3);
    Vent_BF_tiled = Tools.tile_image(Vent_BF,3);
end
ProtonMax = max(Anat_Image(:));
Vent_tiled_hold = Vent_tiled;
Vent_tiled = Vent_tiled.*Mask_tiled;
Vent_BF_tiled = Vent_BF_tiled.*Mask_tiled;


%Plot Anatomic
Anatomic_Fig = figure('Name','All Anatomic','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Anatomic_Fig,'color','white','Units','inches','Position',[1 1 8 8])
%imagesc(Anat_tiled)
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Anat_tiled,[0.9,1.1],[0,0.99*ProtonMax],gray,0,gca);
%Anatomic_Fig = gcf;
axis off
colormap(gray);
title('Anatomic Image')

idcs = strfind(write_path,filesep);%determine location of file separators
sub_ind = strfind(write_path,'Xe-');
if ~isempty(sub_ind)
    move = true;
    while move
        if write_path(sub_ind-1) ~= '_'
            sub_ind = sub_ind - 1;
        else
            move = false;
        end
    end
    Subject = write_path(sub_ind:(idcs(end)-1));
else
    Subject = write_path((end-10):end);
end


Rpttitle = [Subject '_Vent_QC_Report'];
rpt = Report(fullfile(write_path,'Analysis_Reports',Rpttitle),'pdf');

chap1 = Chapter(['Ventilation Imaging Results: ' Subject]);
chap1.Numbered = false;

newsect = Section('Reconstruction and Masking');
newsect.Numbered = false;

fig = Figure(Anatomic_Fig);
fig.Snapshot.Caption = 'Anatomic Image';
add(newsect,fig);

%Plot Anatomic with Mask
Mask_Map = [1 0 0];
%figure;
Mask_Fig = figure('Name','All Anatomic with Mask','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Mask_Fig,'color','white','Units','inches','Position',[1 1 8 8])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Mask_tiled,[0.9,1.1],[0,0.99*ProtonMax],Mask_Map,0.25,gca);

colormap(gca,Mask_Map)
title('Anatomic Image Masked')

fig = Figure(Mask_Fig);
fig.Snapshot.Caption = 'Anatomic Image with Mask Overlay';
add(newsect,fig);

Scaled_Vent_tile = Vent_tiled_hold/(prctile(Vent_tiled(Mask_tiled==1),95));
%Plot Ventilation with Mask outlines
Vent_Fig = figure('Name','All Ventilation with Mask Outline','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Vent_Fig,'color','white','Units','inches','Position',[1 1 8 8])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Scaled_Vent_tile,[0,1],[0,0.99*ProtonMax],gray,1,gca);
%imagesc(Vent_tiled);
%axis off
colormap(gray)
hold on
B = bwboundaries(Mask_tiled);
for j = 1:length(B)
    if length(B{j})>2
        plot(B{j}(:,2),B{j}(:,1),'r')
    end
end
title('Ventilation Image')

VentOnly_Fig = figure('Name','All Ventilation','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(VentOnly_Fig,'color','white','Units','inches','Position',[1 1 8 8])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Scaled_Vent_tile,[0,1],[0,0.99*ProtonMax],gray,1,gca);
%imagesc(Vent_tiled);
%axis off
colormap(gray)

fig = Figure(VentOnly_Fig);
fig.Snapshot.Caption = ['Ventilation Image. SNR for Ventilation Image: ' num2str(SNR,'%1.2f')];
add(newsect,fig);

fig = Figure(Vent_Fig);
fig.Snapshot.Caption = ['Ventilation Image with Mask Outline. SNR for Ventilation Image: ' num2str(SNR,'%1.2f')];
add(newsect,fig);

%Plot Anatomic with Ventilation Overlay
CMap = [linspace(0,0,256)',linspace(0,1,256)',linspace(0,1,256)'];
Scaled_Vent_tile = Vent_tiled/(prctile(Vent_tiled(Mask_tiled==1),95));
Vent_Overlay_Fig = figure('Name','Ventilation Overlay','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Vent_Overlay_Fig,'color','white','Units','inches','Position',[1 1 8 8])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Scaled_Vent_tile,[0.1,1],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap);
title('Ventilation Overlay')

fig = Figure(Vent_Overlay_Fig);
fig.Snapshot.Caption = 'Ventilation Image Overlaid on Anatomic';
add(newsect,fig);

Scaled_Vent_BF_tile = Vent_BF_tiled/(prctile(Vent_BF_tiled(Mask_tiled==1),95));
%Plot Bias Corrected 
Vent_BF_Fig = figure('Name','Bias Corrected Ventilation','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Vent_BF_Fig,'color','white','Units','inches','Position',[1 1 8 8])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Scaled_Vent_BF_tile,[0,1],[0,0.99*ProtonMax],gray,1,gca);
%imagesc(Vent_tiled);
%axis off
colormap(gray)
title('Ventilation Image after N4 Bias Correction')

fig = Figure(Vent_BF_Fig);
fig.Snapshot.Caption = 'Ventilation Image after N4 Bias Correction';
add(newsect,fig);

%Plot Anatomic with Bias Corrected Ventilation Overlay
CMap = [linspace(0,0,256)',linspace(0,1,256)',linspace(0,1,256)'];

Vent_Overlay_Fig = figure('Name','Ventilation Overlay','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Vent_Overlay_Fig,'color','white','Units','inches','Position',[1 1 8 8])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Scaled_Vent_BF_tile,[0.1,1],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap);
title('Bias Corrected Ventilation Overlay')

if ~isfolder(fullfile(write_path,'Shareable_Figs'))
    mkdir(fullfile(write_path,'Shareable_Figs'))
end
saveas(Vent_Overlay_Fig,fullfile(write_path,'Shareable_Figs','Ventilation_Image.jpg'));

fig = Figure(Vent_Overlay_Fig);
fig.Snapshot.Caption = 'Ventilation Image after N4 Bias Correction Overlaid on Anatomic';
add(newsect,fig);

add(chap1,newsect);
%% Now, the Various Types of Ventilation Analysis

% %% First, Mean Anchored Linear Binning, No Bias Correction
% try
%     newsect = Section('Mean Anchored Linear Binning Analysis - No Bias Correction');
%     newsect.Numbered = false;
% 
%     fig = Figure(MALB_Output.AllFig);
%     fig.Snapshot.Caption = 'Ventilation Image with Defects Masked using Mean Anchored Linear Binning Approach - Red: Complete Defect, Orange: Incomplete Defect, Blue: Hyperventilation';
%     add(newsect,fig);
% 
%     tableStyle = { Width("100%"), ...
%                    Border("solid"), ...
%                    RowSep("solid"), ...
%                    ColSep("solid") };
% 
%     headerStyle = { BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
% 
%     footerStyle = { BackgroundColor("LightCyan"), ...
%                 ColSep("none"), ...
%                 WhiteSpace("preserve") };
% 
%     headerContent = {'Complete Defect', 'Incomplete Defect', 'Normal', 'Hyperventilated'};
%     bodyContent = {[num2str(MALB_Output.Complete,'%1.2f') '%'], [num2str(MALB_Output.Incomplete,'%1.2f'), '%'], [num2str(MALB_Output.Normal,'%1.2f') '%'], [num2str(MALB_Output.Hyper,'%1.2f') '%']};
% 
%     footerContent = {[],'VDP ',[num2str(MALB_Output.VDP,'%1.2f') '%'],[]};
% 
%     table = FormalTable(headerContent,bodyContent,footerContent);
%     table.Style = tableStyle;
% 
%     table.Header.TableEntriesHAlign = "center";
%     table.Header.Style = headerStyle;
% 
%     footer = table.Footer;
%     footer.Style = footerStyle;
% 
%     Defect_Entry = entry(table.Header,1,1);
%     Defect_Entry.Style = {BackgroundColor("Red"), ...
%                 Bold(true) };
% 
%     Incomp_Entry = entry(table.Header,1,2);
%     Incomp_Entry.Style = {BackgroundColor("Yellow"), ...
%                 Bold(true) };
% 
%     Normal_Entry = entry(table.Header,1,3);
%     Normal_Entry.Style = {BackgroundColor("White"), ...
%                 Bold(true) };
% 
%     Hyper_Entry = entry(table.Header,1,4);
%     Hyper_Entry.Style = {BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
%     table.TableEntriesHAlign = "center";
% 
%     add(newsect,table);
% 
%     fig = Figure(MALB_Output.HistFig);
%     fig.Snapshot.Caption = 'Histogram of Ventilation Values within Masked Volume using Mean Anchored Linear Binning Approach';
%     add(newsect,fig);
% 
%     add(chap1,newsect);
% catch
%     newsect = Section('Mean Anchored Linear Binning Analysis - No Bias Correction');
%     newsect.Numbered = false;
%     add(newsect,'Report Generation Failed for Mean Anchored Linear Binning Analysis on Non-bias corrected images');
%     add(chap1,newsect);
% end
% 
% 
% %% Next, Mean Anchored Linear Binning on Bias Corrected Image
% try
%     newsect = Section('Mean Anchored Linear Binning Analysis - Bias Corrected Image');
%     newsect.Numbered = false;
% 
%     fig = Figure(MALB_BF_Output.AllFig);
%     fig.Snapshot.Caption = 'N4 Bias Corrected Ventilation Image with Defects Masked using Mean Anchored Linear Binning Approach - Red: Complete Defect, Orange: Incomplete Defect, Blue: Hyperventilation';
%     add(newsect,fig);
% 
%     tableStyle = { Width("100%"), ...
%                    Border("solid"), ...
%                    RowSep("solid"), ...
%                    ColSep("solid") };
% 
%     headerStyle = { BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
% 
%     footerStyle = { BackgroundColor("LightCyan"), ...
%                 ColSep("none"), ...
%                 WhiteSpace("preserve") };
% 
%     headerContent = {'Complete Defect', 'Incomplete Defect', 'Normal', 'Hyperventilated'};
%     bodyContent = {[num2str(MALB_BF_Output.Complete,'%1.2f') '%'], [num2str(MALB_BF_Output.Incomplete,'%1.2f'), '%'], [num2str(MALB_BF_Output.Normal,'%1.2f') '%'], [num2str(MALB_BF_Output.Hyper,'%1.2f') '%']};
% 
%     footerContent = {[],'VDP ',[num2str(MALB_BF_Output.VDP,'%1.2f') '%'],[]};
% 
%     table = FormalTable(headerContent,bodyContent,footerContent);
%     table.Style = tableStyle;
% 
%     table.Header.TableEntriesHAlign = "center";
%     table.Header.Style = headerStyle;
% 
%     footer = table.Footer;
%     footer.Style = footerStyle;
% 
%     Defect_Entry = entry(table.Header,1,1);
%     Defect_Entry.Style = {BackgroundColor("Red"), ...
%                 Bold(true) };
% 
%     Incomp_Entry = entry(table.Header,1,2);
%     Incomp_Entry.Style = {BackgroundColor("Yellow"), ...
%                 Bold(true) };
% 
%     Normal_Entry = entry(table.Header,1,3);
%     Normal_Entry.Style = {BackgroundColor("White"), ...
%                 Bold(true) };
% 
%     Hyper_Entry = entry(table.Header,1,4);
%     Hyper_Entry.Style = {BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
%     table.TableEntriesHAlign = "center";
% 
%     add(newsect,table);
% 
%     fig = Figure(MALB_BF_Output.HistFig);
%     fig.Snapshot.Caption = 'Histogram of Ventilation Values within Masked Volume using Mean Anchored Linear Binning Approach';
%     add(newsect,fig);
% 
%     add(chap1,newsect);
% catch
%     newsect = Section('Mean Anchored Linear Binning Analysis - Bias Correction');
%     newsect.Numbered = false;
%     add(newsect,'Report Generation Failed for Mean Anchored Linear Binning Analysis on bias corrected images');
%     add(chap1,newsect);
% end
% %% Linear Binning, No Bias Correction
% try
%     %Want to get my Healthy Cohort (if present) so that I can say how much of
%     %the histogram lives in each bin
%     if size(Vent,3) > 20
%         try
%             load(fullfile(parent_path,'Spiral_Vent_HealthyThresholds.mat'),'VentThresh','HealthyData');
%             HealthyDistPresent = 1;
%         catch
%             HealthyDistPresent = 0;
%         end
%     else
%         try
%             load(fullfile(parent_path,'CTC_Vent_HealthyThresholds.mat'),'VentThresh','HealthyData');
%             HealthyDistPresent = 1;
%         catch
%             HealthyDistPresent = 0;
%         end
%     end
% 
%     newsect = Section('Linear Binning Analysis - No Bias Correction');
%     newsect.Numbered = false;
% 
%     fig = Figure(LB_Output.AllFig);
%     fig.Snapshot.Caption = 'Binned Ventilation Image using Linear Binning Approach - Red: Complete Defect, Orange: Incomplete Defect, Greens: Healthy, Blues: Hyperventilation';
%     add(newsect,fig);
% 
%     tableStyle = { Width("100%"), ...
%                    Border("solid"), ...
%                    RowSep("solid"), ...
%                    ColSep("solid") };
% 
%     headerStyle = { BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
% 
%     footerStyle = { BackgroundColor("LightCyan"), ...
%                 ColSep("none"), ...
%                 WhiteSpace("preserve") };
%     %
%     headerContent = {[],'Defect', 'Low', 'Healthy', 'Healthy','High','High'};
%     bodyContent = {Subject,[num2str(LB_Output.VentBin1Percent,'%1.2f') '%'], [num2str(LB_Output.VentBin2Percent,'%1.2f'), '%'], [num2str(LB_Output.VentBin3Percent,'%1.2f') '%'], [num2str(LB_Output.VentBin4Percent,'%1.2f') '%'],[num2str(LB_Output.VentBin5Percent,'%1.2f') '%'],[num2str(LB_Output.VentBin6Percent,'%1.2f') '%']};
% 
%     if HealthyDistPresent
%         bodyContent = {bodyContent;'Healthy Ref',[num2str(HealthyData.BinPercentMeans.Vent(1),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(1),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(2),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(2),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(3),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(3),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(4),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(4),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(5),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(5),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(6),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(6),'%1.2f')]};
%     end
% 
%     table = FormalTable(headerContent,bodyContent);
%     table.Style = tableStyle;
% 
%     table.Header.TableEntriesHAlign = "center";
%     table.Header.Style = headerStyle;
% 
%     Defect_Entry = entry(table.Header,1,2);
%     Defect_Entry.Style = {BackgroundColor('#ff0000'), ...
%                 Bold(true) };
% 
%     Low_Entry = entry(table.Header,1,3);
%     Low_Entry.Style = {BackgroundColor('#ffb600'), ...
%                 Bold(true) };
% 
%     Normal1_Entry = entry(table.Header,1,4);
%     Normal1_Entry.Style = {BackgroundColor('#66b366'), ...
%                 Bold(true) };
% 
%     Normal2_Entry = entry(table.Header,1,5);
%     Normal2_Entry.Style = {BackgroundColor('#00ff00'), ...
%                 Bold(true) };
% 
%     High1_Entry = entry(table.Header,1,6);
%     High1_Entry.Style = {BackgroundColor('#0091b5'), ...
%                 Bold(true) };     
% 
%     High2_Entry = entry(table.Header,1,7);
%     High2_Entry.Style = {BackgroundColor('#0000ff'), ...
%                 Bold(true) };  
%     table.TableEntriesHAlign = "center";
% 
%     add(newsect,table);
% 
%     fig = Figure(LB_Output.HistFig);
%     fig.Snapshot.Caption = 'Histogram of Ventilation Values within Masked Volume';
%     add(newsect,fig);
% 
%     add(chap1,newsect);
% catch
%     newsect = Section('Linear Binning Analysis - No Bias Correction');
%     newsect.Numbered = false;
%     add(newsect,'Report Generation Failed for Linear Binning Analysis on Non-bias corrected images');
%     add(chap1,newsect);
% end
% %% Linear Binning, Bias Correction
% try
%     if size(Vent,3) > 20
%         try
%             load(fullfile(parent_path,'Spiral_Vent_BFCorr_HealthyThresholds.mat'),'VentThresh','HealthyData');
%             HealthyDistPresent = 1;
%         catch
%             HealthyDistPresent = 0;
%         end
%     else
%         try
%             load(fullfile(parent_path,'CTC_Vent_BFCorr_HealthyThresholds.mat'),'VentThresh','HealthyData');
%             HealthyDistPresent = 1;
%         catch
%             HealthyDistPresent = 0;
%         end
%     end
% 
% 
%     newsect = Section('Linear Binning Analysis - N4 Bias Corrected Images');
%     newsect.Numbered = false;
% 
%     fig = Figure(LB_BF_Output.AllFig);
%     fig.Snapshot.Caption = 'Binned Ventilation Image using Linear Binning Approach - Red: Complete Defect, Orange: Incomplete Defect, Greens: Healthy, Blues: Hyperventilation';
%     add(newsect,fig);
% 
%     tableStyle = { Width("100%"), ...
%                    Border("solid"), ...
%                    RowSep("solid"), ...
%                    ColSep("solid") };
% 
%     headerStyle = { BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
% 
%     footerStyle = { BackgroundColor("LightCyan"), ...
%                 ColSep("none"), ...
%                 WhiteSpace("preserve") };
%     %
%     headerContent = {[],'Defect', 'Low', 'Healthy', 'Healthy','High','High'};
%     bodyContent = {Subject,[num2str(LB_BF_Output.VentBin1Percent,'%1.2f') '%'], [num2str(LB_BF_Output.VentBin2Percent,'%1.2f'), '%'], [num2str(LB_BF_Output.VentBin3Percent,'%1.2f') '%'], [num2str(LB_BF_Output.VentBin4Percent,'%1.2f') '%'],[num2str(LB_BF_Output.VentBin5Percent,'%1.2f') '%'],[num2str(LB_BF_Output.VentBin6Percent,'%1.2f') '%']};
% 
%     if HealthyDistPresent
%         bodyContent = {bodyContent;'Healthy Ref',[num2str(HealthyData.BinPercentMeans.Vent(1),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(1),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(2),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(2),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(3),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(3),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(4),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(4),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(5),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(5),'%1.2f')],...
%                          [num2str(HealthyData.BinPercentMeans.Vent(6),'%1.2f'),'±',num2str(HealthyData.BinPercentStds.Vent(6),'%1.2f')]};
%     end
% 
%     table = FormalTable(headerContent,bodyContent);
%     table.Style = tableStyle;
% 
%     table.Header.TableEntriesHAlign = "center";
%     table.Header.Style = headerStyle;
% 
%     Defect_Entry = entry(table.Header,1,2);
%     Defect_Entry.Style = {BackgroundColor('#ff0000'), ...
%                 Bold(true) };
% 
%     Low_Entry = entry(table.Header,1,3);
%     Low_Entry.Style = {BackgroundColor('#ffb600'), ...
%                 Bold(true) };
% 
%     Normal1_Entry = entry(table.Header,1,4);
%     Normal1_Entry.Style = {BackgroundColor('#66b366'), ...
%                 Bold(true) };
% 
%     Normal2_Entry = entry(table.Header,1,5);
%     Normal2_Entry.Style = {BackgroundColor('#00ff00'), ...
%                 Bold(true) };
% 
%     High1_Entry = entry(table.Header,1,6);
%     High1_Entry.Style = {BackgroundColor('#0091b5'), ...
%                 Bold(true) };     
% 
%     High2_Entry = entry(table.Header,1,7);
%     High2_Entry.Style = {BackgroundColor('#0000ff'), ...
%                 Bold(true) };  
%     table.TableEntriesHAlign = "center";
% 
%     add(newsect,table);
% 
%     fig = Figure(LB_BF_Output.HistFig);
%     fig.Snapshot.Caption = 'Histogram of Ventilation Values within Masked Volume';
%     add(newsect,fig);
% 
%     add(chap1,newsect);
% catch
%     newsect = Section('Linear Binning Analysis - Bias Correction');
%     newsect.Numbered = false;
%     add(newsect,'Report Generation Failed for Linear Binning Analysis on bias corrected images');
%     add(chap1,newsect);
% end
% try
%     newsect = Section('Atropos Analysis');
%     newsect.Numbered = false;
% 
%     fig = Figure(Atropos_Output.AllFig);
%     fig.Snapshot.Caption = 'Ventilation Image with Atropos Segmentation overlaid - Red: Complete Defect, Orange: Incomplete Defect, Blue: Hyperventilation';
%     add(newsect,fig);
% 
%     tableStyle = { Width("100%"), ...
%                    Border("solid"), ...
%                    RowSep("solid"), ...
%                    ColSep("solid") };
% 
%     headerStyle = { BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
% 
%     footerStyle = { BackgroundColor("LightCyan"), ...
%                 ColSep("none"), ...
%                 WhiteSpace("preserve") };
% 
%     headerContent = {'Complete Defect', 'Incomplete Defect', 'Normal', 'Hyperventilated'};
%     bodyContent = {[num2str(Atropos_Output.Complete,'%1.2f') '%'], [num2str(Atropos_Output.Incomplete,'%1.2f'), '%'], [num2str(Atropos_Output.Normal,'%1.2f') '%'], [num2str(Atropos_Output.Hyper,'%1.2f') '%']};
% 
%     footerContent = {[],'VDP ',[num2str(Atropos_Output.VDP,'%1.2f') '%'],[]};
% 
%     table = FormalTable(headerContent,bodyContent,footerContent);
%     table.Style = tableStyle;
% 
%     table.Header.TableEntriesHAlign = "center";
%     table.Header.Style = headerStyle;
% 
%     footer = table.Footer;
%     footer.Style = footerStyle;
% 
%     Defect_Entry = entry(table.Header,1,1);
%     Defect_Entry.Style = {BackgroundColor("Red"), ...
%                 Bold(true) };
% 
%     Incomp_Entry = entry(table.Header,1,2);
%     Incomp_Entry.Style = {BackgroundColor("Yellow"), ...
%                 Bold(true) };
% 
%     Normal_Entry = entry(table.Header,1,3);
%     Normal_Entry.Style = {BackgroundColor("White"), ...
%                 Bold(true) };
% 
%     Hyper_Entry = entry(table.Header,1,4);
%     Hyper_Entry.Style = {BackgroundColor("LightBlue"), ...
%                 Bold(true) };
% 
%     table.TableEntriesHAlign = "center";
% 
%     add(newsect,table);
% 
%     fig = Figure(Atropos_Output.HistFig);
%     fig.Snapshot.Caption = 'Histogram of Ventilation Values within Masked Volume using Atropos';
%     add(newsect,fig);
% 
%     add(chap1,newsect);
% catch
%     newsect = Section('Atropos Analysis');
%     newsect.Numbered = false;
%     add(newsect,'Report Generation Failed for Atropos Analysis');
%     add(chap1,newsect);
% end
add(rpt,chap1);
close(rpt);
