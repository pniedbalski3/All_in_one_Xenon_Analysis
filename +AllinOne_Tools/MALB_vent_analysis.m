function Output = MALB_vent_analysis(Image,Mask)

%Function to calculate ventilation defects using mean anchored linear
%binning

%Outputs a structure containing 3 figures, +VDP, Hyperventilation

%Code borrowed heavily from CCHMC Code
defect60 = medfilt3(double((Image<(mean(Image(Mask>0))*0.6)).*(Mask>0)));
defect15 = medfilt3(double((Image<(mean(Image(Mask>0))*0.15)).*(Mask>0)));
defect250 = medfilt3(double((Image>(mean(Image(Mask>0))*2)).*(Mask>0)));
defectArray = defect60+defect15+3*defect250;

Image = Image/max(Image(Mask==1));

%bin defect signal for histogram 
d60 = Image.*(defectArray==1); %Incomplete
d15 = Image.*(defectArray==2);%Complete
d250 = Image.*(defectArray==3);%Hyper
d1 = (Image.*(defectArray==0)).*Mask;%Normal

%Calculating precent of defects 
VDP=100*(nnz(defectArray==1)+nnz(defectArray==2))/nnz(Mask>0);
Incomplete= (100*(nnz(defectArray==1)/nnz(Mask>0)));
Complete = 100*(nnz(defectArray==2)/nnz(Mask>0));
Hyper = 100*(nnz(defectArray==3)/nnz(Mask>0));
Normal = 100*((nnz(Mask>0)-nnz(defectArray==1)-nnz(defectArray==2)-nnz(defectArray==3))/nnz(Mask>0));

Output.VDP = VDP;
Output.Incomplete = Incomplete;
Output.Complete = Complete;
Output.Hyper = Hyper;
Output.Normal = Normal;

%Find mean and standard deviation of defects
md1 = mean(d1(d1>0));
sd1 = std(d1(d1>0));
md60 = mean(d60(d60>0));
sd60 = std(d60(d60>0));
md15 = mean(d15(d15>0));
sd15 = std(d15(d15>0));
md250 = mean(d250(d250>0));
sd250 = std(d250(d250>0));

%equalizing histogram bin counts for each defect
%acnts = 50; 
%a = histogram(d1(d1>0),acnts);
% bcnts = length(a)*(max(d60(d60>0))-min(d60(d60>0)))/(max(d1(d1>0))-min(d1(d1>0)));
% ccnts = length(a)*(max(d15(d15>0))-min(d15(d15>0)))/(max(d1(d1>0))-min(d1(d1>0)));
% dcnts = length(a)*(max(d250(d250>0))-min(d250(d250>0)))/(max(d1(d1>0))-min(d1(d1>0)));

Edges = linspace(0,1,100);

%% Create Histogram
Output.HistFig = figure('Name','VDP Histogram','position',[350 350 750 350]);
set(Output.HistFig,'color','white','Units','inches','Position',[0.25 0.25 4 4])
histogram(d1(d1>0),Edges,'FaceColor','w','EdgeColor','k','facealpha',0.5);
hold on
histogram(d60(d60>0),Edges,'FaceColor','y','EdgeColor','k','facealpha',0.5);
histogram(d15(d15>0),Edges,'FaceColor','r','EdgeColor','k','facealpha',0.5);
histogram(d250(d250>0),Edges,'FaceColor','b','EdgeColor','k','facealpha',0.5);
h = findobj(gcf,'Type','patch'); 
legend1 = sprintf('Normal: %0.2f±%0.2f (%0.1f%%)',md1, sd1, Normal);
legend2 = sprintf('Incomplete: %0.2f±%0.2f (%0.1f%%)',md60,sd60,Incomplete);
legend3 = sprintf('Complete: %0.2f±%0.2f (%0.1f%%)',md15,sd15, Complete);
legend4 = sprintf('Hyper: %0.2f±%0.2f (%0.1f%%)',md250,sd250, Hyper);
legend({legend1 legend2 legend3 legend4});
title1 = sprintf('Ventilation Defect Percentage %0.1f%%',VDP);
title({title1},'Fontweight','bold','FontSize',12);
%set(gcf,'PaperPosition',[0 0 7.5 3.5]);
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.01])
%print('Ventilation_Histogram','-dpng','-r300');

%% Display Images
[centerslice,firstslice,lastslice] = Tools.getimcenter(Mask);

%Create ColorMap
CMap = [255 0 0;255 192 0; 0 0 255]/255;
%Fix DefectArray
tmp = defectArray;
tmp(defectArray==1) = 2;
tmp(defectArray==2) = 1;
defectArray = tmp;

Output.VentBinMap = defectArray;
Output.BinMap = CMap;

%For 5 slice, I want to hit a couple different places:
slicestep = floor((lastslice-firstslice)/8);
VentMax = max(Image(Mask>0));

Output.ClinFig = figure('Name','VDP Summary 5 Slice','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output.ClinFig,'color','white','Units','inches','Position',[1 1 5*3 4])
tiledlayout(1,5,'TileSpacing','none','Padding','compact');
nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Image(:,:,centerslice-2*slicestep))),squeeze(defectArray(:,:,centerslice-2*slicestep)),[1 3],[0,0.99*VentMax],CMap,1,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Image(:,:,centerslice-slicestep))),squeeze(defectArray(:,:,centerslice-slicestep)),[1,3],[0,0.99*VentMax],CMap,1,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Image(:,:,centerslice))),squeeze(defectArray(:,:,centerslice)),[1,3],[0,0.99*VentMax],CMap,1,gca);
colormap(gca,CMap)
title('VDP Maps','FontSize',24)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Image(:,:,centerslice+slicestep))),squeeze(defectArray(:,:,centerslice+slicestep)),[1,3],[0,0.99*VentMax],CMap,1,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Image(:,:,centerslice+2*slicestep))),squeeze(defectArray(:,:,centerslice+2*slicestep)),[1,3],[0,0.99*VentMax],CMap,1,gca);
colormap(gca,CMap)

%% All Fig
Output.AllFig = figure('Name','All Slice Summary','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output.AllFig,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
Vent_tiled = Tools.tile_image(Image(:,:,firstslice:lastslice),3);
Defects_tiled = Tools.tile_image(defectArray(:,:,firstslice:lastslice),3);

Label = {'Defect','Low','High'};

[~,~] = Tools.imoverlay(Vent_tiled,Defects_tiled,[1,3],[0,0.99*VentMax],CMap,0.5,gca);
colormap(gca,CMap)
cbar = colorbar(gca','Location','southoutside','Ticks',[]);
pos = abs(cbar.Position);
cbar.Position = [pos(1),0,pos(3),pos(4)];
title('Ventilation Defect Masks','FontSize',16)
Tools.binning_colorbar(cbar,3,Label);
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])

