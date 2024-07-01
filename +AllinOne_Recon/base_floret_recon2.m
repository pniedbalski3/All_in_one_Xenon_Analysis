function [Image_Out,kspace] = base_floret_recon2(ImageSize,data,traj)
%% A Function written to reconstruct Images when K-space data and trajectories are passed to it
% Uses Scott Robertson's reconstruction code - This just makes it more
% modular and easy to implement - This is for 3D data
% 
% ImageSize - Output image matrix size -If Scalar, Isotropic ImageSize
%                                       Can specify x, y, and z dimensions
%                                       by passing 3-vector
%
% data - KSpace Data in column vector (N x 1)
%
% traj - point in kspace corresponding to the data vector - columns for
% x,y, and z. (N x 3)
%
% Outputs Reconstructed Image and Gridded K-space


%Make sure ImageSize is Meaningful
if numel(ImageSize)==1
   ImageSize = [ImageSize(1) ImageSize(1) ImageSize(1)]; 
elseif numel(ImageSize) ~= 3
   error('ImageSize needs to be either a scalar or 3-d vector.'); 
end

kernel.sharpness = 0.3;
kernel.extent = 9*kernel.sharpness;
overgrid_factor = 2;
output_image_size = ImageSize;
nDcfIter = 10;
deapodizeImage = false; 
nThreads = 10;
cropOvergriddedImage = true();
verbose = true();

%% Save the important parameters
%  Choose kernel, proximity object, and then create system model
kernelObj = Reconstruction.Recon.SysModel.Kernel.Gaussian(kernel.sharpness, kernel.extent, verbose);
%kernelObj = Recon.SysModel.Kernel.KaiserBessel(kernel.sharpness, kernel.extent, verbose);
%kernelObj = Recon.SysModel.Kernel.Sinc(kernel.sharpness, kernel.extent, verbose);

proxObj = Reconstruction.Recon.SysModel.Proximity.L2Proximity(kernelObj, verbose);
%proxObj = Recon.SysModel.Proximity.L1Proximity(kernelObj, verbose);
clear kernelObj;
systemObj = Reconstruction.Recon.SysModel.MatrixSystemModel(traj, overgrid_factor, ...
    output_image_size, proxObj, verbose);

% Choose density compensation function (DCF)
dcfObj = Reconstruction.Recon.DCF.Iterative(systemObj, nDcfIter, verbose);
%dcfObj = Recon.DCF.Voronoi(traj, header, verbose);
%dcfObj = Recon.DCF.Analytical3dRadial(traj, verbose);
%dcfObj = Recon.DCF.Unity(traj, verbose);

% Choose Reconstruction Model
reconObj = Reconstruction.Recon.ReconModel.LSQGridded(systemObj, dcfObj, verbose);
clear modelObj;
clear dcfObj;
reconObj.crop = cropOvergriddedImage;
reconObj.deapodize = deapodizeImage;

% Reconstruct image using trajectories in pixel units
[Image_Out,kspace] = reconObj.reconstruct(data, traj); 
%Image_Out = rot90(flip(Image_Out));

