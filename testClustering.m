% %Clean up mask a little
% maskIsletsFull_2 = bwareaopen(maskIsletsFull, 10);
% imshow(maskIsletsFull_2)

%I think grow to combine, filter and relabel might be the way to go
maskIsletsFullTMP = imclose(maskIsletsFull, strel('disk', 40));
maskIsletsFullTMP = imopen(maskIsletsFullTMP, strel('disk', 25));

maskIsletsFullTMP = bwareaopen(maskIsletsFullTMP, 1000);

%Relabel
L = bwlabel(maskIsletsFullTMP);
L = L .* maskIsletsFull;
L = uint16(L);
save('20240405data.mat','L')

imshow(label2rgb(L));
