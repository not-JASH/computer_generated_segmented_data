samplepath = "C:\project_data\fastrcnn_walls\yoloannots\room_1\frame_1";
imagepath = fullfile(samplepath,'image.JPEG');
textfile = append(imagepath,'.txt');
image = imread(imagepath);
file = fopen(textfile,'r');

contents = textscan(file,'%s','delimiter','\n');
contents = contents{1};
data = cell(length(contents),5);
for i = 1:length(contents)
    temp = strsplit(contents{i},'\t');
    switch temp{1}
        case 'walls'
            data{i,1} = 1;
        case 'floor'
            data{i,1} = 2;
        case 'ceiling' 
            data{i,1} = 3;
        case 'bed'
            data{i,1} = 4;
        case 'couch' 
            data{i,1} = 5;
        case 'chair'
            data{i,1} = 6;
        case 'table' 
            data{i,1} = 7;
        case 'drawer'
            data{i,1} = 8;
        case 'door' 
            data{i,1} = 9;
    end
    temp = strsplit(temp{2},' ');
    for j = 1:4
        data{i,j+1} = round(str2double(temp{j}));
    end
end
data = cell2mat(data);
data(:,3) = data(:,3) - data(:,5);
annotated_image = insertObjectAnnotation(image,'rectangle',data(:,2:5),data(:,1));
imshow(annotated_image)