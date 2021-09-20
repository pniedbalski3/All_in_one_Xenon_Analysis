function [VentMask,DisMask] = all_in_one_masking(write_path)

if isfile(fullfile(write_path,'Manual_Dis_Mask.nii.gz'))
    DisMask = niftiread(fullfile(write_path,'Manual_Dis_Mask.nii.gz'));
else
    try
        AllinOne_Seg.CNN_Seg(fullfile(write_path,'LoRes_Anatomic.nii.gz'));
        DisMask = niftiread(fullfile(write_path,'LoRes_Anatomic_mask.nii.gz'));
    catch
        try
            DisMask = niftiread(fullfile(write_path,'LoRes_Anatomic_mask.nii.gz'));
        catch
            DisMask = nan;
        end
    end
end
if isfile(fullfile(write_path,'Manual_Vent_Mask.nii.gz'))
    DisMask = niftiread(fullfile(write_path,'Manual_Vent_Mask.nii.gz'));
else
    try
        AllinOne_Seg.CNN_Seg(fullfile(write_path,'HiRes_Anatomic.nii.gz'));
        VentMask = niftiread(fullfile(write_path,'HiRes_Anatomic_mask.nii.gz'));
    catch
        try
            VentMask = niftiread(fullfile(write_path,'HiRes_Anatomic_mask.nii.gz'));
        catch
            VentMask = nan;
        end
    end
end