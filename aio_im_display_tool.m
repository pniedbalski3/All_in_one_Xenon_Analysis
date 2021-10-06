function aio_im_display_tool(path)

%Tool to display images given a subject path
%Start by closing everything
close all;

%First need to load in all my images:
%Try ventilation (don't want to break if it's not there)
%%
try
    Vent = niftiread(fullfile(path,'All_in_One_Analysis','Vent_Image.nii.gz'));
    Vent_Anat = niftiread(fullfile(path,'All_in_One_Analysis','HiRes_Anatomic.nii.gz'));
    Vent_Mask = niftiread(fullfile(path,'All_in_One_Analysis','HiRes_Anatomic_mask.nii.gz'));
    
    %Divide by 95th percentile to make pretty images
    Vent = Vent/prctile(Vent(Vent_Mask==1),95);
    
    %Now, want to pick which slice I want
    figure('Name','Ventilation Selection','Color','w','Units','normalized','Position',[.1 .1 .5 .8])
    Vent_Tile = Tools.tile_image(Vent,3);
    imagesc(Vent_Tile)
    colormap(gray)
    axis off
    caxis([0 1])
    
    s_fig = size(Vent_Tile);
    imsize_1 = size(Vent,1);
    imsize_2 = size(Vent,2);
    width_1 = s_fig(2)/imsize_1;
    height_1 = s_fig(1)/imsize_2;
    
    count = 1;
    for i = 1:height_1
        for j = 1:width_1
            xloc = 0.25*imsize_1+imsize_1*(j-1);
            yloc = 0.25*imsize_2+imsize_2*(i-1);
            text(xloc,yloc,num2str(count),'FontSize',20,'Color','r','HorizontalAlignment','center')
            count = count+1;
        end
    end
    slice_num = inputdlg('What slice do you want to display?','Slice Selection',[1 40],{num2str(imsize_1/2)});
    close;
    slice_num = str2double(slice_num{1});
    
    
    Vent_show = squeeze(Vent(:,:,slice_num));
    Anat_show = squeeze(Vent_Anat(:,:,slice_num));
    Mask_show = squeeze(Vent_Mask(:,:,slice_num));
    %Pretty blue colormap
    CMap = [linspace(0,0,256)',linspace(0,1,256)',linspace(0,1,256)'];
    
    ProtonMax = prctile(Anat_show(:),99)*1.5; %Let's make the anatomic a little darker
    figure('Name','Ventilation_Image_No_Anatomic')
    [~,~] = Tools.imoverlay(Anat_show,Vent_show,[0 1],[0,0.99*ProtonMax],gray,1,gca);
    colormap(gca,gray)
    
    %Load data:
    load(fullfile(path,'All_in_One_Analysis','Vent_Analysis_Workspace.mat'),'MALB_BF_Output','LB_BF_Output');
    %This opens up 6 figures - kill them
    close;close;close;close;close;close;
    
    
    figure('Name','Ventilation_Image_Overlay')
    [~,~] = Tools.imoverlay(Anat_show,Vent_show.*Mask_show,[0.1 1],[0,0.99*ProtonMax],CMap,1,gca);
    colormap(gca,CMap)
    
    figure('Name','Ventilation_Binned_Overlay')
    [~,~] = Tools.imoverlay(Anat_show,squeeze(LB_BF_Output.VentBinMap(:,:,slice_num)),[1 6],[0,0.99*ProtonMax],LB_BF_Output.BinMap,1,gca);
    colormap(gca,LB_BF_Output.BinMap)
    
    figure('Name','Ventilation_Threshold_Overlay')
    [~,~] = Tools.imoverlay(Vent_show,squeeze(MALB_BF_Output.VentBinMap(:,:,slice_num)),[1 3],[0,1],MALB_BF_Output.BinMap,1,gca);
    colormap(gca,MALB_BF_Output.BinMap)
catch
    disp('Something went wrong with displaying ventilation images!');
end

%% Now, Gas Exchange!
try
    Dis_Anat = niftiread(fullfile(path,'All_in_One_Analysis','LoRes_Anatomic.nii.gz'));
    Dis_Mask = niftiread(fullfile(path,'All_in_One_Analysis','LoRes_Anatomic_mask.nii.gz'));
    RBC = niftiread(fullfile(path,'All_in_One_Analysis','RBC.nii.gz'));
    Bar = niftiread(fullfile(path,'All_in_One_Analysis','Barrier.nii.gz'));
    RBC_Bin = niftiread(fullfile(path,'All_in_One_Analysis','RBC_Labeled.nii.gz'));
    Bar_Bin = niftiread(fullfile(path,'All_in_One_Analysis','Barrier_Labeled.nii.gz'));
    Dis = niftiread(fullfile(path,'All_in_One_Analysis','Dissolved_Image.nii.gz'));
    
    SixBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
    EightBinMap = [1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier

    SixBinMapA = [0 0 0; 1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 0 0.57 0.71; 0 0 1]; %Used for Vent and RBC
    EightBinMapA = [0 0 0; 1 0 0; 1 0.7143 0; 0.4 0.7 0.4; 0 1 0; 184/255 226/255 145/255; 243/255 205/255 213/255; 225/255 129/255 162/255; 197/255 27/255 125/255]; %Used for barrier

    
    ProtonMax = prctile(Dis_Anat(:),99); %Let's make the anatomic a little darker
    
     %Now, want to pick which slice I want
    figure('Name','RBC Selection','Color','w','Units','normalized','Position',[0 .1 .5 .8])
    Dis_Tile1 = Tools.tile_image(RBC_Bin,3);
    Anat_Tile = Tools.tile_image(Dis_Anat,3);
    [~,~] = Tools.imoverlay(Anat_Tile,Dis_Tile1,[1 6],[0,0.99*ProtonMax],SixBinMap,1,gca);
    colormap(gca,SixBinMap)
    
    s_fig = size(Dis_Tile1);
    imsize_1 = size(Dis,1);
    imsize_2 = size(Dis,2);
    width_1 = s_fig(2)/imsize_1;
    height_1 = s_fig(1)/imsize_2;
    
    count = 1;
    for i = 1:height_1
        for j = 1:width_1
            xloc = 0.25*imsize_1+imsize_1*(j-1);
            yloc = 0.25*imsize_2+imsize_2*(i-1);
            text(xloc,yloc,num2str(count),'FontSize',20,'Color','r','HorizontalAlignment','center')
            count = count+1;
        end
    end
    figure('Name','Barrier Selection','Color','w','Units','normalized','Position',[0.5 .1 .5 .8])
    Dis_Tile2 = Tools.tile_image(Bar_Bin,3);
    Anat_Tile = Tools.tile_image(Dis_Anat,3);
    [~,~] = Tools.imoverlay(Anat_Tile,Dis_Tile2,[1 8],[0,0.99*ProtonMax],EightBinMap,1,gca);
    colormap(gca,EightBinMap)
    
    s_fig = size(Dis_Tile1);
    imsize_1 = size(Dis,1);
    imsize_2 = size(Dis,2);
    width_1 = s_fig(2)/imsize_1;
    height_1 = s_fig(1)/imsize_2;
    
    count = 1;
    for i = 1:height_1
        for j = 1:width_1
            xloc = 0.25*imsize_1+imsize_1*(j-1);
            yloc = 0.25*imsize_2+imsize_2*(i-1);
            text(xloc,yloc,num2str(count),'FontSize',20,'Color','r','HorizontalAlignment','center')
            count = count+1;
        end
    end
    
    slice_num = inputdlg('What slice do you want to display?','Slice Selection',[1 40],{num2str(imsize_1/2)});
    close;close;
    slice_num = str2double(slice_num{1});
    
    Dis_Show = squeeze(Dis(:,:,slice_num));
    RBC_Show = squeeze(RBC(:,:,slice_num));
    RBCBin_Show = squeeze(RBC_Bin(:,:,slice_num));
    Bar_Show = squeeze(Bar(:,:,slice_num));
    BarBin_Show = squeeze(Bar_Bin(:,:,slice_num));
    GEVent_Show = squeeze(Vent(:,:,slice_num));
    DisAnat_Show = squeeze(Dis_Anat(:,:,slice_num));
    DisMask_Show = squeeze(Dis_Mask(:,:,slice_num));
    
    ProtonMax = prctile(DisAnat_Show(:),99)*1.5; %Let's make the anatomic a little darker

    figure('Name','RBC_Image_No_Anatomic')
    [~,~] = Tools.imoverlay(DisAnat_Show,abs(RBC_Show/prctile(RBC_Show(DisMask_Show==1),99)),[0 1],[0,0.99*ProtonMax],gray,1,gca);
    colormap(gca,gray)
    
    figure('Name','Bar_Image_No_Anatomic')
    [~,~] = Tools.imoverlay(DisAnat_Show,abs(Bar_Show/prctile(Bar_Show(DisMask_Show==1),99)),[0 1],[0,0.99*ProtonMax],gray,1,gca);
    colormap(gca,gray)
    
    figure('Name','Dis_Image_No_Anatomic')
    [~,~] = Tools.imoverlay(DisAnat_Show,Dis_Show/prctile(Dis_Show(DisMask_Show==1),99),[0 1],[0,0.99*ProtonMax],gray,1,gca);
    colormap(gca,gray)
    
    figure('Name','Binned_RBC')
    [~,~] = Tools.imoverlay(DisAnat_Show,RBCBin_Show,[1 6],[0,0.99*ProtonMax],SixBinMap,1,gca);
    colormap(gca,SixBinMap)
    
    figure('Name','Binned_Barrier')
    [~,~] = Tools.imoverlay(DisAnat_Show,BarBin_Show,[1 8],[0,0.99*ProtonMax],EightBinMap,1,gca);
    colormap(gca,EightBinMap)
    
catch
    disp('Something went wrong with displaying Gas Exchange images!');
end
    
if ~isfolder(fullfile(path,'All_in_One_Rep_Figs'))
    mkdir(fullfile(path,'All_in_One_Rep_Figs'))
end
curpath = pwd;
cd(fullfile(path,'All_in_One_Rep_Figs'));
save_all_figs('FileType','-djpeg');
cd(curpath);

