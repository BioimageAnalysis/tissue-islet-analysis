classdef IsletAnalyzer
%ISLETANALYZER  Analyze histological images to identify islets
%
%  IA = ISLETANALYZER will create a new ISLETANALYZER object.

properties

    isletRGB = [92, 63, 33];
    isletMatchRange = 12;
    tissueGrange = [5, 190];  %Green intensity for tissue

    numTiles = [25, 25];
    minIsletAreaPx = 500;

end

methods

    function processImages(obj, files, outputDir)
        %PROCESSIMAGES  Identifies and measures
        
        %Parse the inputs
        if ~iscell(files)

            files = {files};

        end

        %Convert the target RGB colors into Lab color space. Note:
        %Currently assuming that data is uint8.
        isletRGB = reshape(obj.isletRGB, 1, 1, 3);
        isletLab = rgb2lab(uint8(isletRGB));

        for iFile = 1:numel(files)

            %Get file path and name
            [fpath, fname] = fileparts(files{iFile});

            %Print progress statement
            fprintf('%s - Processing file %s (%.0f/%.0f)\n', ...
                datetime, fname, iFile, numel(files));
            
            %Create a BioformatsImage object to read image file
            reader = BioformatsImage(files{iFile});

            %Initialize matrices to store output
            maskTissueFull = false(reader.height, reader.width);
            maskIsletsFull = false(reader.height, reader.width);

            imageOut = zeros(ceil(reader.height/10), ceil(reader.width/10), 3, 'uint8');

            for ii = 1:prod(obj.numTiles)

                %Read in image by parts
                Igreen = getTile(reader, 1, 2, 1, obj.numTiles, ii);

                %Skip tile if there is no information to save time
                if all(Igreen == 0, 'all')
                    continue;
                end

                [Ired, rect] = getTile(reader, 1, 1, 1, obj.numTiles, ii);
               
                Iblue = getTile(reader, 1, 3, 1, obj.numTiles, ii);

                %Generate RGB image and convert to Lab color space
                Irgb = cat(3, Ired, Igreen, Iblue);
                labImg = rgb2lab(Irgb);

                %Find islets by matching color
                maskIslets = ((labImg(:, :, 2) - isletLab(2)).^2 + (labImg(:, :, 3) - isletLab(3)).^2) <= (obj.isletMatchRange)^2;
                maskIslets = bwareaopen(maskIslets, 10); %Remove regions < 5 pixels in size

                %Find tissue
                maskTissue = Igreen > min(obj.tissueGrange) & Igreen < max(obj.tissueGrange);
                maskTissue = imclose(maskTissue, strel('disk', 7));

                %Store masks
                maskIsletsFull(rect(2):(rect(2)+rect(4) - 1), rect(1):(rect(1)+rect(3) - 1)) = maskIslets;
                maskTissueFull(rect(2):(rect(2)+rect(4) - 1), rect(1):(rect(1)+rect(3) - 1)) = maskTissue;

                %Shrink image by 10x
                Iout = imresize(Irgb, 0.1);

                rowOutResized = ceil(rect(2)/10);
                colOutResized = ceil(rect(1)/10);
                imageOut( rowOutResized:(rowOutResized + size(Iout, 1) - 1), ...
                    colOutResized:(colOutResized + size(Iout, 2) - 1), :) = Iout;

                % figure(1)
                % subplot(1, 3, 1)
                % imshow(Irgb)
                % subplot(1, 3, 2)
                % imshowpair(Irgb, maskIslets)
                % subplot(1, 3, 3)
                % imshowpair(Irgb, maskTissue)
            end

            %--Clean up the final masks--%

            %Clean up tissue mask
            maskTissueFull = imclose(maskTissueFull, strel('disk', 10));
            maskTissueFull = bwareaopen(maskTissueFull, 10000);

            %Group and label the islet masks
            maskIsletsFullTMP = imclose(maskIsletsFull, strel('disk', 75));
            % % maskIsletsFullTMP = imopen(maskIsletsFullTMP, strel('disk', 25));
            %maskIsletsFullTMP = imdilate(maskIsletsFull, strel('disk', 10));

            %maskIsletsFullTMP = bwareaopen(maskIsletsFullTMP, 500);

            isletLabels = bwlabel(maskIsletsFullTMP);
            isletLabels = uint16(isletLabels .* maskIsletsFull .* maskTissueFull);

            %--- Analyze islet regions ---%

            isletData = regionprops(maskIsletsFull, 'Circularity', 'Area', 'Centroid', 'BoundingBox', 'Image', 'PixelIdxList');

            isletDataFilt = isletData;
            isletDataFilt([isletData.Area] < obj.minIsletAreaPx) = [];

            %Remake the isletLabels matrix to only include filtered data
            isletLabels = zeros(size(isletLabels), 'uint16');

            %Analyze individual islets
            for ii = 1:numel(isletDataFilt)

                %Update the label image
                isletLabels(isletDataFilt(ii).PixelIdxList) = ii;

                %Get the image for each islet
                bb = isletDataFilt(ii).BoundingBox;
                bb(1:2) = bb(1:2) - 50;
                bb(3:4) = bb(3:4) + 100;
                bb = round(bb);

                Ired = getPlane(reader, 1, 1, 1, 'ROI', bb);
                Igreen = getPlane(reader, 1, 2, 1, 'ROI', bb);
                Iblue = getPlane(reader, 1, 3, 1, 'ROI', bb);

                Irgb = cat(3, Ired, Igreen, Iblue);
                labImg = rgb2lab(Irgb);

                currIsletMask = isletDataFilt(ii).Image;
                currIsletMask = padarray(currIsletMask, [50 50], 0, 'both');

                isletDataFilt(ii).meanLightness = mean(labImg(currIsletMask), 'all');
                isletDataFilt(ii).meanIntensity = mean(Ired(currIsletMask) + Igreen(currIsletMask) + Iblue(currIsletMask), 'all');

                Iout = showoverlay(Irgb, currIsletMask, 'Opacity', 30);

                if ~exist(fullfile(outputDir, 'islets'), 'dir')
                    mkdir(fullfile(outputDir, 'islets'))
                end

                imwrite(Iout, fullfile(outputDir, 'islets', sprintf('I%03d.tif', ii)))

            end

            %--- Generate output files ---%

            %Write data to file
            imwrite(isletLabels, fullfile(outputDir, [fname, '_isletLabels.tif']), 'Compression', 'none')
            imwrite(maskTissueFull, fullfile(outputDir, [fname, '_tissueMask.tif']), 'Compression', 'none')

            %Generate a thumbnail image for validation
            imageOut = showoverlay(imageOut, imresize(isletLabels > 0, 0.1), 'Color', [1 0 0], 'Opacity', 40);
            imageOut = showoverlay(imageOut, imresize(maskTissueFull, 0.1), 'Color', [0 1 0], 'Opacity', 20);

            imwrite(imageOut, fullfile(outputDir, [fname, '_thumbnail.tif']))

            save(fullfile(outputDir, [fname, '.mat']), 'isletDataFilt')

            %Print completion statement
            fprintf('%s - Completed file %s (%.0f/%.0f).\n', ...
                datetime, fname, iFile, numel(files));

        end

    end

end

methods (Static)



    
end

end