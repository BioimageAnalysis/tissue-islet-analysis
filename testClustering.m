% %Clean up mask a little
% maskIsletsFull_2 = bwareaopen(maskIsletsFull, 10);
% imshow(maskIsletsFull_2)

%I think grow to combine, filter and relabel might be the way to go
maskIsletsFullTMP = imclose(maskIsletsFull, strel('disk', 40));
maskIsletsFullTMP = imopen(maskIsletsFullTMP, strel('disk', 25));

maskIsletsFullTMP = bwareaopen(maskIsletsFullTMP, 1000);

%Relabel


imshow(maskIsletsFullTMP);






%Measure x-y locations
[rowIdx, colIdx] = find(maskIsletsFull);

idx = dbscan([colIdx, rowIdx], 15, 30);

xx = colIdx(idx > 0);
yy = rowIdx(idx > 0);

idxFilt = idx(idx > 0);

gscatter(xx, yy, idxFilt);
