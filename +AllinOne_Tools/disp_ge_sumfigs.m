function [SumVentFig,SumDissFig,SumMemFig,SumRBCFig,SumRBCMemFig] = disp_ge_sumfigs(Proton_Mask,VentBinMap,H1_Image,DissolvedBinMap,MembraneBinMap,RBCBinMap,RBCMembraneBinMap,SNRS)

ProtonMax = prctile(abs(H1_Image(:)),99.99);

VentSNR = SNRS.VentSNR;
GasSNR = SNRS.GasSNR;
DissolvedSNR = SNRS.DissolvedSNR;
MembraneSNR = SNRS.MembraneSNR;
RBCSNR = SNRS.RBCSNR;
RBC2Mem = SNRS.RBC2Mem;

SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for Membrane
SixBinRBCMemMap = [ 197/255 27/255 125/255; 225/255 129/255 162/255; 0.4 0.7 0.4; 0 1 0; 1 0.7143 0; 1 0 0]; %Used for RBC/Membrane ratio

%% Determine which slices to plot (a la Matt Willmering)
NumPlotSlices = 16;
Co_MaskVoxels = squeeze(sum(Proton_Mask,[1,2]));
Co_StartIndex = find(Co_MaskVoxels,1,'first');
Co_EndIndex = find(Co_MaskVoxels,1,'last');
Co_MiddleIndex = round((Co_StartIndex+Co_EndIndex)/2);
Co_Step = floor((Co_EndIndex-Co_StartIndex)/NumPlotSlices);
Slices_Co = (Co_MiddleIndex-Co_Step*(NumPlotSlices)/2):Co_Step:(Co_MiddleIndex+Co_Step*(NumPlotSlices-2)/2);
    %Axial
Ax_MaskVoxels = squeeze(sum(Proton_Mask,[2,3]));
Ax_StartIndex = find(Ax_MaskVoxels,1,'first');
Ax_EndIndex = find(Ax_MaskVoxels,1,'last');
Ax_MiddleIndex = round((Ax_StartIndex+Ax_EndIndex)/2);
Ax_Step = floor((Ax_EndIndex-Ax_StartIndex)/NumPlotSlices);
Slices_Ax = (Ax_MiddleIndex-Ax_Step*(NumPlotSlices-1)/2):Ax_Step:(Ax_MiddleIndex+Ax_Step*(NumPlotSlices-1)/2);


Vent_Summary_figs = cat(3,VentBinMap(:,:,Slices_Co(1:(NumPlotSlices/2))),VentBinMap(:,:,Slices_Co((NumPlotSlices/2+1):end)));
H1_Summary_figs = cat(3,abs(H1_Image(:,:,Slices_Co(1:(NumPlotSlices/2)))),abs(H1_Image(:,:,Slices_Co((NumPlotSlices/2+1):end))));
Dis_Summary_figs = cat(3,DissolvedBinMap(:,:,Slices_Co(1:(NumPlotSlices/2))),abs(DissolvedBinMap(:,:,Slices_Co((NumPlotSlices/2+1):end))));
RBC_Summary_figs = cat(3,RBCBinMap(:,:,Slices_Co(1:(NumPlotSlices/2))),abs(RBCBinMap(:,:,Slices_Co((NumPlotSlices/2+1):end))));
Membrane_Summary_figs = cat(3,MembraneBinMap(:,:,Slices_Co(1:(NumPlotSlices/2))),abs(MembraneBinMap(:,:,Slices_Co((NumPlotSlices/2+1):end))));
RBCMem_Summary_figs = cat(3,RBCMembraneBinMap(:,:,Slices_Co(1:(NumPlotSlices/2))),abs(RBCMembraneBinMap(:,:,Slices_Co((NumPlotSlices/2+1):end))));

