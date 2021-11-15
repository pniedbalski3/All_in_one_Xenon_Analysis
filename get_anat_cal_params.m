function [H1_Raw,H1_Traj,Cal_Raw,Params] = get_anat_cal_params(xe_file,h1_file,cal_file)

parent_path = which('get_anat_cal_params');
idcs = strfind(parent_path,filesep);%determine location of file separators
parent_path = parent_path(1:idcs(end)-1);%remove file

Xe_Dat_twix = AllinOne_DataImport.mapVBVD(xe_file,'ignoreSeg');

Seq_Name = Xe_Dat_twix.hdr.Config.SequenceFileName;
Params.imsize = Xe_Dat_twix.hdr.MeasYaps.sKSpace.lBaseResolution;
Params.TR = ((Xe_Dat_twix.hdr.MeasYaps.alTR{1}+Xe_Dat_twix.hdr.MeasYaps.alTR{2})/1000);
Params.TE = (Xe_Dat_twix.hdr.MeasYaps.alTE{1}/1000);
Params.GasFA = Xe_Dat_twix.hdr.MeasYaps.adFlipAngleDegree{2};
Params.DisFA = Xe_Dat_twix.hdr.MeasYaps.adFlipAngleDegree{1};
Params.freq_offset = Xe_Dat_twix.hdr.MeasYaps.sWipMemBlock.alFree{5};
Params.Dwell = Xe_Dat_twix.hdr.MeasYaps.sRXSPEC.alDwellTime{1,1}*1e-9;
scanDate = Xe_Dat_twix.hdr.Phoenix.tReferenceImage0; 
scanDate = strsplit(scanDate,'.');
scanDate = scanDate{end};
scanDateStr = [scanDate(1:4),'-',scanDate(5:6),'-',scanDate(7:8)];
Params.scandatestr = scanDateStr;

H1_Dat_twix = AllinOne_DataImport.mapVBVD(h1_file,'ignoreSeg');
H1_Dat_twix.flagIgnoreSeg = 1;
H1_Dat_twix.image.flagIgnoreSeg = 1;

H1_Raw1 = squeeze(double(H1_Dat_twix.image()));

%This gets written out as npts x ncoils x npro - need to permute
H1_Raw = permute(H1_Raw1,[1 3 2]);

%While dealing with this, get the H1 image size
Params.imsizeH1 = H1_Dat_twix.hdr.MeasYaps.sKSpace.lBaseResolution;


H1_Hubs = H1_Dat_twix.hdr.MeasYaps.sWipMemBlock.alFree{2}; %Number of hubs for 1H image
H1_Alpha = H1_Dat_twix.hdr.MeasYaps.sWipMemBlock.adFree{3}; %Alpha for 1H image
H1_Ordering = H1_Dat_twix.hdr.MeasYaps.sWipMemBlock.alFree{5}; %Ordering Scheme for 1H image (Golden Means)
H1_Pro = size(H1_Raw,2); %I could also get this from twix, but this is just as easy.
H1_ImSize = H1_Dat_twix.hdr.MeasYaps.sKSpace.lBaseResolution; %Desired Output Image Size
H1_Dim = 1; %Dimension - 1 means 3D - I hate to hardcode, but this will always be 3D, so it's fine

%Hardcode for now:
H1_traj_file = fullfile(parent_path,'Traj_Files','Vent_GasEx_Anatomic_20210819_Traj.dat');

H1_Traj = AllinOne_DataImport.spiral_coords_from_dat(H1_traj_file,H1_Ordering,H1_Dim,H1_Alpha,H1_Hubs,H1_Pro);
%% Calibration
Cal_Dat_twix = AllinOne_DataImport.mapVBVD(cal_file);
nFids = Cal_Dat_twix.hdr.Config.NRepMeas;
te = Cal_Dat_twix.hdr.Phoenix.alTE{1}; 
dwell_time = Cal_Dat_twix.hdr.MeasYaps.sRXSPEC.alDwellTime{1,1}*1e-9;
theFID = squeeze(double(Cal_Dat_twix.image()));
if nFids > 100 %If we have a lot of FIDs, that means we're using the old version of the calibration
    nDis = 100;
    disData = theFID(:,101:(100+nDis)); % Throw out first 100 points for old calibration
else
    nDis = 13; %use all data for new calibration
    disData = theFID(:,1:nDis);
end

%Average all dissolved data (to accomodate possible differences among
%calibration sequences
disData_avg = mean(disData,2);
% Spec_Post = nan;
% if ~prod(isnan(Spec_Post))
%     Spec_Post = transpose(Spec_Post);
%     disData_avg = mean(Spec_Post,2); 
%     dwell_time = Xe_Dat_twix.hdr.MeasYaps.sWipMemBlock.adFree{15}*1e-6/2; %Off by a factor of 2 - Probably due to readout oversampling?
%     te = Params.TE;
% end

Cal_Raw.data = disData_avg;
Cal_Raw.dwell = dwell_time;
