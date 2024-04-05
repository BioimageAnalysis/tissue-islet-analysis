clearvars
clc

IisletMask = imread('D:\Documents\OneDrive - UCB-O365\Shared\Shared with Hill Lab\test_isletMask.tif');

IisletMask = imopen(IisletMask, strel('disk',5));
IisletMask = imclose(IisletMask, strel('disk',10));
IisletMask = bwareaopen(IisletMask, 15);

ItisseMask = imread('D:\Documents\OneDrive - UCB-O365\Shared\Shared with Hill Lab\test_tissueMask.tif');

imagePath = 'D:\Documents\OneDrive - UCB-O365\Projects\2024 Hill\cdubvGF_101623\2023_10_16__0013.czi';

%%
%Measure properties from mask
data = regionprops(IisletMask, 'Circularity', 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');

histogram([data.Circularity])

%How to visualize?
%%
%Display some examples
reader = BioformatsImage(imagePath);
%%
rngIdx = randsample(numel(data), 6);

figure;
for ii = 1:numel(rngIdx)

    subplot(2, 3, ii)
    
    bb = data(rngIdx(ii)).BoundingBox;
    bb(1:2) = bb(1:2) - 50;
    bb(3:4) = bb(3:4) + 100;
    bb = round(bb);

    Ired = getPlane(reader, 1, 1, 1, 'ROI', bb);
    Igreen = getPlane(reader, 1, 2, 1, 'ROI', bb);
    Iblue = getPlane(reader, 1, 3, 1, 'ROI', bb);

    currMask = false(size(IisletMask));
    currMask(data(rngIdx(ii)).PixelIdxList) = true;

    currMask = currMask(bb(2):(bb(2)+bb(4) - 1), bb(1):(bb(1)+bb(3) - 1) );

    allMask = IisletMask(bb(2):(bb(2)+bb(4) - 1), bb(1):(bb(1)+bb(3) - 1) );

    Irgb = cat(3, Ired, Igreen, Iblue);

    Iout = showoverlay(Irgb, bwperim(currMask));
    showoverlay(Irgb, bwperim(currMask), 'Color', [1 0 1])

end

