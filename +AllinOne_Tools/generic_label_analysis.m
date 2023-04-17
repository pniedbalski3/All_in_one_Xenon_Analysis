function Output_Struct = generic_label_analysis(Vent,Segmentation)

%Let's make this structure the maximum length always.
Output_Struct(1).BinPct = 0;
Output_Struct(2).BinPct = 0;
Output_Struct(3).BinPct = 0;
Output_Struct(4).BinPct = 0;
Output_Struct(5).BinPct = 0;
Output_Struct(6).BinPct = 0;
for i = 1:(length(unique(Segmentation))-1)
    Output_Struct(i).BinPct = nnz(Segmentation(:)==i)/nnz(Segmentation(:))*100;
end
%% Create Histogram
Vent = Vent/max(Vent(:));
Edges = linspace(0,1,100);
Output_Struct(1).HistFig = figure('Name','VDP Histogram','position',[350 350 750 350]);
set(Output_Struct(1).HistFig,'color','white','Units','inches','Position',[0.25 0.25 4 4])
%CMap = [255 0 0; 255 192 0; 0 255 0; 0 0 255]/255;
CMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC     
CMap = CMap(1:(length(unique(Segmentation))-1),:);
for i = 1:(length(unique(Segmentation))-1)
    data = Vent.*(Segmentation==i);
    histogram(data(data>0),Edges,'FaceColor',CMap(i,:),'EdgeColor','k','facealpha',0.25);
    mylegend{i} = ['Bin ' num2str(i) ': ' num2str(Output_Struct(i).BinPct,3)];
    hold on
end
legend(mylegend)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.01])

%% Display Images
[centerslice,firstslice,lastslice] = Tools.getimcenter(Segmentation);

%Create ColorMap

%For 5 slice, I want to hit a couple different places:
slicestep = floor((lastslice-firstslice)/8);
VentMax = max(Vent(Segmentation>0));


%% All Fig
Output_Struct(1).AllFig = figure('Name','All Slice Summary','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output_Struct(1).AllFig,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
Vent_tiled = Tools.tile_image(Vent(:,:,firstslice:lastslice),3);
Defects_tiled = Tools.tile_image(Segmentation(:,:,firstslice:lastslice),3);

%Label = {'Defect','Low','Normal','High'};

[~,~] = Tools.imoverlay(Vent_tiled,Defects_tiled,[1,(length(unique(Segmentation))-1)],[0,0.99*VentMax],CMap,0.25,gca);
colormap(gca,CMap)
cbar = colorbar(gca','Location','southoutside','Ticks',[]);
%pos = abs(cbar.Position);
%cbar.Position = [pos(1),0,pos(3),pos(4)];
title('Ventilation Defect Masks','FontSize',16)
%Tools.binning_colorbar(cbar,4,Label);
%InSet = get(gca, 'TightInset');
%set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
title('Ventilation Defect Masks','FontSize',24)