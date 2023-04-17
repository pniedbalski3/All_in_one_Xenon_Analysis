function Image_Out = Dissolved_Phase_LowResRecon(ImageSize,data,traj,PixelShift)

% Uses Scott Robertson's reconstruction code - This just makes it more
% modular and easy to implement - This is for 3D data
% 
% ImageSize - Scalar: Output image matrix size
%
% data - KSpace Data in (N_ro x N_Proj)
%
% traj - point in kspace corresponding to the data vector - columns for
% x,y, and z. (3 x N_ro x N_Proj)
%
% PixelShift - array of size 3 with pixels to shift by [a(-)p(+), h(+)f(-), r(+)l(-)]

%Let's kill all points too large to be included
rad = sqrt(traj(:,1).^2+traj(:,2).^2+traj(:,3).^2);
toobig = find(rad>0.5);
data(toobig) = [];
traj(toobig,:) = [];

%  Settings
kernel.sharpness = 0.14;
kernel.extent = 9*kernel.sharpness;
overgrid_factor = 3;
output_image_size = ImageSize*[1 1 1];
nDcfIter = 15;
deapodizeImage = false();%true();
cropOvergriddedImage = true();
verbose = true();
if exist('PixelShift','var')==0%if not passed, set to 0's
    PixelShift = [0, 0, 0];
end

%  Transform Data/Traj to Nx1 and Nx3
traj_redim = traj;%[reshape(traj(1,:,:),1,[])' reshape(traj(2,:,:),1,[])' reshape(traj(3,:,:),1,[])'];
data_redim = data;%reshape(data(:,:),1,[])';

%   Remove NaNs from data and traj (particularly for keyhole images but
%   should have no affect on other images
Nans = find(isnan(data_redim));
data_redim(Nans) = [];
traj_redim(Nans,:) = [];    

%  Choose kernel, proximity object, and then create system model
kernelObj = Reconstruction.Recon.SysModel.Kernel.Gaussian(kernel.sharpness, kernel.extent, verbose);
proxObj = Reconstruction.Recon.SysModel.Proximity.L2Proximity(kernelObj, verbose);
clear kernelObj;
systemObj = Reconstruction.Recon.SysModel.MatrixSystemModel(traj_redim, overgrid_factor, ...
    output_image_size, proxObj, verbose);

% Choose density compensation function (DCF)
dcfObj = Reconstruction.Recon.DCF.Iterative(systemObj, nDcfIter, verbose);

% Choose Reconstruction Model
reconObj = Reconstruction.Recon.ReconModel.LSQGridded(systemObj, dcfObj, verbose);
clear modelObj;
clear dcfObj;
%reconObj.PixelShift = PixelShift;
reconObj.crop = cropOvergriddedImage;
reconObj.deapodize = deapodizeImage;

% Reconstruct image
Image_Out = reconObj.reconstruct(data_redim, traj_redim);

%Image_Out = permute(Image_Out,[2 3 1]);
