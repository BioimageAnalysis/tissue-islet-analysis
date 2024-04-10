clearvars
clc

% IisletMask = imread('D:\Documents\OneDrive - UCB-O365\Shared\Shared with Hill Lab\test_isletMask.tif');
% 
% IisletMask = imopen(IisletMask, strel('disk',5));
% IisletMask = imclose(IisletMask, strel('disk',10));
% IisletMask = bwareaopen(IisletMask, 15);

load('20240405data.mat')
IisletMask = L;

ItisseMask = imread('D:\Documents\OneDrive - UCB-O365\Shared\Shared with Hill Lab\test_tissueMask.tif');

imagePath = 'D:\Documents\OneDrive - UCB-O365\Projects\2024 Hill\cdubvGF_101623\2023_10_16__0013.czi';

%Display some examples
reader = BioformatsImage(imagePath);
%%
%Measure properties from mask
data = regionprops(IisletMask, 'Circularity', 'Area', 'Centroid', 'BoundingBox', 'PixelIdxList');

%%
%Filter any regions with small areas
dataFilt = data;
dataFilt([data.Area] < 1500) = [];

% histogram([data.Area], 100)

rngIdx = randsample(numel(dataFilt), 6);

figure;
for ii = 1:numel(rngIdx)

    subplot(2, 3, ii)
    
    bb = dataFilt(rngIdx(ii)).BoundingBox;
    bb(1:2) = bb(1:2) - 50;
    bb(3:4) = bb(3:4) + 100;
    bb = round(bb);

    Ired = getPlane(reader, 1, 1, 1, 'ROI', bb);
    Igreen = getPlane(reader, 1, 2, 1, 'ROI', bb);
    Iblue = getPlane(reader, 1, 3, 1, 'ROI', bb);

    Irgb = cat(3, Ired, Igreen, Iblue);

    labImg = rgb2lab(Irgb);
    
    currMask = false(size(IisletMask));
    currMask(dataFilt(rngIdx(ii)).PixelIdxList) = true;

    currMask = currMask(bb(2):(bb(2)+bb(4) - 1), bb(1):(bb(1)+bb(3) - 1) );

    meanLightness = mean(mean(labImg(:, :, 1) .* currMask));
    meanColor = mean(mean(labImg(:, :, 1) .* currMask));

    %Mean RGB intensity - (0.21 × R) + (0.72 × G) + (0.07 × B) for
    %perceived brightness?
    %r

    %allMask = IisletMask(bb(2):(bb(2)+bb(4) - 1), bb(1):(bb(1)+bb(3) - 1) );

    %Should we refine to include regions of a similar color nearby?

    Irgb = cat(3, Ired, Igreen, Iblue);

    Iout = showoverlay(Irgb, bwperim(currMask));
    showoverlay(Irgb, bwperim(currMask), 'Color', [1 0 1])
    title(sprintf('Lightness: %.3f', meanLightness))

end