Vent_Sum_Tile = AllinOne_Tools.tile_image(Vent_Summary_figs,3,'nColumns',NumPlotSlices/2);
H1_Sum_Tile = AllinOne_Tools.tile_image(H1_Summary_figs,3,'nColumns',NumPlotSlices/2);
Dis_Sum_Tile = AllinOne_Tools.tile_image(Dis_Summary_figs,3,'nColumns',NumPlotSlices/2);
RBC_Sum_Tile = AllinOne_Tools.tile_image(RBC_Summary_figs,3,'nColumns',NumPlotSlices/2);
Mem_Sum_Tile = AllinOne_Tools.tile_image(Membrane_Summary_figs,3,'nColumns',NumPlotSlices/2);
RBCMem_Sum_Tile = AllinOne_Tools.tile_image(RBCMem_Summary_figs,3,'nColumns',NumPlotSlices/2);

%Vent
SumVentFig = figure('Name','Ventitlation Binned','units','normalized','outerposition',[0 0 1 4/((NumPlotSlices/2))]);%set(SumVentFig,'WindowState','minimized');
set(SumVentFig,'color','white','Units','inches','Position',[0.5 0.5 2*(NumPlotSlices/2)-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,Vent_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinMap,1,gca);
colormap(gca,SixBinMap)
%title('Binned Ventilation','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cMem = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cMem,6,Vent_Dis_RBC_Label);
catch
end
set(SumVentFig,'WindowState','minimized');

%Dissolved
SumDissFig = figure('Name','Dissolved Binned','units','normalized','outerposition',[0 0 1 4/(NumPlotSlices/2)]);%set(SumVentFig,'WindowState','minimized');
set(SumDissFig,'color','white','Units','inches','Position',[0.5 0.5 2*(NumPlotSlices/2)-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,Dis_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinMap,1,gca);
colormap(gca,SixBinMap)
%title('Binned Dissolved','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cMem = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cMem,6,Vent_Dis_RBC_Label);
catch
end
set(SumDissFig,'WindowState','minimized');

%Membrane
SumMemFig = figure('Name','Membrane Binned','units','normalized','outerposition',[0 0 1 4/(NumPlotSlices/2)]);%set(SumVentFig,'WindowState','minimized');
set(SumMemFig,'color','white','Units','inches','Position',[0.5 0.5 2*(NumPlotSlices/2)-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,Mem_Sum_Tile,[1,8],[0,0.99*ProtonMax],EightBinMap,1,gca);
colormap(gca,EightBinMap)
%title('Binned Membrane','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cMem = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cMem,8,Mem_Label);
catch
end
set(SumMemFig,'WindowState','minimized');

%RBC
SumRBCFig = figure('Name','RBC Binned','units','normalized','outerposition',[0 0 1 4/(NumPlotSlices/2)]);%set(SumVentFig,'WindowState','minimized');
set(SumRBCFig,'color','white','Units','inches','Position',[0.5 0.5 2*(NumPlotSlices/2)-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,RBC_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinMap,1,gca);
colormap(gca,SixBinMap)
%title('Binned RBC','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cMem = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cMem,6,Vent_Dis_RBC_Label);
catch
end
set(SumRBCFig,'WindowState','minimized');

%RBC/Membrane
SumRBCMemFig = figure('Name','RBC to Membrane Binned','units','normalized','outerposition',[0 0 1 4/(NumPlotSlices/2)]);%set(SumVentFig,'WindowState','minimized');
set(SumRBCMemFig,'color','white','Units','inches','Position',[0.5 0.5 2*(NumPlotSlices/2)-1.1 2*2])
[~,~] = AllinOne_Tools.imoverlay(H1_Sum_Tile,RBCMem_Sum_Tile,[1,6],[0,0.99*ProtonMax],SixBinRBCMemMap,1,gca);
colormap(gca,SixBinRBCMemMap)
%title('Binned RBC/Membrane','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)])
cMem = colorbar(gca','Location','south','Ticks',[]);
try
    AllinOne_Tools.binning_colorbar(cMem,6,RBCMem_Label);
catch
end
set(SumRBCMemFig,'WindowState','minimized');