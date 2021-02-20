% setenv('CUDA_VISIBLE_DEVICES','1,2')
if isempty(gcp('nocreate'))
    parpool('local',8);
end
imagedir = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\images";
pixeldir = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\pixellabels";
checkpointpath = "C:\project_data\groundtruthsegmentation\checkpoints";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('net_checkpoint__4662__2020_11_03__11_27_48.mat')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imageDs = imageDatastore(imagedir);
classNames = ["walls" "floor" "ceiling" "door" "bed" "couch" "chair" "drawer" "table"];
pixelLabelID = [1 2 3 4 5 6 7 8 9];

pixelDs = pixelLabelDatastore(pixeldir,classNames,pixelLabelID);
sample = imread('sample.png');

%model = segnetLayers([370 720 3],9,'vgg19');

no_files = numel(imageDs.Files);
no_samples = no_files;
testsplit = 0.8;
indices = randperm(no_files);
limit = round(testsplit*no_samples);
train_indices = indices(1:limit);
valid_indices = indices(limit+1:no_samples);

train_labels = pixelDs.Files(train_indices);
trainingPixelDs = pixelLabelDatastore(train_labels,classNames,pixelLabelID);
train_images = imageDs.Files(train_indices);
trainingImageDs = imageDatastore(train_images);

valid_labels = pixelDs.Files(valid_indices);
validationPixelDs = pixelLabelDatastore(valid_labels,classNames,pixelLabelID);
valid_images = imageDs.Files(valid_indices);
validationImageDs = imageDatastore(valid_images);

options = trainingOptions('adam',...
    'InitialLearnRate',1e-5,...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.1,...
    'LearnRateDropPeriod',1,...
    'MaxEpochs',2,...
    'MiniBatchSize',12,...
    'Verbose',1,...
    'VerboseFrequency',25,...
    'Shuffle','every-epoch',...
    'Checkpointpath',checkpointpath,...
    'ExecutionEnvironment','multi-gpu',...
    'WorkerLoad',[1 1 0 0 0 0 0 0],...
    'Plots','training-progress',...
    'DispatchInBackground',1);

training_data = pixelLabelImageDatastore(trainingImageDs,trainingPixelDs);
trainedNet = trainNetwork(training_data,layerGraph(net),options);
