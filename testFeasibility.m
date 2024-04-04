clearvars
clc

%reader = BioformatsImage('D:\Documents\OneDrive - UCB-O365\Projects\2024 Hill\cdubvGF_101623\2023_10_16__0013.czi');
reader = BioformatsImage('C:\Users\Jian Tay\OneDrive - UCB-O365\Projects\2024 Hill\cdubvGF_101623\2023_10_16__0013.czi');

numTiles = [25, 25];

maskTissueFull = false(reader.height, reader.width);
maskIsletsFull = false(reader.height, reader.width);

tStart = tic;
for ii = 160%1:prod(numTiles)

    % Ired = getPlane(reader, 1, 1, 1, 'ROI', [10000, 10000, 1000, 1000]);
    % Igreen = getPlane(reader, 1, 2, 1, 'ROI', [10000, 10000, 1000, 1000]);
    % Iblue = getPlane(reader, 1, 3, 1, 'ROI', [10000, 10000, 1000, 1000]);

    [Ired, rect] = getTile(reader, 1, 1, 1, numTiles, ii);
    Igreen = getTile(reader, 1, 2, 1, numTiles, ii);
    Iblue = getTile(reader, 1, 3, 1, numTiles, ii);

    Irgb = cat(3, Ired, Igreen, Iblue);

    imshow(Irgb,[])

    %%

    %Target RGB color of islets as a 1x1x3 vector.
    spotColorRGB = cat(3, 92, 63, 33);

    %Convert the spot RGB color to L*a*b color (Note: The RGB color has to be
    %an unsigned 8-bit integer to match the original data).
    spotColorLab = rgb2lab(uint8(spotColorRGB));

    tissueColorRGB = cat(3, 188, 185, 167);
    tissueColorLab = rgb2lab(uint8(tissueColorRGB));

    %Convert the image into Lab color space
    labImg = rgb2lab(Irgb);

    %Index the a* and b* colors
    aa = labImg(:, :, 2);
    bb = labImg(:, :, 3);

    %Find similar colors in the image to the spot above
    maskIslets = (aa - spotColorLab(2)).^2 + (bb - spotColorLab(3)).^2 <= 10^2;
    maskIslets = bwareaopen(maskIslets, 5);
   
    %imshow(maskIslets)

    % maskTissue = (aa - tissueColorLab(2)).^2 + (bb - tissueColorLab(3)).^2 <= 20^2;
    % maskTissue = imopen(maskTissue, strel('disk', 3));

    maskTissue = Igreen < 190 & Igreen > 5;
    %maskTissue = imclose(maskTissue, strel('disk', 10));
    imshowpair(Irgb, maskTissue)

    maskTissueFull(rect(2):(rect(2)+rect(4) - 1), rect(1):(rect(1)+rect(3) - 1)) = maskTissue;
    maskIsletsFull(rect(2):(rect(2)+rect(4) - 1), rect(1):(rect(1)+rect(3) - 1)) = maskIslets;
    
    % figure(1)
    % subplot(1, 3, 1)
    % imshow(Irgb)
    % subplot(1, 3, 2)
    % imshowpair(Irgb, maskIslets)
    % subplot(1, 3, 3)
    % imshowpair(Irgb, maskTissue)
end
toc(tStart)

% imwrite(maskIsletsFull, 'test_isletMask.tif', 'Compression', 'none');
% imwrite(maskTissueFull, 'test_tissueMask.tif', 'Compression', 'none');