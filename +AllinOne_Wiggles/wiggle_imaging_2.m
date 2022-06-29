function wiggle_imaging_2(disfid,gasfid,traj,gastraj,H1_im,Gas_Image,H1_Mask,Vent_Mask,RBC_Mask,RBC2Bar,TR,ImSize,scanDateStr,write_path)
%% Body of Function
%Function to implement data detrending, oscillation binning, etc.
%Pass fids, trajectories, Proton image, RBC/Barrier Ratio, and TR. This function is going to be
%fully self contained, so it will bin, reconstruct, calculate oscillation images,
%display figures, and write out an "oscillation report". 

%Make sure masks are logical
H1_Mask = logical(H1_Mask);
Vent_Mask = logical(H1_Mask);
RBC_Mask = logical(RBC_Mask);

%Make a nice purple color
purp = [168 96 168]/255;

parent_path = which('Xe_Analysis.wiggle_imaging');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end-1)-1);%remove file

%excel_summary_file = 'C:\Users\pniedbalski\OneDrive - University of Kansas Medical Center\Documents\GitHub\Xenon_Pipeline\Analysis_Pipeline\AncillaryFiles\All_Wiggle_Summary.xlsx';

if(exist(fullfile(parent_path,'AncillaryFiles','HealthyCohort.mat'),'file') == 2) %if Healthy cohort data exists, use
    HealthyFile = dir(fullfile(parent_path,'AncillaryFiles','HealthyCohort.mat'));%get file info
    HealthyData = load(fullfile(HealthyFile.folder,HealthyFile.name), '-regexp','^(?!Comb|Ind)...');%import all variable but figures
    %RBCOscThresh = HealthyData.thresholds.RBCOsc;
    %First couple of times, healthy distribution won't be around
    HealthyDistPresent = 0;
else 
    RBCOscThresh = [8.9596-2*10.5608,8.9596-1*10.5608,8.9596,8.9596+1*10.5608,8.9596+2*10.5608,8.9596+3*10.5608,8.9596+4*10.5608];%8
    HealthyDistPresent = 0;
end
%For now
RBCOscThresh = [8.9596-2*10.5608,8.9596-1*10.5608,8.9596,8.9596+1*10.5608,8.9596+2*10.5608,8.9596+3*10.5608,8.9596+4*10.5608];%8

%% Rotate Mask and Gas

H1_Mask = Tools.canonical2matlab(H1_Mask);
RBC_Mask = Tools.canonical2matlab(RBC_Mask);

Gas_Image = Tools.canonical2matlab(Gas_Image);
H1_im = Tools.canonical2matlab(H1_im);

%% Change Sizes!
% oldsize = ImSize;
% ImSize = ImSize/2;
% H1_Mask = imresize3(H1_Mask,0.5);
% if size(gasfid,1) ~= size(disfid,1)
%     [gasfid,gastraj] = ImTools.change_mat_size(gasfid,gastraj,ImSize,oldsize*3/2);
% else
%     [gasfid,gastraj] = ImTools.change_mat_size(gasfid,gastraj,ImSize,oldsize);
% end
% [disfid,traj] = ImTools.change_mat_size(disfid,traj,ImSize,oldsize);

%% Check whether we've done the binning before - if so, load in binning values
%if isfile(fullfile(write_path,'Wiggle_Binning.mat'))
 %   load(fullfile(write_path,'Wiggle_Binning.mat'));
%else
    [Glob_Amp,Glob_Amp_Std] = Tools.bin_wiggles(disfid,gasfid,RBC2Bar,TR,write_path);
    load(fullfile(write_path,'Wiggle_Binning.mat'));
%end

%At this point, we should have indices for low and high binned projections,
%the total number of projections used for binning, and
%high-binned/low-binned RBC/Barrier
%% First, check that the total number of projections that we have is the same as was used for binning
%If not, binning indices are invalid, so run binning again
%if(Tot_Proj ~= size(disfid,2))
    %Tools.bin_wiggles(disfid,gasfid,-RBC2Bar,TR,write_path)
    %load(fullfile(write_path,'Wiggle_Binning.mat'));
%end

%% Now, need to divide Dissolved fids by Gas k0 to detrend data
Gask0 = abs(gasfid(1,:));
dis2gasfid = disfid;
for i = 1:size(disfid,2)
    dis2gasfid(:,i) = disfid(:,i)/Gask0(i);
end

%% Next, create keyhole. 
% Following my paper, use radius at which the keyhole is at least 50%
% sampled - Since there's ramp sampling and double sampling along radial
% arm, let's figure out keyhole radius as a percentage of k-space. Then, I
% can select a k-space radius (in pixel units) as the keyhole radius, which
% should be more robust than number of points.
radpts = 1:0.1:ceil(size(disfid,1)/2);
NHigh = length(High_Indx);
Full_Samp = 4*pi*radpts.^2;

Samp = NHigh./Full_Samp*100;

Key_Rad_Pts = find(Samp > 100.0,1,'last');

Key_Rad = radpts(Key_Rad_Pts)/(size(disfid,1)/2)*0.5;

%Now, we just need to pick out all the points of the trajectories with radius less than Key_Rad 
Traj_Rad = squeeze(sqrt(traj(1,:,:).^2+traj(2,:,:).^2+traj(3,:,:).^2));
num_k0 = length(find(Traj_Rad(:,1)==0));

Pts = find(Traj_Rad(:,1)<Key_Rad,1,'last');
Key_Rad = Pts;

%Data is doubly sampled along radial arm - we get two points for every one
%that was calculated
%Key_Rad = Key_Rad*2+num_k0-1;

Keyhole = dis2gasfid;
Keyhole(1:Key_Rad,:) = NaN;

High_Key = Keyhole;
Low_Key = Keyhole;

%I don't think that I did this previously, but I think I should probably
%scale the keyhole
mean_high = mean(abs(dis2gasfid(1,High_Indx)));
mean_low = mean(abs(dis2gasfid(1,Low_Indx)));

for i = 1:length(Keyhole)
    High_Key(:,i) = High_Key(:,i)*mean_high/abs(dis2gasfid(1,i));
    Low_Key(:,i) = Low_Key(:,i)*mean_low/abs(dis2gasfid(1,i));
end

%Put high and low keys in keyhole
High_Key(1:Key_Rad,High_Indx) = dis2gasfid(1:Key_Rad,High_Indx);
Low_Key(1:Key_Rad,Low_Indx) = dis2gasfid(1:Key_Rad,Low_Indx);

%% Keyhole Alternative Binning
radpts = 1:0.1:ceil(size(disfid,1)/2);
NHigh = length(Alt_Bin);
Full_Samp = 4*pi*radpts.^2;

Samp = NHigh./Full_Samp*100;

