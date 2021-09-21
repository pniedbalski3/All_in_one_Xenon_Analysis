function [biasCorrectedImage, biasField] = Vent_BiasCorrection(Image,Mask)
%% Bias field correction
% Image: image to be corrected
% Mask: Mask for correction (optional)
% biasCorrectedImage: Resulting image corrected for bias

%% Set mask if not provided
if ~exist('Mask','var')
    % second parameter does not exist, so default it to something
    Mask = ones(size(Image)); %Mask is all ones
end

%% Set location of exe and temp images
%location of N4BiasFieldCorrection
N4Path = which('Xe_Analysis.Vent_BiasCorrection');
idcs = strfind(N4Path,filesep);%determine location of file separators
N4Path = [N4Path(1:idcs(end-1)-1),filesep];%remove file

%% Export Image and Mask temporarily for use in N4
niftiwrite(abs(Image),[N4Path,'Image.nii']);%Image
niftiwrite(abs(Mask),[N4Path,'Weight.nii']);%Save mask as Weight

%% Run Bias Correction
%Main issue is drop off at top of lungs (dual loop) and RL edges (Polarean)
%Will correct for each direction independently, starting with typically least severe before doing a full correction

%AP Correction
cmd = ['"',fullfile(N4Path,'AncillaryFiles\'),'N4BiasFieldCorrection.exe"',...%run bias correction
    ' -d 3 -i "',N4Path,'Image.nii"',... % set to 3 dimensions and input image of Image.nii
    ' -s 1',... % shrink by factor of 1
    ' -w "',N4Path,'Weight.nii" ',... % import mask called Weight.nii
    ' -c [25,0]',... % convergence
    ' -b [1x1x18,2]',... % spline settings %hf, lr, ap
    ' -t [0.4,0.01,100]',... % histogram settings
    ' -o ["',N4Path,'CorrectedImage.nii","',N4Path,'Bias.nii"]']; % output corrected image and bias field
system(cmd);

%RL Correction
cmd = ['"',fullfile(N4Path,'AncillaryFiles\'),'N4BiasFieldCorrection.exe"',...%run bias correction
    ' -d 3 -i "',N4Path,'CorrectedImage.nii"',... % set to 3 dimensions and input image of Image.nii
    ' -s 1',... % shrink by factor of 1
    ' -w "',N4Path,'Weight.nii" ',... % import mask called Weight.nii
    ' -c [25,0]',... % convergence
    ' -b [1x18x1,2]',... % spline settings %hf, lr, ap
    ' -t [0.4,0.01,100]',... % histogram settings
    ' -o ["',N4Path,'CorrectedImage.nii","',N4Path,'Bias.nii"]']; % output corrected image and bias field
system(cmd);

%HF Correction
cmd = ['"',fullfile(N4Path,'AncillaryFiles\'),'N4BiasFieldCorrection.exe"',...%run bias correction
    ' -d 3 -i "',N4Path,'CorrectedImage.nii"',... % set to 3 dimensions and input image of CorrectedImage.nii
    ' -s 1',... % shrink by factor of 1
    ' -w "',N4Path,'Weight.nii" ',... % import mask called Weight.nii
    ' -c [25,0]',... % convergence
    ' -b [18x1x1,2]',... % spline settings %hf, lr, ap
    ' -t [0.4,0.01,100]',... % histogram settings
    ' -o ["',N4Path,'CorrectedImage.nii","',N4Path,'Bias.nii"]']; % output corrected image and bias field
system(cmd);

%Complete Correction
cmd = ['"',fullfile(N4Path,'AncillaryFiles\'),'N4BiasFieldCorrection.exe"',...%run bias correction
    ' -d 3 -i "',N4Path,'CorrectedImage.nii"',... % set to 3 dimensions and input image of CorrectedImage.nii
    ' -s 2',... % shrink by factor of 1
    ' -w "',N4Path,'Weight.nii" ',... % import mask called Weight.nii
    ' -c [50,0]',... % convergence
    ' -b [4x4x4,2]',... % spline settings %hf, lr, ap
    ' -t [0.2,0.01,100]',... % histogram settings
    ' -o ["',N4Path,'CorrectedImage.nii","',N4Path,'Bias.nii"]']; % output corrected image and bias field
system(cmd);

%% Import Results
biasCorrectedImage = niftiread(strcat(N4Path,"CorrectedImage.nii"));
biasField = niftiread(strcat(N4Path,"Bias.nii"));

%% Delete Temp Files
delete([N4Path,'Image.nii']);
delete([N4Path,'Weight.nii']);
delete([N4Path,'CorrectedImage.nii']);
delete([N4Path,'Bias.nii']);

end