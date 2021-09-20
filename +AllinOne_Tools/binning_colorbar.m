function binning_colorbar(cbar,nbins,labels)

%cbar = colorbar(gca,'Location',location,'Ticks',[]);

locs = cbar.Position;

%need to put text box into normalized

bin_width = locs(3)/nbins;

for i = 1:nbins
    x_textloc = locs(1)+bin_width*(i-1);
    y_textloc = locs(2);
    annotation(gcf,'textbox',[x_textloc,y_textloc,bin_width locs(4)],'String',labels{i},'Units','normalized','VerticalAlignment','middle','HorizontalAlignment','center','FontName','Arial','FontSize',14,'EdgeColor','none')
   % text(x_textloc,y_textloc,labels{i},'Units','normalized','HorizontalAlignment','center','FontName','Arial','FontSize',14);
end