Key_Rad_Pts = find(Samp > 100.0,1,'last');

Key_Rad = radpts(Key_Rad_Pts)/(size(disfid,1)/2)*0.5;

%Now, we just need to pick out all the points of the trajectories with radius less than Key_Rad 
Traj_Rad = squeeze(sqrt(traj(1,:,:).^2+traj(2,:,:).^2+traj(3,:,:).^2));
num_k0 = length(find(Traj_Rad(:,1)==0));

Pts = find(Traj_Rad(:,1)<Key_Rad,1,'last');
Key_Rad = Pts;

Keyhole = dis2gasfid;
Keyhole(1:Key_Rad,:) = NaN;

%I should scale the keyhole!
Alt_Keys = zeros([size(dis2gasfid) size(Alt_Bin,1)]);
for i = 1:size(Alt_Bin,1)
    Alt_Keys(:,:,i) = Keyhole;
    mean_key = mean(abs(dis2gasfid(1,Alt_Bin(i,:))));
    for j = 1:length(Keyhole)
        Alt_Keys(:,j,i) = Alt_Keys(:,j,i)*mean_key/abs(dis2gasfid(1,j));
    end
    Alt_Keys(1:Key_Rad,Alt_Bin(i,:),i) = dis2gasfid(1:Key_Rad,Alt_Bin(i,:));
    
    %For debugging, let's look at the trajectories in each key
    %Tools.disp_traj(traj(:,:,Alt_Bin(i,:))); It really looks pretty good.
    
end

%% Now, need to reconstruct High, Low, and Unaltered Data
trajx = reshape(traj(1,:,:),1,[])';
trajy = reshape(traj(2,:,:),1,[])';
trajz = reshape(traj(3,:,:),1,[])';

traj_r = [trajx trajy trajz];

gastrajx = reshape(gastraj(1,:,:),1,[])';
gastrajy = reshape(gastraj(2,:,:),1,[])';
gastrajz = reshape(gastraj(3,:,:),1,[])';

gastraj_r = [gastrajx gastrajy gastrajz];
%orientation issue!
gastraj_hold = gastraj_r;
gastraj_r(:,1) = gastraj_hold(:,1);
gastraj_r(:,2) = gastraj_hold(:,3);
gastraj_r(:,3) = gastraj_hold(:,2);

%Reshape to column vectors
dis_data_r = reshape(dis2gasfid,1,[])';
high_data_r = reshape(High_Key,1,[])';
low_data_r = reshape(Low_Key,1,[])';
gas_data_r = reshape(gasfid,1,[])';

%Remove NaNs
all_nan = isnan(dis_data_r);
high_nan = isnan(high_data_r);
low_nan = isnan(low_data_r);
dis_data_r(all_nan) = [];
high_data_r(high_nan) = [];
low_data_r(low_nan) = [];
high_traj_r = traj_r;
high_traj_r(high_nan,:) = [];
low_traj_r = traj_r;
low_traj_r(low_nan,:) = [];
dis_traj_r = traj_r;
dis_traj_r(all_nan,:) = [];

%Reconstruct
All_Dis = Reconstruction.Dissolved_Phase_LowResRecon(ImSize,dis_data_r,dis_traj_r);
High_Dis = Reconstruction.Dissolved_Phase_LowResRecon(ImSize,high_data_r,high_traj_r);
Low_Dis = Reconstruction.Dissolved_Phase_LowResRecon(ImSize,low_data_r,low_traj_r);
%Gas_Image = Reconstruction.Dissolved_Phase_LowResRecon(ImSize,gas_data_r,gastraj_r);

%% What about alternative binning:

Alt_Images = zeros(ImSize,ImSize,ImSize,size(Alt_Bin,1));
for i = 1:size(Alt_Bin,1)
    thiskey = squeeze(Alt_Keys(:,:,i));
    thistraj = traj_r;
    thiskey_r = reshape(thiskey,1,[])';
    thisnan = isnan(thiskey_r);
    thiskey_r(thisnan) = [];
    thistraj(thisnan,:) = [];
    Alt_Images(:,:,:,i) = Reconstruction.Dissolved_Phase_LowResRecon(ImSize,thiskey_r,thistraj);
end

%% Separate RBC and Barrier Images
[All_Bar,All_RBC, ~, ~] = Tools.SinglePointDixon_V2(All_Dis,-RBC2Bar,Gas_Image,H1_Mask);
[High_Bar,High_RBC, ~, ~] = Tools.SinglePointDixon_V2(High_Dis,-High_RBC2Bar,Gas_Image,H1_Mask);
[Low_Bar,Low_RBC, ~, ~] = Tools.SinglePointDixon_V2(Low_Dis,-Low_RBC2Bar,Gas_Image,H1_Mask);

Alt_RBC = zeros(ImSize,ImSize,ImSize,size(Alt_Bin,1));
Alt_Bar = zeros(ImSize,ImSize,ImSize,size(Alt_Bin,1));
for i = 1:size(Alt_Bin,1)
    [Alt_Bar(:,:,:,i),Alt_RBC(:,:,:,i),~,~] = Tools.SinglePointDixon_V2(squeeze(Alt_Images(:,:,:,i)),-Alt_RBC2Bar(i),Gas_Image,H1_Mask);
end
Alt_RBC = abs(Alt_RBC);
All_RBC = abs(All_RBC);
% if ~MaskPres
%     %Just get RBC points with SNR > 2.5
%     [~,RBC_Mask] = Tools.erode_dilate(All_RBC,1,2.5);
%     RBC_Mask = logical(RBC_Mask.*Vent_Mask);
% end
%% Test to see if the many key approach even remotely works:
mean_RBC = zeros(1,size(Alt_Bin,1));
mean_Bar = zeros(1,size(Alt_Bin,1));
for i = 1:size(Alt_Bin,1)
    thisRBC = squeeze(Alt_RBC(:,:,:,i));
    thisBar = squeeze(Alt_Bar(:,:,:,i));
    mean_RBC(i) = mean(thisRBC(H1_Mask(:)));
    mean_Bar(i) = mean(thisBar(H1_Mask(:)));
end
figure('Name','Mean RBC and Bar')
plot(mean_RBC)
% hold on
% plot(mean_Bar)
hold off

%% Scale images such that 1 is the overall mean RBC signal
allmean = mean(mean_RBC);
Alt_RBC = Alt_RBC/allmean;
All_RBC2 = All_RBC/allmean;

%% Now, loop through points in mask and get maximum and minimum. Also, get overall phase shift
Phase_Step = 360 / size(Alt_Bin,1);

%Let's find the "phase" of the overall mean RBC:
if Alt_Min2Min
    [~,extr_ind] = max(mean_RBC);
    mean_Phase = extr_ind*Phase_Step;
