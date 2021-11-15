function Image = all_in_one_canonical_orientation(In_Image)

%Function to rotate images from all-in-one images to the proper, canonical
%orientation.

Image = permute(In_Image,[2,3,1]);
Image = flip(Image,3);
Image = flipud(Image);