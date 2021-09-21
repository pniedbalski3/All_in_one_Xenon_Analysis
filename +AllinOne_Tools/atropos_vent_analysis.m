function Output_Struct = atropos_vent_analysis(Vent,atropos_seg)

%Calculating precent of defects 
Output_Struct.VDP=100*(sum(sum(sum(atropos_seg==1)))+(sum(sum(sum(atropos_seg==2)))))/sum(sum(sum(atropos_seg>0)));
Output_Struct.Incomplete= (100*(sum(sum(sum(atropos_seg==2)))/sum(sum(sum(atropos_seg>0)))));
Output_Struct.Complete = 100*(sum(sum(sum(atropos_seg==1)))/sum(sum(sum(atropos_seg>0))));
Output_Struct.Hyper = 100*(sum(sum(sum(atropos_seg==4)))/sum(sum(sum(atropos_seg>0))));
Output_Struct.Normal = 100*((sum(sum(sum(atropos_seg>0))))-(sum(sum(sum(atropos_seg==1))))-(sum(sum(sum(atropos_seg==2))))-(sum(sum(sum(atropos_seg==4)))))/(sum(sum(sum(atropos_seg>0))));

Vent = Vent/max(Vent(:));

%bin defect signal for histogram 
d60 = Vent.*(atropos_seg==2); %Incomplete
d15 = Vent.*(atropos_seg==1);%Complete
d250 = Vent.*(atropos_seg==4);%Hyper
d1 = (Vent.*(atropos_seg==3));%Normal

%Find mean and standard deviation of defects
md1 = mean(d1(d1>0));
sd1 = std(d1(d1>0));
md60 = mean(d60(d60>0));
sd60 = std(d60(d60>0));
md15 = mean(d15(d15>0));
sd15 = std(d15(d15>0));
md250 = mean(d250(d250>0));
sd250 = std(d250(d250>0));
%% Create Histogram
Edges = linspace(0,1,100);
Output_Struct.HistFig = figure('Name','VDP Histogram','position',[350 350 750 350]);
set(Output_Struct.HistFig,'color','white','Units','inches','Position',[0.25 0.25 4 4])
histogram(d1(d1>0),Edges,'FaceColor','w','EdgeColor','k','facealpha',0.5);
hold on
histogram(d60(d60>0),Edges,'FaceColor','y','EdgeColor','k','facealpha',0.5);
histogram(d15(d15>0),Edges,'FaceColor','r','EdgeColor','k','facealpha',0.5);
histogram(d250(d250>0),Edges,'FaceColor','b','EdgeColor','k','facealpha',0.5);
h = findobj(gcf,'Type','patch'); 
legend1 = sprintf('Normal: %0.2f±%0.2f (%0.1f%%)',md1, sd1, Output_Struct.Normal);
legend2 = sprintf('Incomplete: %0.2f±%0.2f (%0.1f%%)',md60,sd60,Output_Struct.Incomplete);
legend3 = sprintf('Complete: %0.2f±%0.2f (%0.1f%%)',md15,sd15, Output_Struct.Complete);
legend4 = sprintf('Hyper: %0.2f±%0.2f (%0.1f%%)',md250,sd250, Output_Struct.Hyper);
legend({legend1 legend2 legend3 legend4});
title1 = sprintf('Ventilation Defect Percentage %0.1f%%',Output_Struct.VDP);
title({title1},'Fontweight','bold','FontSize',12);
%set(gcf,'PaperPosition',[0 0 7.5 3.5]);
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.01])
%print('Ventilation_Histogram','-dpng','-r300');

%% Display Images
[centerslice,firstslice,lastslice] = Tools.getimcenter(atropos_seg);

%Create ColorMap
CMap = [255 0 0; 255 192 0; 0 255 0; 0 0 255]/255;
     
%For 5 slice, I want to hit a couple different places:
slicestep = floor((lastslice-firstslice)/8);
VentMax = max(Vent(atropos_seg>0));

Output_Struct.ClinFig = figure('Name','VDP Summary 5 Slice','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output_Struct.ClinFig,'color','white','Units','inches','Position',[1 1 5*3 4])
tiledlayout(1,5,'TileSpacing','none','Padding','compact');
nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Vent(:,:,centerslice-2*slicestep))),squeeze(atropos_seg(:,:,centerslice-2*slicestep)),[1 4],[0,0.99*VentMax],CMap,.25,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Vent(:,:,centerslice-slicestep))),squeeze(atropos_seg(:,:,centerslice-slicestep)),[1,4],[0,0.99*VentMax],CMap,.25,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Vent(:,:,centerslice))),squeeze(atropos_seg(:,:,centerslice)),[1,4],[0,0.99*VentMax],CMap,.25,gca);
colormap(gca,CMap)
title('VDP Maps','FontSize',24)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Vent(:,:,centerslice+slicestep))),squeeze(atropos_seg(:,:,centerslice+slicestep)),[1,4],[0,0.99*VentMax],CMap,.25,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Vent(:,:,centerslice+2*slicestep))),squeeze(atropos_seg(:,:,centerslice+2*slicestep)),[1,4],[0,0.99*VentMax],CMap,.25,gca);
colormap(gca,CMap)

%% All Fig
Output_Struct.AllFig = figure('Name','All Slice Summary','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output_Struct.AllFig,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
Vent_tiled = Tools.tile_image(Vent(:,:,firstslice:lastslice),3);
Defects_tiled = Tools.tile_image(atropos_seg(:,:,firstslice:lastslice),3);

Label = {'Defect','Low','Normal','High'};

[~,~] = Tools.imoverlay(Vent_tiled,Defects_tiled,[1,4],[0,0.99*VentMax],CMap,0.25,gca);
colormap(gca,CMap)
cbar = colorbar(gca','Location','southoutside','Ticks',[]);
pos = abs(cbar.Position);
cbar.Position = [pos(1),0,pos(3),pos(4)];
title('Ventilation Defect Masks','FontSize',16)
Tools.binning_colorbar(cbar,4,Label);
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
title('Ventilation Defect Masks','FontSize',24)