else
    [~,extr_ind] = min(mean_RBC);
    mean_Phase = extr_ind*Phase_Step;
end

Amp = zeros(ImSize,ImSize,ImSize);
Phase = zeros(ImSize,ImSize,ImSize);
Phase(Phase == 0) = -361;

figure('Name','Debug Wiggles')
counter = 1;
for i = 1:ImSize
    for j = 1:ImSize
        for k = 1:ImSize
            if RBC_Mask(i,j,k) == 1
                tmp_RBC = squeeze(Alt_RBC(i,j,k,:));
                
                %Can I smooth this at all:
                tmp_RBC = smooth(tmp_RBC,3);
                
                %In the original paper, I scaled by the mean of the
                %non-keyhole RBC - Let's try that again!
                Amp(i,j,k) = (max(tmp_RBC)-min(tmp_RBC))/mean(All_RBC2(RBC_Mask==1));
                %Need to know whether we went from max to max or min to min           
                if Alt_Min2Min
                    [~,extr_ind] = max(tmp_RBC);
                else
                    [~,extr_ind] = min(tmp_RBC);
                end
                Phase(i,j,k) = mean_Phase - Phase_Step*extr_ind;
                
                %Let's have a look at every 100th point to see how this is
                %working
                if mod((i*ImSize*ImSize+j*ImSize+k),100) == 0
                    subplot(10,10,counter)
                    plot(tmp_RBC);
                    counter = counter+1;
                    if counter > 100
                        counter = 1;
                    end
                end
                
            end
        end
    end
end

Amp = Amp*100;

save(fullfile(write_path,'Alternative_Binning.mat'),'Amp','Phase');

%% Get SNR
NoiseMask = imerode(~H1_Mask,strel('sphere',7));%avoid edges/artifacts/partialvolume
HighRBC_SNR = (mean(High_RBC(Vent_Mask(:)))- mean(High_RBC(NoiseMask(:))))/std(High_RBC(NoiseMask(:)));
LowRBC_SNR = (mean(Low_RBC(Vent_Mask(:)))- mean(Low_RBC(NoiseMask(:))))/std(Low_RBC(NoiseMask(:)));
HighBar_SNR = (mean(High_Bar(Vent_Mask(:)))- mean(High_Bar(NoiseMask(:))))/std(High_Bar(NoiseMask(:)));
LowBar_SNR = (mean(Low_Bar(Vent_Mask(:)))- mean(Low_Bar(NoiseMask(:))))/std(Low_Bar(NoiseMask(:)));
%We don't need to correct for T2* or anything like that, because that will
%be a constant offset that will just cancel out when we get the oscillation
%amplitude.

% if ~MaskPres
%     %Just get RBC points with SNR > 2.5
%     [~,RBC_Mask] = Tools.erode_dilate(All_RBC,1,2.5);
%     RBC_Mask = logical(RBC_Mask.*Vent_Mask);
% end
%% Calculate Regional Oscillations
RBC_Osc = (High_RBC - Low_RBC)./mean(All_RBC(RBC_Mask(:)))*100.*RBC_Mask;

% I've looked at gas in the past, but maybe time to revisit
RBC_Osc_Gas = (High_RBC - Low_RBC)./abs(Gas_Image).*RBC_Mask;

%And let's look at dissolved as well
RBC_Osc_Dis = (High_RBC - Low_RBC)./abs(All_Dis)*100.*RBC_Mask;

%Let's also kill values outside of the range [-50 100] - just do for RBC
RBC_Mask(RBC_Osc>100) = false;
RBC_Mask(RBC_Osc<-50) = false;
RBC_Mask = logical(RBC_Mask);
RBC_Osc = RBC_Osc.*RBC_Mask;
%Make the RBC_Osc map non-masked areas a big negative number
RBC_Osc(~RBC_Mask) = -1000; 

%Make the RBC_Osc map non-masked areas a big negative number
RBC_Osc_Gas(~RBC_Mask) = -1000; 
RBC_Osc_Dis(~RBC_Mask) = -1000;

%We'll get Barrier oscillation too, just as a sanity check for now
Bar_Osc = (High_Bar - Low_Bar)./All_Bar*100.*RBC_Mask;
Bar_Osc(~RBC_Mask) = -1000;

Bar_Osc_Dis = (High_Bar - Low_Bar)./abs(All_Dis)*100.*RBC_Mask;
Bar_Osc_Dis(~RBC_Mask) = -1000;

Bar_Osc_Gas = (High_Bar - Low_Bar)./abs(Gas_Image).*RBC_Mask;
Bar_Osc_Gas(~RBC_Mask) = -1000;

%Get mean and standard deviation of oscillations
RBC_Osc_Mean = mean(RBC_Osc(RBC_Mask(:)));
RBC_Osc_Std = std(RBC_Osc(RBC_Mask(:)));
Bar_Osc_Mean = mean(Bar_Osc(RBC_Mask(:)));
Bar_Osc_Std = std(Bar_Osc(RBC_Mask(:)));

RBC_OscDis_Mean = mean(RBC_Osc_Dis(RBC_Mask(:)));
RBC_OscDis_Std = std(RBC_Osc_Dis(RBC_Mask(:)));

RBC_OscGas_Mean = mean(RBC_Osc_Gas(RBC_Mask(:)));
RBC_OscGas_Std = std(RBC_Osc_Gas(RBC_Mask(:)));

Bar_OscDis_Mean = mean(Bar_Osc_Dis(RBC_Mask(:)));
Bar_OscDis_Std = std(Bar_Osc_Dis(RBC_Mask(:)));

Bar_OscGas_Mean = mean(Bar_Osc_Gas(RBC_Mask(:)));
Bar_OscGas_Std = std(Bar_Osc_Gas(RBC_Mask(:)));

%% Bin Images - I am starting to think that this isn't the best way to do this for oscillations
EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier
OscBinMap = Tools.BinImages(RBC_Osc, RBCOscThresh);
OscBinMap = OscBinMap.*RBC_Mask;%Mask to ventilated volume

