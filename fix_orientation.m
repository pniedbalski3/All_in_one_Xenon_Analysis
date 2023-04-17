function fix_orientation(mypath)

files = dir(mypath);
files = struct2cell(files);
files = files(1,:);

for lcv = 1:length(files)
    tmp_file = files{lcv};
    if contains(tmp_file,'.nii.gz') && ~contains(tmp_file,'warped')
        im = double(niftiread(fullfile(mypath,tmp_file)));
        nii_info = AllinOne_Tools.nifti_metadata(im,400/size(im,1),400);
        tmp_file = erase(tmp_file,'.nii.gz');
        niftiwrite(im,fullfile(mypath,tmp_file),nii_info,'Compressed',true)
    end
end