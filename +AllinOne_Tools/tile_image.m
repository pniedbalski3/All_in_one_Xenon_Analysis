function Tiled_Image = tile_image(Image,Dimension,varargin)

%This function will take in a 3D image and separate it into a tiled image
%showing slices of the dimension specified by the user. I also want to have
%an option for specifying the number of rows or number of columns
%Current Optional Arguments (which need to be provided in the same way that
%plot uses things
%'nRows' - Specify the number of rows in the tile plot
%'nColumns' - Specify the number of columns in the tile plot
%'Name' - Give the figure a name, default is 'Tile Image'
%'ColorMap' - Give the figure a colormap - default is gray
%'ZeroOffset' - Make the added blank matrices a value other than zero
%'StartIndex' - Start the tiling at a certain slice
%'EndIndex' - End the tiling at a certain slice


%Make sure that dimension was passed correctly:
if Dimension ~= 1 && Dimension ~= 2 && Dimension ~=3
    display('Error: Dimension must equal 1, 2, or 3');
    return;
end

%If images are passed as complex numbers, I just want magnitude. Otherwise,
%I don't want to do anything to them
if ~isreal(Image)
    Image = abs(Image);
end
%Find the size of each of the dimensions
ImageSize = size(Image);
StartIndex = 1;
EndIndex = ImageSize(Dimension);

%Declare these variables
nRows = 0;
nColumns = 0;
name = 'Tile Image';
cmap = gray;
ZeroOffset = 0;
if nargin > 2
    if ~isempty(find(strcmp(varargin,'StartIndex'),1))
        StartIndex = varargin{find(strcmp(varargin,'StartIndex'),1)+1};
    end
    if ~isempty(find(strcmp(varargin,'EndIndex'),1))
        EndIndex = varargin{find(strcmp(varargin,'EndIndex'),1)+1};
    end
end

%Set nRows and nColumns - They will be reset if user sends different values
nRows = floor(sqrt(EndIndex-StartIndex+1));
nColumns = ceil((EndIndex-StartIndex+1)/nRows);
%Want to find out which optional arguments the user put in
if nargin>2
    
    if ~isempty(find(strcmp(varargin,'nRows'),1))
        nRows = double(varargin{find(strcmp(varargin,'nRows'),1)+1});
        nColumns = ceil((EndIndex-StartIndex+1)/nRows);
    end
    if ~isempty(find(strcmp(varargin,'nColumns'),1))
        nColumns = double(varargin{find(strcmp(varargin,'nColumns'),1)+1});
        nRows = ceil((EndIndex-StartIndex+1)/nColumns);
    end
    if ~isempty(find(strcmp(varargin,'Name'),1))
        name = varargin{find(strcmp(varargin,'Name'),1)+1};
    end
    if ~isempty(find(strcmp(varargin,'ColorMap'),1))
        cmap = varargin{find(strcmp(varargin,'ColorMap'),1)+1};
    end
    if ~isempty(find(strcmp(varargin,'ZeroOffset'),1))
        ZeroOffset = varargin{find(strcmp(varargin,'ZeroOffset'),1)+1};
    end
    
end

RowCells = cell(1,nRows);
if Dimension==1
    for i = 1:nRows
        row = [];
        for j = 1:nColumns
            if ((i-1)*nColumns+j+StartIndex-1)<=EndIndex
                slice1 = rot90(squeeze(Image((i-1)*nColumns+j+StartIndex-1,:,:)),-1);
                row = [row slice1];
            end
        end
        RowCells{i} = row;
    end
elseif Dimension==2
    for i = 1:nRows
        row = [];
        for j = 1:nColumns
            if ((i-1)*nColumns+j+StartIndex-1)<=EndIndex
                slice1 = squeeze(Image(:,(i-1)*nColumns+j+StartIndex-1,:));
                row = [row slice1];
            end
        end
        RowCells{i} = row;
    end
elseif Dimension==3
    for i = 1:nRows
        row = [];
        for j = 1:nColumns
            if ((i-1)*nColumns+j+StartIndex-1)<=EndIndex
                %slice1 = squeeze(Image(:,:,(i-1)*nColumns+j+StartIndex-1));
                slice1 = squeeze(Image(:,:,(i-1)*nColumns+j+StartIndex-1));
                %slice1 = fliplr(rot90(squeeze(Image(:,:,(i-1)*nColumns+j+StartIndex-1)),-1));
                row = [row slice1];
            end
        end
        RowCells{i} = row;
    end
end

RowSize = ImageSize(1)*nColumns;

finalimage = [];
for i = 1:nRows
    %Pull rows out of cell
    thisrow = double(RowCells{i});
    %make sure the row size is what it should be, if not, pad with the
    %value defined by ZeroOffset
    if size(thisrow,2)~=RowSize
        zeromat = ones(size(thisrow,1),RowSize-size(thisrow,2))*ZeroOffset;
        thisrow = [thisrow zeromat];
    end
    finalimage = cat(1,finalimage,thisrow);
end

% figure('Name',name)
% imagesc(finalimage)
% colormap(cmap)
% axis off

Tiled_Image = finalimage;

        


