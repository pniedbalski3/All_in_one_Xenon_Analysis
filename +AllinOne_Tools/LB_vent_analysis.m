function Output = LB_vent_analysis(Vent,Anat,Mask,BFtrue)
%Function to calculate ventilation defects using linear binning
%So that I load the correct healthy cohort distribution, pass a boolean
%telling whether images are bias corrected or not.


parent_path = which('Xe_Analysis.LB_vent_analysis');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file
%I need to know whether I'm doing Spiral, or CTC. Spiral should always have
%lots of slices, so we can use that to determine which healthy cohort
%distribution to load in
if size(Vent,3) > 20
    try
        if BFtrue
            load(fullfile(parent_path,'Spiral_Vent_BFCorr_HealthyThresholds.mat'),'VentThresh','HealthyData');
            HealthyDistPresent = 1;
        else
            load(fullfile(parent_path,'Spiral_Vent_HealthyThresholds.mat'),'VentThresh','HealthyData');
            HealthyDistPresent = 1;
        end
    catch
        VentThresh = [0.51-2*0.19,0.51-1*0.19,0.51,0.51+1*0.19,0.51+2*0.19];
        HealthyDistPresent = 0;
    end
else
    try
        if BFtrue
            load(fullfile(parent_path,'CTC_Vent_BFCorr_HealthyThresholds.mat'),'VentThresh','HealthyData');
            HealthyDistPresent = 1;
        else
            load(fullfile(parent_path,'CTC_Vent_HealthyThresholds.mat'),'VentThresh','HealthyData');
            HealthyDistPresent = 1;
        end
    catch
        VentThresh = [0.51-2*0.19,0.51-1*0.19,0.51,0.51+1*0.19,0.51+2*0.19];
        HealthyDistPresent = 0;
    end
end

%Start by scaling Ventilation image to top 1% of image voxels in mask
ProtonMax = prctile(abs(Vent(Mask==1)),99);

ScaledVentImage = Vent/ProtonMax;
ScaledVentImage(ScaledVentImage>1) = 1;

SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC

%Vent Binning
VentBinMap = Tools.BinImages(ScaledVentImage, VentThresh);
VentBinMap = VentBinMap.*Mask;%Mask to lung volume

Output.VentBinMap = VentBinMap;
Output.BinMap = SixBinMap;

%% Now, find how full each bin is:

%Ventilation Quantification
Output.VentMean = mean(ScaledVentImage(Mask==1));
Output.VentStd = std(ScaledVentImage(Mask==1));
Output.VentBin1Percent = sum(VentBinMap(:)==1)/sum(Mask(:)==1)*100;
Output.VentBin2Percent = sum(VentBinMap(:)==2)/sum(Mask(:)==1)*100;
Output.VentBin3Percent = sum(VentBinMap(:)==3)/sum(Mask(:)==1)*100;
Output.VentBin4Percent = sum(VentBinMap(:)==4)/sum(Mask(:)==1)*100;
Output.VentBin5Percent = sum(VentBinMap(:)==5)/sum(Mask(:)==1)*100;
Output.VentBin6Percent = sum(VentBinMap(:)==6)/sum(Mask(:)==1)*100;

%% Display some pictures
VentEdges = [-0.5, linspace(0,1,100) 1.5];
if HealthyDistPresent
    Output.HistFig = Tools.CalculateDissolvedHistogram(ScaledVentImage(Mask==1),VentEdges,VentThresh,SixBinMap,HealthyData.VentEdges,HealthyData.HealthyVentFit);
else
    Output.HistFig = Tools.CalculateDissolvedHistogram(ScaledVentImage(Mask==1),VentEdges,VentThresh,SixBinMap,[],[]);
end
set(Output.HistFig,'Name','Ventilation Histogram');%title(Output.HistFig.CurrentAxes,'99 Percentile Scaled Ventilation Histogram');

%% Display Images

[centerslice,firstslice,lastslice] = Tools.getimcenter(Mask);

%Create ColorMap
CMap = SixBinMap;
     
%For 5 slice, I want to hit a couple different places:
slicestep = floor((lastslice-firstslice)/8);
ProtonMax = max(Anat(:));

Output.ClinFig = figure('Name','VDP Summary 5 Slice','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output.ClinFig,'color','white','Units','inches','Position',[1 1 5*3 4])
tiledlayout(1,5,'TileSpacing','none','Padding','compact');
nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Anat(:,:,centerslice-2*slicestep))),squeeze(VentBinMap(:,:,centerslice-2*slicestep)),[1 6],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Anat(:,:,centerslice-slicestep))),squeeze(VentBinMap(:,:,centerslice-slicestep)),[1,6],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Anat(:,:,centerslice))),squeeze(VentBinMap(:,:,centerslice)),[1,6],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap)
title('VDP Maps','FontSize',24)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Anat(:,:,centerslice+slicestep))),squeeze(VentBinMap(:,:,centerslice+slicestep)),[1,6],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap)

nexttile
[~,~] = Tools.imoverlay(squeeze(abs(Anat(:,:,centerslice+2*slicestep))),squeeze(VentBinMap(:,:,centerslice+2*slicestep)),[1,6],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap)

%% All Fig
Output.AllFig = figure('Name','All Slice Summary','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Output.AllFig,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
Anat_tiled = Tools.tile_image(Anat(:,:,firstslice:lastslice),3);
Binned_tiled = Tools.tile_image(VentBinMap(:,:,firstslice:lastslice),3);

Label = {'Defect','Low','Healthy','Healthy','High','High'};
[~,~] = Tools.imoverlay(Anat_tiled,Binned_tiled,[1,6],[0,0.99*ProtonMax],CMap,1,gca);
colormap(gca,CMap)
cbar = colorbar(gca','Location','southoutside','Ticks',[]);
pos = abs(cbar.Position);
cbar.Position = [pos(1),0,pos(3),pos(4)];
title('Ventilation Defect Masks','FontSize',16)
Tools.binning_colorbar(cbar,6,Label);
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])