%% Now summary figures
[~,firstslice,lastslice] = Tools.getimcenter(H1_Mask);
ProtonMax = max(H1_im(:));
Phase(RBC_Mask==0) = -1000;
Bar_Label = {'Defect','Low','Healthy','Healthy','Elevated','Elevated','High','High'};
Phase_Label = {'Max Out Phase',' ',' ',' ','In Phase'};
try
    Anat_tiled1 = Tools.tile_image(H1_im(:,:,(firstslice-2):(lastslice+2)),3,'nRows',3);
    Anat_tiled = Tools.tile_image(H1_im(:,:,(firstslice-2):(lastslice+2)),3);
    RBCHigh_tiled = abs(Tools.tile_image(High_RBC(:,:,(firstslice-2):(lastslice+2)),3,'nRows',3));
    RBCLow_tiled = abs(Tools.tile_image(Low_RBC(:,:,(firstslice-2):(lastslice+2)),3,'nRows',3));
    BarHigh_tiled = abs(Tools.tile_image(High_Bar(:,:,(firstslice-2):(lastslice+2)),3,'nRows',3));
    BarLow_tiled = abs(Tools.tile_image(Low_Bar(:,:,(firstslice-2):(lastslice+2)),3,'nRows',3));
    RBCOsc_tiled = Tools.tile_image(RBC_Osc(:,:,(firstslice-2):(lastslice+2)),3);
    RBCOscGas_tiled = Tools.tile_image(RBC_Osc_Gas(:,:,(firstslice-2):(lastslice+2)),3);
    RBCOscDis_tiled = Tools.tile_image(RBC_Osc_Dis(:,:,(firstslice-2):(lastslice+2)),3);
    BarOsc_tiled = Tools.tile_image(Bar_Osc(:,:,(firstslice-2):(lastslice+2)),3);
    BarOscGas_tiled = Tools.tile_image(Bar_Osc_Gas(:,:,(firstslice-2):(lastslice+2)),3);
    BarOscDis_tiled = Tools.tile_image(Bar_Osc_Dis(:,:,(firstslice-2):(lastslice+2)),3);
    OscBin_tiled = Tools.tile_image(OscBinMap(:,:,(firstslice-2):(lastslice+2)),3);
    Amp_tiled = Tools.tile_image(Amp(:,:,(firstslice-2):(lastslice+2)),3);
    Phase_tiled = Tools.tile_image(Phase(:,:,(firstslice-2):(lastslice+2)),3);
catch
    Anat_tiled1 = Tools.tile_image(H1_im,3,'nRows',3);
    BarHigh_tiled = abs(Tools.tile_image(High_Bar,3,'nRows',3));
    BarLow_tiled = abs(Tools.tile_image(Low_Bar,3,'nRows',3));
    Anat_tiled = Tools.tile_image(H1_im,3);
    RBCOsc_tiled = Tools.tile_image(RBC_Osc,3);
    RBCOscGas_tiled = Tools.tile_image(RBC_Osc_Gas,3);
    RBCOscDis_tiled = Tools.tile_image(RBC_Osc_Dis,3);
    BarOsc_tiled = Tools.tile_image(Bar_Osc,3);
    BarOscGas_tiled = Tools.tile_image(Bar_Osc_Gas,3);
    BarOscDis_tiled = Tools.tile_image(Bar_Osc_Dis,3);
    OscBin_tiled = Tools.tile_image(OscBinMap,3);
    RBCHigh_tiled = Tools.tile_image(High_RBC,3,'nRows',3);
    RBCLow_tiled = Tools.tile_image(Low_RBC,3,'nRows',3);
    Amp_tiled = Tools.tile_image(Amp(:,:,:),3);
    Phase_tiled = Tools.tile_image(Phase(:,:,:),3);
end

%RBC_Lim = [min(RBC_Osc(RBC_Mask(:))) max(RBC_Osc(RBC_Mask(:)))];
RBC_Lim = [-20 40];
%Bar_Lim = [min(Bar_Osc(Vent_Mask(:))) max(Bar_Osc(Vent_Mask(:)))];



