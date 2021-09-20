function [center,first,last] = getimcenter(Mask)

sumslice = zeros(size(Mask,3));
for i = 1:size(Mask,3)
    slice = Mask(:,:,i);
    sumslice(i) = sum(slice(:));
end

nonzeros = find(sumslice);

first = min(nonzeros);
last = max(nonzeros);

center = first + floor((last-first)/2);
