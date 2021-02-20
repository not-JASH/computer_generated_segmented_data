imagedir = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\images";
pixeldir = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\pixellabels";

imageDs = imageDatastore(imagedir);
classNames = ["walls" "floor" "ceiling" "door" "bed" "couch" "chair" "drawer" "table"];
pixelLabelID = [1 2 3 4 5 6 7 8 9];

pixelDs = pixelLabelDatastore(pixeldir,classNames,pixelLabelID);

newsize = [370 720];
outputfolder = append(pwd,'\reshaped_dataset');

imagefolder = strcat(outputfolder,'\images');
imageDs = resizeImages(imageDs,imagefolder,newsize);

pixelfolder = strcat(outputfolfer,'\pixels');
pixelDs = resizePixelLabels(pixelDs,pixelfolder,newize);