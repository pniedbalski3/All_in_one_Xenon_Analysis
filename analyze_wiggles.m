function analyze_wiggles(Dis_Image,LoRes_Gas_Image,HiRes_Gas_Image,H1_Image_Dis,Cal_Raw,Proton_Mask,write_path,Dis_Fid,Gas_Fid,Params,Dis_Traj,Gas_Traj)

parent_path = which('analyze_wiggles');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

V_file = fopen(fullfile(parent_path,'Pipeline_Version.txt'),'r');
Pipeline_Version = fscanf(V_file,'%s');

if(exist(fullfile(parent_path,'AncillaryFiles','HealthyCohort.mat'),'file') == 2) %if Healthy cohort data exists, use
    HealthyFile = dir(fullfile(parent_path,'AncillaryFiles','HealthyCohort.mat'));%get file info
    HealthyData = load(fullfile(HealthyFile.folder,HealthyFile.name), '-regexp','^(?!Comb|Ind)...');%import all variable but figures
    VentThresh = HealthyData.thresholds.Vent;
    RBCThresh = HealthyData.thresholds.RBC;
else %use thresholds from Duke 1.5T Quantitative Analysis Paper 10.1002/mp.12264,
    VentThresh = [0.51-2*0.19,0.51-1*0.19,0.51,0.51+1*0.19,0.51+2*0.19];%6
    RBCThresh = [0.0026-2*0.0010,0.0026-1*0.0010,0.0026,0.0026+1*0.0010,0.0026+2*0.0010];%6
end

%% Get various Parameters
TR = Params.TR;
TE = Params.TE;
ActTE90 = TE;
GasFA = Params.GasFA;
DisFA = Params.DisFA;
Dwell = Params.Dwell;
freq_jump = Params.freq_offset;
scanDateStr = Params.scandatestr;

%% Calibration
try
    disData_avg = Cal_Raw.data;
    t = double((0:(length(disData_avg)-1))*Cal_Raw.dwell);
    disfitObj = Spectroscopy.NMR_TimeFit_v(disData_avg,t,[1 1 1],[0 -700  -7400],[250 200 30],[0 200 0],[0 0 0],0,length(t)); % first widths lorenzian, 2nd are gauss
    disfitObj = disfitObj.fitTimeDomainSignal();
    RBC2Bar = disfitObj.area(1)/disfitObj.area(2);
    %T2* Calculations
    GasT2Star = 1/(pi * disfitObj.fwhm(3))*1000; %in ms
    BarrierT2Star = 1/(pi * max([disfitObj.fwhm(2),disfitObj.fwhmG(2)]))*1000; %in ms
    RBCT2Star = 1/(pi * disfitObj.fwhm(1))*1000; %in ms
catch
    %If no calibration is found, set some "default" values so that it will
    %run through at least.
    RBC2Bar = 0.5;
    GasT2Star = 15;
    RBCT2Star = 1.5;
end

[Bar_Image,RBC_Image, Delta_angle_deg, ~] = AllinOne_Tools.SinglePointDixon_V2(Dis_Image,-RBC2Bar,LoRes_Gas_Image,Proton_Mask);
GasImageScaled = abs(LoRes_Gas_Image)/(exp(-ActTE90/GasT2Star));
RBCfraction = disfitObj.area(1)/(disfitObj.area(2)+disfitObj.area(1));
RBCImageCorrected = RBC_Image/(exp(-ActTE90/RBCT2Star));

%% Scale Images appropriately
GasImageScaled = GasImageScaled*sind(DisFA)/sind(GasFA);
%Express RBC/Gas, Barrier/Gas, and Dissolved/Gas as %
RBC2Gas = abs(RBCImageCorrected)./abs(GasImageScaled).*Proton_Mask*100;

VentMax = prctile(abs(HiRes_Gas_Image(Proton_Mask(:))),99);
ScaledVentImage = abs(HiRes_Gas_Image)/VentMax;
ScaledVentImage(ScaledVentImage>1) = 1;

%% Bin Images
%Ventilation Binning
VentBinMap = AllinOne_Tools.BinImages(ScaledVentImage,VentThresh);
VentBinMap = VentBinMap.*Proton_Mask;
VentBinMask = logical((VentBinMap-1).*Proton_Mask); %Mask for ventilated areas only

RBCBinMap = AllinOne_Tools.BinImages(RBC2Gas, RBCThresh);
RBCBinMap = RBCBinMap.*VentBinMask;%Mask to ventilated volume
RBC_Mask = logical((RBCBinMap-1).*VentBinMask); %Create a mask for areas with RBC signal

%% Wiggle Analysis
ImSize = size(RBC2Gas,1);
save(fullfile(write_path,'Gas_Exchange_Workspace_4_wiggles.mat'),'Dis_Fid','Gas_Fid','Dis_Traj','Gas_Traj','H1_Image_Dis','LoRes_Gas_Image','Proton_Mask','VentBinMask','RBC_Mask','RBC2Bar','TR','ImSize','scanDateStr','write_path');
AllinOne_Wiggles.wiggle_imaging_2(Dis_Fid,Gas_Fid,Dis_Traj,Gas_Traj,H1_Image_Dis,LoRes_Gas_Image,Proton_Mask,VentBinMask,RBC_Mask,-RBC2Bar,TR,size(RBC2Gas,1),scanDateStr,write_path)

