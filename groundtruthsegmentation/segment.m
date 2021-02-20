imagedir = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\images";
images = dir(imagedir);images(1:2)=[];
%load('trainedsegnet2.mat')

sample = imread(fullfile(imagedir,images(randi(length(images))).name));
tic
C = semanticseg(sample,trainedNet,...
    'OutputType','uint8',...
    'MiniBatchSize',128,...
    'ExecutionEnvironment','gpu');
toc

imshow(sample)
hold on 
overlay = imshow(25*C);
hold off
set(overlay,'AlphaData',0.5)
