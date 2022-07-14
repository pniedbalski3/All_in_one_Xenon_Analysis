function [H_Map,H_Index] = xe_vent_heterogeneity(Image,Mask,L)

%Function to calculate heterogeneity map and Heterogeneity Index from
%ventilation images. Follows description here: 
% Tzeng, Lutchen, Albert, J Appl Physiol 2009; 106, 813-822

%I should probably add just simple calculation of coefficient of variation
%within the ventilated volume, but this is a good start.

%We'll have to optimize L. For now, let's do a cube with length 5 voxels
%centered on a given point
%L = 5; 

Noise_Mask = imerode(~Mask,strel('sphere',7));%avoid edges/artifacts/partialvolume

Noise_Mean = mean(Image(Noise_Mask));
Noise_STD = std(Image(Noise_Mask));

zero_mat = zeros(size(Image));
H_Map = zeros(size(Image));
%Probably faster ways to do this, but for now do the easy thing:
for i = 1:size(Image,1)
    for j = 1:size(Image,2)
        for k = 1:size(Image,3)
            if Mask(i,j,k)
                %Get a cube mask centered on the voxel of interest
                Cube = zero_mat;
                [X,Y,Z] = meshgrid((i-((L-1)/2)):(i+((L-1)/2)),(j-((L-1)/2)):(j+((L-1)/2)),(k-((L-1)/2)):(k+((L-1)/2)));
                Cube(X,Y,Z) = 1;
                %Remove cube points that aren't in mask
                Cube = Cube.*Mask;
                
                Mean_Sig_ROI = mean(Image(Cube==1));
                SD_Sig_ROI = std(Image(Cube==1));
                
                SNR_ROI = (Mean_Sig_ROI - Noise_Mean)/Noise_STD;
                
                if SNR_ROI > 5
                    H_Map(i,j,k) = SD_Sig_ROI/Mean_Sig_ROI;
                end
            end
        end
    end
end

H_Index = mean(H_Map(H_Map~=0));
                
                


