function [SumVentFig,SumDissFig,SumBarrFig,SumRBCFig,SumRBCBarFig] = disp_ge_sumfigs(Proton_Mask,VentBinMap,H1_Image,DissolvedBinMap,BarrierBinMap,RBCBinMap,RBCBarrierBinMap,SNRS)

ProtonMax = prctile(abs(H1_Image(:)),99.99);

VentSNR = SNRS.VentSNR;
GasSNR = SNRS.GasSNR;
DissolvedSNR = SNRS.DissolvedSNR;
BarrierSNR = SNRS.BarrierSNR;
RBCSNR = SNRS.RBCSNR;
RBC2Bar = SNRS.RBC2Bar;

SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier
SixBinRBCBarMap = [ 197/255 27/255 125/255; 225/255 129/255 162/255; 0.4 0.7 0.4; 0 1 0; 1 0.7143 0; 1 0 0]; %Used for RBC/Barrier ratio

%% Determine which slices to plot (a la Matt Willmering)
NumPlotSlices = 7;
Co_MaskVoxels = squeeze(sum(Proton_Mask,[1,2]));
Co_StartIndex = find(Co_MaskVoxels,1,'first');
Co_EndIndex = find(Co_MaskVoxels,1,'last');
Co_MiddleIndex = round((Co_StartIndex+Co_EndIndex)/2);
Co_Step = floor((Co_EndIndex-Co_StartIndex)/NumPlotSlices);
Slices_Co = (Co_MiddleIndex-Co_Step*(NumPlotSlices-1)/2):Co_Step:(Co_MiddleIndex+Co_Step*(NumPlotSlices-1)/2);
    %Axial
Ax_MaskVoxels = squeeze(sum(Proton_Mask,[2,3]));
Ax_StartIndex = find(Ax_MaskVoxels,1,'first');
Ax_EndIndex = find(Ax_MaskVoxels,1,'last');
Ax_MiddleIndex = round((Ax_StartIndex+Ax_EndIndex)/2);
Ax_Step = floor((Ax_EndIndex-Ax_StartIndex)/NumPlotSlices);
Slices_Ax = (Ax_MiddleIndex-Ax_Step*(NumPlotSlices-1)/2):Ax_Step:(Ax_MiddleIndex+Ax_Step*(NumPlotSlices-1)/2);


Vent_Summary_figs = cat(3,VentBinMap(:,:,Slices_Co),fliplr(rot90(permute(squeeze(abs(VentBinMap(Slices_Ax,:,:))),[2 3 1]),-1)));
H1_Summary_figs = cat(3,abs(H1_Image(:,:,Slices_Co)),fliplr(rot90(permute(squeeze(abs(H1_Image(Slices_Ax,:,:))),[2 3 1]),-1)));
Dis_Summary_figs = cat(3,DissolvedBinMap(:,:,Slices_Co),fliplr(rot90(permute(squeeze(abs(DissolvedBinMap(Slices_Ax,:,:))),[2 3 1]),-1)));
RBC_Summary_figs = cat(3,RBCBinMap(:,:,Slices_Co),fliplr(rot90(permute(squeeze(abs(RBCBinMap(Slices_Ax,:,:))),[2 3 1]),-1)));
Barrier_Summary_figs = cat(3,BarrierBinMap(:,:,Slices_Co),fliplr(rot90(permute(squeeze(abs(BarrierBinMap(Slices_Ax,:,:))),[2 3 1]),-1)));
RBCBar_Summary_figs = cat(3,RBCBarrierBinMap(:,:,Slices_Co),fliplr(rot90(permute(squeeze(abs(RBCBarrierBinMap(Slices_Ax,:,:))),[2 3 1]),-1)));

Vent_Sum_Tile = AllinOne_Tools.tile_image(Vent_Summary_figs,3,'nColumns',NumPlotSlices);
H1_Sum_Tile = AllinOne_Tools.tile_image(H1_Summary_figs,3,'nColumns',NumPlotSlices);
Dis_Sum_Tile = AllinOne_Tools.tile_image(Dis_Summary_figs,3,'nColumns',NumPlotSlices);
RBC_Sum_Tile = AllinOne_Tools.tile_image(RBC_Summary_figs,3,'nColumns',NumPlotSlices);
Bar_Sum_Tile = AllinOne_Tools.tile_image(Barrier_Summary_figs,3,'nColumns',NumPlotSlices);
RBCBar_Sum_Tile = AllinOne_Tools.tile_image(RBCBar_Summary_figs,3,'nColumns',NumPlotSlices);

%Vent
SumVentFig = figure('Name','Ventitlation Binned','units','normalized','outerposition',[0 0 1 4/NumPlotSlices]);%set(SumVentFig,'WindowState','minimized');
set(SumVentFig,'color','white','Units','inches','Position',[0.5 0.5 2*NumPlotSlices-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,Vent_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinMap,1,gca);
colormap(gca,SixBinMap)
%title('Binned Ventilation','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cbar = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cbar,6,Vent_Dis_RBC_Label);
catch
end
set(SumVentFig,'WindowState','minimized');

%Dissolved
SumDissFig = figure('Name','Dissolved Binned','units','normalized','outerposition',[0 0 1 4/NumPlotSlices]);%set(SumVentFig,'WindowState','minimized');
set(SumDissFig,'color','white','Units','inches','Position',[0.5 0.5 2*NumPlotSlices-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,Dis_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinMap,1,gca);
colormap(gca,SixBinMap)
%title('Binned Dissolved','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cbar = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cbar,6,Vent_Dis_RBC_Label);
catch
end
set(SumDissFig,'WindowState','minimized');

%Barrier
SumBarrFig = figure('Name','Barrier Binned','units','normalized','outerposition',[0 0 1 4/NumPlotSlices]);%set(SumVentFig,'WindowState','minimized');
set(SumBarrFig,'color','white','Units','inches','Position',[0.5 0.5 2*NumPlotSlices-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,Bar_Sum_Tile,[1,8],[0,0.99*ProtonMax],EightBinMap,1,gca);
colormap(gca,EightBinMap)
%title('Binned Barrier','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cbar = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cbar,8,Bar_Label);
catch
end
set(SumBarrFig,'WindowState','minimized');

%RBC
SumRBCFig = figure('Name','RBC Binned','units','normalized','outerposition',[0 0 1 4/NumPlotSlices]);%set(SumVentFig,'WindowState','minimized');
set(SumRBCFig,'color','white','Units','inches','Position',[0.5 0.5 2*NumPlotSlices-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,RBC_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinMap,1,gca);
colormap(gca,SixBinMap)
%title('Binned RBC','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cbar = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cbar,6,Vent_Dis_RBC_Label);
catch
end
set(SumRBCFig,'WindowState','minimized');

%RBC/Barrier
SumRBCBarFig = figure('Name','RBC to Barrier Binned','units','normalized','outerposition',[0 0 1 4/NumPlotSlices]);%set(SumVentFig,'WindowState','minimized');
set(SumRBCBarFig,'color','white','Units','inches','Position',[0.5 0.5 2*NumPlotSlices-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,RBCBar_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinRBCBarMap,1,gca);
colormap(gca,SixBinRBCBarMap)
%title('Binned RBC/Barrier','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cbar = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cbar,6,RBCBar_Label);
catch
end
set(SumRBCBarFig,'WindowState','minimized');