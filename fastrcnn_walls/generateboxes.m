if isempty(gcp('nocreate'))
    parpool(3);
end
pathtoimages = "C:\project_data\fastrcnn_walls\images\render_1";
load('detector_1700.mat')

image_files = dir(pathtoimages);
image_files(1:2) = [];
no_images = length(image_files);
indices = zeros(no_images,1);
for i = 1:no_images
    temp = strsplit(image_files(i).name,'_');
    temp = strsplit(temp{2},'.');
    indices(i) = str2double(temp{1});
end
[~,indices] = sort(indices,'ascend');
image_files = image_files(indices);


images = cell(no_images,1);
parfor i = 1:no_images
    temp = cell(1,5);
    temp{1} = imread(fullfile(pathtoimages,image_files(i).name));
    [temp{2},temp{3},temp{4}] = detect(detector,temp{1},...
        'MiniBatchSize',32,...
        'ExecutionEnvironment','gpu');
    temp{5} = insertObjectAnnotation(temp{1},'rectangle',temp{2},temp{4});
    images{i} = temp;
end


