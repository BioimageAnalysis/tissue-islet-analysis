clearvars
clc

filePath = 'D:\Work\Research\HillLabTEST\2023_10_16__0013\2023_10_16__0013.mat';

load(filePath);

[fpath, fname] = fileparts(filePath);

fid = fopen(fullfile(fpath, [fname, '.csv']), 'w');

%Write headers
fprintf(fid, 'Islet ID, Area, Circularity, Mean Lightness, Mean Intensity\n');

for iRow = 1:numel(isletDataFilt)

    fprintf(fid, '%03d, %d, %.3f, %.3f, %.3f\n', ...
        iRow, isletDataFilt(iRow).Area, isletDataFilt(iRow).Circularity, ...
        isletDataFilt(iRow).meanLightness, isletDataFilt(iRow).meanIntensity);

end

fclose(fid);