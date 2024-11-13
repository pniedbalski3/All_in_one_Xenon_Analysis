function ct_overlay(CT,Overlay,Colormap,CLim,alpha,FileName,slice)

my_fig = figure('Name',['CT_Overlay_' FileName]);
set(my_fig,'color','white','Units','inches','Position',[0.5 0.5 12 6])
%CT = CT/prctile(CT(:),90);

%out_name = fullfile(mypath,[FileName '.tif']);
%for i = 1:size(CT,3)
i = slice;
    CT_slice = squeeze(CT(:,:,i));
    Overlay_slice = squeeze(Overlay(:,:,i));
    CT_slice = fliplr(rot90(CT_slice,-1));
    Overlay_slice = fliplr(rot90(Overlay_slice,-1));
    CT_slice = [CT_slice CT_slice];
    Overlay_slice = [zeros(size(Overlay_slice)),Overlay_slice];
   [~,~] = Tools.imoverlay(CT_slice,Overlay_slice,CLim,[-1400 200],gray,alpha,gca); %Set to CT lung window/Level
  % [~,~] = Tools.imoverlay(CT_slice,Overlay_slice,CLim,[0 1467],gray,alpha,gca);
    colormap(gca,Colormap);
    My_title = strrep(FileName,'_',' ');
    title(My_title)
    if length(Colormap) > 10
        cbar = colorbar(gca','Location','southoutside','FontSize',12);
    else
        if length(Colormap) == 3
            cbar = colorbar(gca','Location','southoutside','Ticks',[0.5 1.5 2.5],'TickLabels',{'Defect','Low','Hyper'});
        elseif length(Colormap) == 4
            cbar = colorbar(gca','Location','southoutside','Ticks',[0.5 1.5 2.5 3.5],'TickLabels',{'Bin 1','Bin 2','Bin 3','Bin 4'});
        elseif length(Colormap) == 6
            cbar = colorbar(gca','Location','southoutside','Ticks',[0.5 1.5 2.5 3.5 4.5 5.5],'TickLabels',{'Defect','Low','Normal','Normal','High','High'});
        elseif length(Colormap) == 8
            cbar = colorbar(gca','Location','southoutside','Ticks',[0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5],'TickLabels',{'Defect','Low','Normal','Normal','Elev.','Elev','High','High'});
        end
    end
%     my_frame = getframe(my_fig);
%     if i == 1
%         imwrite(my_frame.cdata,out_name);
%     else
%         imwrite(my_frame.cdata, out_name, 'WriteMode', 'append');
%     end
%     clf(gcf)
% %end

%close;