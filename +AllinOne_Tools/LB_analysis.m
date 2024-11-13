function VentBinMap= LB_analysis(Vent,Mask,BFtrue)
%Function to calculate ventilation defects using linear binning
%So that I load the correct healthy cohort distribution, pass a boolean
%telling whether images are bias corrected or not.


parent_path = which('AllinOne_Tools.LB_analysis');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file
%I need to know whether I'm doing Spiral, or CTC. Spiral should always have
%lots of slices, so we can use that to determine which healthy cohort
%distribution to load in
if size(Vent,3) > 20
    try
        if BFtrue
            load(fullfile(parent_path,'AncillaryFiles','Healthy_Vent_Reference_N4.mat'),'vent_thresh_N4','vent_fit_N4');
            VentThresh = vent_thresh_N4;
        else
            load(fullfile(parent_path,'AncillaryFiles','Healthy_Vent_Reference.mat'),'vent_thresh','vent_fit');
            VentThresh = vent_thresh;
        end
    catch
        VentThresh = [0.51-2*0.19,0.51-1*0.19,0.51,0.51+1*0.19,0.51+2*0.19];
    end
else
    try
        if BFtrue
            load(fullfile(parent_path,'CTC_Vent_BFCorr_HealthyThresholds.mat'),'VentThresh','HealthyData');
        else
            load(fullfile(parent_path,'CTC_Vent_HealthyThresholds.mat'),'VentThresh','HealthyData');
        end
    catch
        VentThresh = [0.51-2*0.19,0.51-1*0.19,0.51,0.51+1*0.19,0.51+2*0.19];
    end
end


%Start by scaling Ventilation image to top 3% of image voxels in mask
ProtonMax = prctile(abs(Vent(Mask==1)),97);

ScaledVentImage = Vent/ProtonMax;
%ScaledVentImage(ScaledVentImage>1) = 1;

%Vent Binning
VentBinMap = Tools.BinImages(ScaledVentImage, VentThresh);
VentBinMap = VentBinMap.*Mask;%Mask to lung volume