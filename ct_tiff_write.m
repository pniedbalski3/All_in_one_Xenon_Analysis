function ct_tiff_write(CT,Overlay,Colormap,CLim,alpha,FileName,mypath)

my_fig = figure('Name',['CT_Overlay_' FileName]);
CT = CT/prctile(CT(:),90);

out_name = fullfile(mypath,[FileName '.tif']);
for i = 1:size(CT,3)
    CT_slice = squeeze(CT(:,:,i));
    Overlay_slice = squeeze(Overlay(:,:,i));
    CT_slice = fliplr(rot90(CT_slice,-1));
    Overlay_slice = fliplr(rot90(Overlay_slice,-1));
    [~,~] = Tools.imoverlay(CT_slice,Overlay_slice,CLim,[-13.8243 3.3274],gray,alpha,gca);
    colormap(gca,Colormap);
    my_frame = getframe(my_fig);
    if i == 1
        imwrite(my_frame.cdata,out_name);
    else
        imwrite(my_frame.cdata, out_name, 'WriteMode', 'append');
    end
    clf(gcf)
end

close;