% %RBC High
% RBC_High_Montage = figure('Name','RBC High','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(RBC_High_Montage,'color','white','Units','inches','Position',[1 1 10 3.3])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled1,RBCHigh_tiled,[0 max(abs(RBCHigh_tiled(:)))],[0 max(abs(RBCHigh_tiled(:)))],gray,1,gca);
% axis off
% colormap(gray);
% title('RBC High Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(RBC_High_Montage,'textbox',[0.8 0.08 0.2 0.05],'Color',[1 1 1],'String',['SNR = ' num2str(HighRBC_SNR,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% set(RBC_High_Montage,'WindowState','minimized');
% saveas(RBC_High_Montage,fullfile(write_path,'Wiggle_figs','RBCHigh.png'));
% 
% %RBC Low
% RBC_Low_Montage = figure('Name','RBC Low','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(RBC_Low_Montage,'color','white','Units','inches','Position',[1 1 10 3.3])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled1,RBCLow_tiled,[0 max(abs(RBCLow_tiled(:)))],[0 max(abs(RBCLow_tiled(:)))],gray,1,gca);
% axis off
% colormap(gray);
% title('RBC Low Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(RBC_Low_Montage,'textbox',[0.8 0.08 0.2 0.05],'Color',[1 1 1],'String',['SNR = ' num2str(LowRBC_SNR,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% set(RBC_Low_Montage,'WindowState','minimized');
% saveas(RBC_High_Montage,fullfile(write_path,'Wiggle_figs','RBCHigh.png'));

%Bar High
% Bar_High_Montage = figure('Name','Bar High','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Bar_High_Montage,'color','white','Units','inches','Position',[1 1 10 3.3])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled1,BarHigh_tiled,[0 max(abs(BarHigh_tiled(:)))],[0 max(abs(BarHigh_tiled(:)))],gray,1,gca);
% axis off
% colormap(gray);
% title('Bar High Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(Bar_High_Montage,'textbox',[0.8 0.08 0.2 0.05],'Color',[1 1 1],'String',['SNR = ' num2str(HighBar_SNR,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% set(Bar_High_Montage,'WindowState','minimized');
% saveas(RBC_High_Montage,fullfile(write_path,'Wiggle_figs','RBCHigh.png'));
% 
% %RBC Low
% Bar_Low_Montage = figure('Name','Bar Low','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Bar_Low_Montage,'color','white','Units','inches','Position',[1 1 10 3.3])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled1,BarLow_tiled,[0 max(abs(BarLow_tiled(:)))],[0 max(abs(BarLow_tiled(:)))],gray,1,gca);
% axis off
% colormap(gray);
% title('Bar Low Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(Bar_Low_Montage,'textbox',[0.8 0.08 0.2 0.05],'Color',[1 1 1],'String',['SNR = ' num2str(LowBar_SNR,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% set(Bar_Low_Montage,'WindowState','minimized');
% saveas(RBC_Low_Montage,fullfile(write_path,'Wiggle_figs','RBCLow.png'));

if ~isfolder(fullfile(write_path,'Wiggle_figs'))
    mkdir(fullfile(write_path,'Wiggle_figs'));
end

%RBC Osc
RBC_Osc_Montage = figure('Name','RBC Oscillation old way','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(RBC_Osc_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
%set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,RBCOsc_tiled,RBC_Lim,[0,0.99*ProtonMax],parula,1,gca);
axis off
colormap(parula);
cbar = colorbar(gca','Location','southoutside');
pos = cbar.Position;
cbar.Position = [pos(1),0.03,pos(3),pos(4)];
title('RBC Oscillation Amplitude Old way','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
annotation(RBC_Osc_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(RBC_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
%set(RBC_Osc_Montage,'WindowState','minimized');
saveas(RBC_Osc_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Old_Way.png'));

%Amplitude from Alternative Binning Method
Amp_Montage = figure('Name','Oscillation Amplitude from Alternative Binning','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Amp_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
%set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Amp_tiled,[0.01 40],[0,0.99*ProtonMax],parula,1,gca);
axis off
colormap(parula);
cbar = colorbar(gca','Location','southoutside');
pos = cbar.Position;
cbar.Position = [pos(1),0.03,pos(3),pos(4)];
title('RBC Oscillation Amplitude Alternative Binning','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
annotation(Amp_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(mean(Amp(RBC_Mask(:))),'%.3f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
%set(RBC_Osc_Montage,'WindowState','minimized');
saveas(Amp_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Amp_From_Alternative_Binning.png'));

%Amplitude from Simple way
Amp2_Montage = figure('Name','Oscillation Phase from Alternative Binning','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
set(Amp2_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
%set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
axes('Units', 'normalized', 'Position', [0 0 1 1])
[~,~] = Tools.imoverlay(Anat_tiled,Phase_tiled,[-360 360],[0,0.99*ProtonMax],parula,1,gca);
axis off
colormap(parula);
cbar = colorbar(gca','Location','southoutside');
pos = cbar.Position;
cbar.Position = [pos(1),0.03,pos(3),pos(4)];
title('RBC Oscillation Phase Alternative Binning','FontSize',16)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
annotation(Amp2_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(mean(Phase(RBC_Mask(:))),'%.3f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
%set(RBC_Osc_Montage,'WindowState','minimized');
saveas(Amp2_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Phase_From_Alternative_Binning.png'));

%Amplitude from Simple way scaled by mean RBC rather than voxel
% Amp3_Montage = figure('Name','Oscillation Amplitude from RBC Stack','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Amp3_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,Amp3_tiled,[0.0001 20],[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('RBC Oscillation Amplitude Image Peak Diff Scaled by mean RBC','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(Amp3_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(mean(Amp3(RBC_Mask(:))),'%.3f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(RBC_Osc_Montage,'WindowState','minimized');
% saveas(Amp3_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Amp_From_mean_diff_Btw_peaks.png'));


% %RBC Osc as scaled by gas
% RBC_OscGas_Montage = figure('Name','RBC Oscillations scaled by gas','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(RBC_OscGas_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,RBCOscGas_tiled,RBC_Lim,[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('RBC Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(RBC_OscGas_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(RBC_OscGas_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(RBC_OscGas_Montage,'WindowState','minimized');
% saveas(RBC_OscGas_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Scaled_Gas.png'));

% %RBC Osc as scaled by Dis
% RBC_OscDis_Montage = figure('Name','RBC Oscillations scaled by Dis','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(RBC_OscDis_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,RBCOscDis_tiled,RBC_Lim,[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('RBC Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(RBC_OscDis_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(RBC_OscDis_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(RBC_OscGas_Montage,'WindowState','minimized');
% saveas(RBC_OscDis_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Scaled_Dis.png'));
% 
% %Bar Osc
% Bar_Osc_Montage = figure('Name','Barrier Oscillations','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Bar_Osc_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(BarMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,BarOsc_tiled,RBC_Lim,[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('Barrier Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.03])
% annotation(Bar_Osc_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['Bar Osc Mean = ' num2str(Bar_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(Bar_Osc_Montage,'WindowState','minimized');
% saveas(Bar_Osc_Montage,fullfile(write_path,'Wiggle_figs','Bar_Osc_Scaled_Bar.png'));
% 
% %Bar Osc
% Bar_OscGas_Montage = figure('Name','Barrier Oscillations By Gas','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Bar_OscGas_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(BarMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,BarOscGas_tiled,RBC_Lim,[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('Barrier Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.03])
% annotation(Bar_OscGas_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['Bar Osc Mean = ' num2str(Bar_OscGas_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(Bar_Osc_Montage,'WindowState','minimized');
% saveas(Bar_OscGas_Montage,fullfile(write_path,'Wiggle_figs','Bar_Osc_Scaled_Gas.png'));

% %Bar Osc
% Bar_OscDis_Montage = figure('Name','Barrier Oscillations by Dis','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Bar_OscDis_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(BarMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,BarOscDis_tiled,RBC_Lim,[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('Barrier Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)+.03])
% annotation(Bar_OscDis_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['Bar Osc Mean = ' num2str(Bar_OscDis_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(Bar_Osc_Montage,'WindowState','minimized');
% saveas(Bar_OscDis_Montage,fullfile(write_path,'Wiggle_figs','Bar_Osc_Scaled_Dis.png'));

% OscBinMontage = figure('Name','Binned Oscillations','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% %set(BarrierBinMontage,'color','white','Units','inches','Position',[1 1 10 3.3])
% set(OscBinMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,OscBin_tiled,[1,8],[0,0.99*ProtonMax],EightBinMap,1,gca);
% axis off
% colormap(gca,EightBinMap)
% cbar = colorbar(gca','Location','southoutside','Ticks',[]);
% pos = cbar.Position;
% cbar.Position = [pos(1),0,pos(3),pos(4)];
% %Tools.binning_colorbar(cbar,8,Bar_Label);
% title('Binned Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(OscBinMontage,'textbox',[0.8 0.08 0.2 0.05],'Color',[1 1 1],'String',['Mean Osc = ' num2str(RBC_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(OscBinMontage,'WindowState','minimized');
% saveas(OscBinMontage,fullfile(write_path,'Wiggle_figs','Binned_Oscillations.png'));
% 
% 

%Phase from Fit
% Phase_Montage = figure('Name','Oscillation Phase from RBC Stack','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Phase_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,Phase_tiled,[-pi pi],[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('RBC Oscillation Phase Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% %annotation(Phase_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(RBC_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(RBC_Osc_Montage,'WindowState','minimized');
% saveas(Phase_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Phase_From_Sin_Fit.png'));

%Freq from Fit
% Freq_Montage = figure('Name','Oscillation Freq from RBC Stack','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(Freq_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,Freq_tiled,[0.0001 2],[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('RBC Oscillation Freq Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% %annotation(Phase_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(RBC_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(RBC_Osc_Montage,'WindowState','minimized');
% saveas(Freq_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Freq_From_Sin_Fit.png'));

%Freq from Fit
% R2_Montage = figure('Name','Goodness of Sine fit','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% set(R2_Montage,'color','white','Units','inches','Position',[1 1 8 7.2])
% %set(RBCMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,R2_tiled,[0.00001 0.04],[0,0.99*ProtonMax],parula,1,gca);
% axis off
% colormap(parula);
% cbar = colorbar(gca','Location','southoutside');
% pos = cbar.Position;
% cbar.Position = [pos(1),0.03,pos(3),pos(4)];
% title('RBC Oscillation R^2 Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% %annotation(Phase_Montage,'textbox',[0.7 0.08 0.2 0.05],'Color',[1 1 1],'String',['RBC Osc Mean = ' num2str(RBC_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(RBC_Osc_Montage,'WindowState','minimized');
% saveas(R2_Montage,fullfile(write_path,'Wiggle_figs','RBC_Osc_Goodness_of_Fit.png'));

% NewOscBinMontage = figure('Name','Phase Binned Oscillations','units','normalized','outerposition',[.2 .2 1 4/3]);%set(ClinFig,'WindowState','minimized');
% %set(BarrierBinMontage,'color','white','Units','inches','Position',[1 1 10 3.3])
% set(NewOscBinMontage,'color','white','Units','inches','Position',[1 1 8 7.2])
% axes('Units', 'normalized', 'Position', [0 0 1 1])
% [~,~] = Tools.imoverlay(Anat_tiled,NewOscBin_tiled,[1,5],[0,0.99*ProtonMax],FiveBinMap,1,gca);
% axis off
% colormap(gca,FiveBinMap)
% cbar = colorbar(gca','Location','southoutside','Ticks',[]);
% pos = cbar.Position;
% cbar.Position = [pos(1),0,pos(3),pos(4)];
% %Tools.binning_colorbar(cbar,5,Phase_Label);
% title('Phase Binned Oscillation Image','FontSize',16)
% InSet = get(gca, 'TightInset');
% set(gca, 'Position', [InSet(1:2), 1-InSet(1)-InSet(3), 1-InSet(2)-InSet(4)-.01])
% annotation(NewOscBinMontage,'textbox',[0.8 0.08 0.2 0.05],'Color',[1 1 1],'String',['Mean Osc = ' num2str(RBC_Osc_Mean,'%.1f')],'FontSize',14,'FontName','Arial','FitBoxToText','on','BackgroundColor',[0 0 0],'VerticalAlignment','middle','HorizontalAlignment','center');
% %set(OscBinMontage,'WindowState','minimized');
% saveas(NewOscBinMontage,fullfile(write_path,'Wiggle_figs','Attempted_Phase_Bin.png'));

%% Histogram
% RBCOscEdges = [-100, linspace(RBCOscThresh(3)*-7,RBCOscThresh(3)*7,100) 100];
% NewRBCOscEdges = linspace(-50,50,100);
% 
% Osc_Phase_Edges = linspace(-150,20,100);
% 
% if HealthyDistPresent
%     RBCOscHistFig = GasExchangeV3.CalculateDissolvedHistogram(RBC_Osc(RBC_Mask(:)),RBCOscEdges,RBCOscThresh,EightBinMap,HealthyData.RBCOscEdges,HealthyData.HealthyRBCOscFit);
%     NewRBCOscHistFig = GasExchangeV3.CalculateDissolvedHistogram(RBC_Osc(RBC_Mask(:)),NewRBCOscEdges,New_RBCOscThresh,FiveBinMap,HealthyData.RBCOscEdges,HealthyData.HealthyRBCOscFit);
% else
%     RBCOscHistFig = GasExchangeV3.CalculateDissolvedHistogram(RBC_Osc(RBC_Mask(:)),RBCOscEdges,RBCOscThresh,EightBinMap,[],[]);
%     RBCOscGasHistFig = GasExchangeV3.CalculateDissolvedHistogram(RBC_Osc_Gas(RBC_Mask(:)),RBCOscEdges,RBCOscThresh,EightBinMap,[],[]);
%     RBCOscDisHistFig = GasExchangeV3.CalculateDissolvedHistogram(RBC_Osc_Dis(RBC_Mask(:)),RBCOscEdges,RBCOscThresh,EightBinMap,[],[]);
% %    NewRBCOscHistFig = GasExchangeV3.CalculateDissolvedHistogram(RBC_Osc(RBC_Mask(:)),NewRBCOscEdges,New_RBCOscThresh,FiveBinMap,[],[]);
% %    OscPhaseHistFig = GasExchangeV3.CalculateDissolvedHistogram(Phase_Osc(RBC_Mask(:)),Osc_Phase_Edges,Osc_Phase_Thresh,EightBinMap,[],[]);
% end
% 
% %Edit Names/Titles
% set(RBCOscHistFig,'Name','RBC Oscillation Histogram','WindowState','normal');%title(RBCBarHistFig.CurrentAxes,'RBC:Barrier Histogram');
% set(RBCOscGasHistFig,'Name','RBC Oscillation Histogram','WindowState','normal');%title(RBCBarHistFig.CurrentAxes,'RBC:Barrier Histogram');
% set(RBCOscDisHistFig,'Name','RBC Oscillation Histogram','WindowState','normal');%title(RBCBarHistFig.CurrentAxes,'RBC:Barrier Histogram');
% %set(NewRBCOscHistFig,'Name','RBC Oscillation fifth Histogram','WindowState','normal');%title(RBCBarHistFig.CurrentAxes,'RBC:Barrier Histogram');
% %set(OscPhaseHistFig,'Name','RBC Oscillation Phase Histogram','WindowState','normal');%title(RBCBarHistFig.CurrentAxes,'RBC:Barrier Histogram');
% saveas(RBCOscHistFig,fullfile(write_path,'Wiggle_figs','RBCOscHistFig.png'));
% saveas(RBCOscGasHistFig,fullfile(write_path,'Wiggle_figs','RBCOscHistFig.png'));
% saveas(RBCOscDisHistFig,fullfile(write_path,'Wiggle_figs','RBCOscHistFig.png'));
% %saveas(NewRBCOscHistFig,fullfile(write_path,'Wiggle_figs','NewRBCOscHistFig.png'));
% %saveas(OscPhaseHistFig,fullfile(write_path,'Wiggle_figs','OscPhaseHistFig.png'));
% 
% %Barrier/Gas Quantification
% RBCOscBin1Percent = sum(OscBinMap(:)==1)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin2Percent = sum(OscBinMap(:)==2)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin3Percent = sum(OscBinMap(:)==3)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin4Percent = sum(OscBinMap(:)==4)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin5Percent = sum(OscBinMap(:)==5)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin6Percent = sum(OscBinMap(:)==6)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin7Percent = sum(OscBinMap(:)==7)/sum(RBC_Mask(:)==1)*100;
% RBCOscBin8Percent = sum(OscBinMap(:)==8)/sum(RBC_Mask(:)==1)*100;

Hist_Fig = figure('Name','Histograms');
subplot(2,2,1)
histogram(RBC_Osc(RBC_Mask(:)))
title('Old Way RBC Oscillation Amplitude')
subplot(2,2,2)
histogram(Amp(RBC_Mask(:)))
title('Alternative Binning Amplitude')
subplot(2,2,4)
histogram(Phase(RBC_Mask(:)))
title('Alternative Binning Phase');


saveas(Hist_Fig,fullfile(write_path,'Wiggle_Histograms.png'));

%% Save Workspace
save(fullfile(write_path,'Wiggle_Workspace.mat'),'RBC_Osc','RBC_Mask','High_RBC','Low_RBC','H1_im','RBC_Osc_Mean','RBC_Osc_Std','All_RBC');


%% Write to excel
%Get subject from path
idcs = strfind(write_path,filesep);%determine location of file separators
try
    sub_ind = strfind(write_path,'Xe-');
    sub_end = find(idcs>sub_ind,1,'first');
    sub_end = idcs(sub_end);
    move = true;
    while move
        if write_path(sub_ind-1) ~= '_'
            sub_ind = sub_ind - 1;
        else
            move = false;
        end
    end
    Subject = write_path(sub_ind:(sub_end-1));
catch
    Subject = 'Unknown';
end

matfile = 'Wiggles2.mat';
SubjectMatch = [];
try
    load(fullfile(parent_path,'AncillaryFiles',matfile),'Wiggles');
    SubjectMatch = find(strcmpi(Wiggles.Date,scanDateStr) &...
        strcmpi(Wiggles.Subject,Subject));
catch
    headers = {'Subject','Date','Global_Amp','Global_Amp_std','Osc_Amp_Old_mean','Osc_Amp_Old_std','Osc_Amp_Alt_mean','Osc_Amp_Alt_std','Osc_Phase_mean','Osc_Phase_std'};
    Wiggles = cell2table(cell(0,size(headers,2)));
    Wiggles.Properties.VariableNames = headers;
end

NewData = {Subject,scanDateStr,Glob_Amp,Glob_Amp_Std,RBC_Osc_Mean,RBC_Osc_Std,mean(Amp(RBC_Mask(:))),std(Amp(RBC_Mask(:))),mean(Phase(RBC_Mask(:))),std(Phase(RBC_Mask(:)))};

if (isempty(SubjectMatch))%if no match
    Wiggles = [Wiggles;NewData];%append
else
    Wiggles(SubjectMatch,:) = NewData;%overwrite
end
save(fullfile(parent_path,'AncillaryFiles',matfile),'Wiggles')
excel_summary_file =  fullfile(parent_path,'AncillaryFiles','Wiggle_Summary_New.xlsx');
writetable(Wiggles,excel_summary_file,'Sheet',1)
% %% Reporting - "Clinical"
% idcs = strfind(write_path,filesep);%determine location of file separators
% path = write_path(1:idcs(end)-1);
% if ~exist(fullfile(path,'Analysis_Reports'))
%     mkdir(fullfile(path,'Analysis_Reports'));
% end
% 
% num = str2num(write_path(end)); %The number of the gas exchange scan should be the last character in the write path
% % Need to change the name of the report for whether doing CTC or Fast Dixon
% Seq_Name = 'Wiggle_Imaging';
% %Start "Clinical Report"
% %Get subject from path
% idcs = strfind(write_path,filesep);%determine location of file separators
% sub_ind = strfind(write_path,'Xe-');
% sub_end = find(idcs>sub_ind,1,'first');
% sub_end = idcs(sub_end);
% Subject = write_path(sub_ind:(sub_end-1));
% 
% Rpttitle = [Seq_Name num2str(num) '_Report_Subject_' Subject];
% 
% import mlreportgen.report.*
% import mlreportgen.dom.*
% 
% %Height of table rows
% d = Document(fullfile(path,'Analysis_Reports',Rpttitle),'pdf');
% open(d);
% try
%     currentLayout = d.CurrentPageLayout;
%     currentLayout.PageSize.Orientation = "landscape";
%     currentLayout.PageSize.Height = '8.5in';
%     currentLayout.PageSize.Width = '11in';
% 
%     pdfheader = PDFPageHeader;
%     p = Paragraph(['Wiggle Imaging Results, Subject ' Subject ': Imaged ' scanDateStr]);
%     p.Style = [p.Style, {HAlign('center'), Bold(true), FontSize('12pt')}];
%     append(pdfheader, p);
%     currentLayout.PageHeaders = pdfheader;
% 
%     currentLayout.PageMargins.Top = '0.05in';
%     currentLayout.PageMargins.Header = '0.25in';
%     currentLayout.PageMargins.Bottom = '0.0in';
%     currentLayout.PageMargins.Left = '0.5in';
%     currentLayout.PageMargins.Right = '0.5in';
%     currentLayout.PageSize.Orientation = "landscape";
% 
%     %Barrier
%     mainTableStyle = {Width('100%'), Border('none') ColSep('none'), RowSep('none')};
%     dataTableStyle = {Border('solid'), ColSep('solid'), RowSep('solid'),...
%         OuterMargin('0pt', '0pt', '0pt', '0pt')};
%     dataTableEntriesStyle = {OuterMargin('1pt', '1pt', '2pt', '2pt'), VAlign('middle'),HAlign('center')};
% 
%     dataHeader = {[],'Defect', 'Low','Elevated','High'};
%     dataBody = {Subject,[num2str(RBCOscBin1Percent,'%1.1f') '%'], [num2str(RBCOscBin2Percent,'%1.1f'), '%'],[num2str(RBCOscBin5Percent+RBCOscBin6Percent,'%1.1f') '%'],[num2str(RBCOscBin7Percent+RBCOscBin8Percent,'%1.1f') '%']};
%     if HealthyDistPresent
%         bodyContent2 = {'Ref',[num2str(HealthyData.BinPercentMeans.RBCOsc(1),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.RBCOsc(1),'%1.1f') '%'],...
%                          [num2str(HealthyData.BinPercentMeans.RBCOsc(2),'%1.1f'),'±',num2str(HealthyData.BinPercentStds.RBCOsc(2),'%1.1f') '%'],...
%                          [num2str(HealthyData.BinPercentMeans.RBCOsc(5) + HealthyData.BinPercentMeans.RBCOsc(6),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBCOsc(5),HealthyData.BinPercentStds.RBCOsc(6)]),'%1.1f') '%'],...
%                          [num2str(HealthyData.BinPercentMeans.RBCOsc(7) + HealthyData.BinPercentMeans.RBCOsc(8),'%1.1f'),'±',num2str(mean([HealthyData.BinPercentStds.RBCOsc(7),HealthyData.BinPercentStds.RBCOsc(8)]),'%1.1f') '%']};
%         dataBody = [dataBody;bodyContent2];
%     else
%         bodyContent2 = {'Ref','-','-','-','-'};
%         dataBody = [dataBody;bodyContent2];
%     end
%     table = FormalTable([dataHeader',dataBody']);
%     table.Header.Style = [table.Header.Style {Bold}];
%     table.Style = dataTableStyle;
%     table.TableEntriesStyle = [table.TableEntriesStyle dataTableEntriesStyle]; 
%     table.Header.TableEntriesHAlign = "center";
%     r = TableRow;
%     r.Style = [r.Style dataTableEntriesStyle];
%     p = Paragraph('RBC Oscillation');
%     p.Style = [p.Style dataTableEntriesStyle];
%     te = TableEntry(p);
%     te.ColSpan = 3;
%     append(r, te);
%     append(table.Header,r);
%     Defect_Entry = entry(table.Body,2,1);
%     Defect_Entry.Style = {BackgroundColor('#ff0000'), ...
%                 Bold(true) };
%     Low_Entry = entry(table.Body,3,1);
%     Low_Entry.Style = {BackgroundColor('#ffb600'), ...
%                 Bold(true) }; 
%     High2_Entry = entry(table.Body,4,1);
%     High2_Entry.Style = {BackgroundColor('#f3cdd5'), ...
%                 Bold(true) };  
%     High1_Entry = entry(table.Body,5,1);
%     High1_Entry.Style = {BackgroundColor('#c51b7d'), ...
%                 Bold(true) };  
%     table.TableEntriesHAlign = "center";
%     t = Table(2);
%     t.Style = [t.Style mainTableStyle];
%     imgStyle = {ScaleToFit(true)};
%     %Montage Figure
%     saveas(OscBinMontage,fullfile(path,'Analysis_Reports','SumOscFig.png'));
%     fig1Img = Image(fullfile(path,'Analysis_Reports','SumOscFig.png'));
%     fig1Img.Height = '7in';
%     fig1Img.Width = '7in';
%     %Histogram Figure
%     saveas(RBCOscHistFig,fullfile(path,'Analysis_Reports','OscHistFig.png'));
%     fig2Img = Image(fullfile(path,'Analysis_Reports','OscHistFig.png'));
%     fig2Img.Height = '3in';
%     fig2Img.Width = '3in';
%     row1 = TableRow;
%     row1.Style = [row1.Style {Width('11in')}];
%     % Put in Summary Figure
%     entry2 = TableEntry;
%     append(entry2,fig1Img);
%     entry2.RowSpan = 2;
%     entry2.Style = [entry2.Style {Width('7in'), Height('7in'), HAlign('center')}];
%     append(row1,entry2);
%     %Put in Histogram
%     entry1 = TableEntry;
%     append(entry1,fig2Img);
%     entry1.Style = [entry1.Style {Width('3in'), Height('3in')}];
%     entry1.RowSpan = 1;
%     append(row1,entry1);
%     append(t,row1);
%     
%     %entry2.Style = [entry2.Style {Width('3in'), HAlign('center')}];
%     row2 = TableRow;
%     row2.Style = [row2.Style {Width('11in')}];
%     entry3 = TableEntry;
%     append(entry3,table);
%     table.Style = [table.Style {Width('3in'),HAlign('center'),FontSize('12')}];
%     entry3.Style = [entry3.Style {Width('3in'), HAlign('center'),VAlign('middle')}];
%     append(row2,entry3);
%     append(t,row2);
%     %End Barrier Table Entry
% 
%     append(d,t);
%     
%     %Now, add the summary figure for global oscillations
%     sumfig = Image(fullfile(write_path,'Global_Wiggle_Summary.png'));
%     sumfig.Width = '10in';
%     sumfig.Height = '8in';
%     append(d,sumfig);
%     
%     close(d);
% 
%     %Delete image files that were written exclusively for reporting.
%     delete(fullfile(path,'Analysis_Reports','SumOscFig.png'));
%     delete(fullfile(path,'Analysis_Reports','OscHistFig.png'));
% catch
%    disp('No Clinical Report Written')
%    close(d);
% end
% 
% %% Write out data to summary excel file
% SubjectMatch = [];
% try 
%     load(fullfile(parent_path,'AncillaryFiles','AllSubjectWiggleSummary.mat'),'AllSubjectSummary');
%    %Remove for now so I can go home. Will need to figure out at some point.
%     SubjectMatch = find(strcmpi(AllSubjectSummary.Subject{1},Subject) &...
%         strcmpi(AllSubjectSummary.Scan_Date{1},scanDateStr) &...
%         strcmpi(AllSubjectSummary.AcquisitionNumber{1},num2str(num)));
% catch
%     headers = {'Subject', 'Scan_Date','AcquisitionNumber'...%Subject Info
%                 'Process_Date',...%Reconstruction Info
%                 'Global_RBC_Osc','Global_RBC_Osc_STD',...
%                 'Mean_RBC_Osc','Std_RBC_Osc',...
%                 'Mean_Bar_Osc','Std_Bar_Osc',...
%                 'Mean_RBC_Osc_Dis','Std_RBC_Osc_Dis',...
%                 'Mean_Bar_Osc_Dis','Std_Bar_Osc_Dis',...
%                 'Mean_RBC_Osc_Gas','Std_RBC_Osc_Gas',...
%                 'Mean_Bar_Osc_Gas','Std_Bar_Osc_Gas',...
%                 'Mean_New_Wiggle','Std_New_Wiggle',...
%                 };
%     AllSubjectSummary = cell2table(cell(0,size(headers,2)));
%     AllSubjectSummary.Properties.VariableNames = headers;
% end
% NewData = {Subject,scanDateStr,num2str(num),...
%             datestr(date,29),...
%             Avg_Amp,Std_Amp,...
%             RBC_Osc_Mean, RBC_Osc_Std,...
%             Bar_Osc_Mean, Bar_Osc_Std,...
%             RBC_OscDis_Mean, RBC_OscDis_Std,...
%             Bar_OscDis_Mean, Bar_OscDis_Std,...
%             RBC_OscGas_Mean, RBC_OscGas_Std,...
%             Bar_OscGas_Mean, Bar_OscGas_Std,...
%             mean(Amp(RBC_Mask(:))),std(Amp(RBC_Mask(:))),...
%             };
% if (isempty(SubjectMatch))%if no match
%     AllSubjectSummary = [AllSubjectSummary;NewData];%append
% else
%     AllSubjectSummary(SubjectMatch,:) = NewData;%overwrite
% end
% save(fullfile(parent_path,'AncillaryFiles','AllSubjectWiggleSummary.mat'),'AllSubjectSummary')
% writetable(AllSubjectSummary,excel_summary_file,'Sheet',1)
