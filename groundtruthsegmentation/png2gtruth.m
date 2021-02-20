png_path = "C:\project_data\interiors_2\png_renders";
files = [];
% [path2imagefolder,newfilename] %% images will be out of order
renders = dir(png_path);renders(1:2) = [];
for i = 1:size(renders,1)
    renderpath = fullfile(png_path,renders(i).name);
    frames = dir(renderpath);frames(1:2) = [];
    for j = 1:size(frames,1)
        path2frame = fullfile(renderpath,frames(i).name);
        newfilename = append('render_',num2str(i),'_frame_',num2str(j));
        files = [files;[{path2frame} {newfilename}]];
    end
end



for i = 1:size(files,1)
    progressbar(i/size(files,1));
    parfeval(@png2truth,0,files(i,:));
end



function png2truth(info)
    image_savepath = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\images";
    pixel_savepath = "C:\project_data\groundtruthsegmentation\groundtruth_dataset\pixellabels";
    path = info{1};
    name = info{2};
    sample = dir(path);sample(1:2) = [];
    gtruth = [];
    for i = 1:size(sample,1)
        currentfile = fullfile(path,sample(i).name);
        if endsWith(sample(i).name,'.JPEG')
            image = imread(currentfile);
        elseif endsWith(sample(i).name,'.png')
            temp = rgb2gray(imread(currentfile));
            temp(temp~=0) = whichclass(sample(i).name);
            gtruth = [gtruth;{temp}];
        end
    end
    temp = gtruth{1};
    for i = 2:length(gtruth)
        temp = temp + gtruth{i};
    end
    temp(temp>9) = 0;
    imwrite(image,fullfile(image_savepath,append(name,'.JPEG')))
    imwrite(temp,fullfile(pixel_savepath,append(name,'.png')),'png')
end   







































function class_num = whichclass(string)
%class 0 is background? 
    if contains(string,'walls')
        class_num = 1;
    elseif contains(string,'floor')
        class_num = 2;
    elseif contains(string,'ceiling')
        class_num = 3;
    elseif contains(string,'door')
        class_num = 4;
    elseif contains(string,'bed')
        class_num = 5;
    elseif contains(string,'couch')
        class_num = 6;
    elseif contains(string,'chair')
        class_num = 7;
    elseif contains(string,'drawer')
        class_num = 8;
    elseif contains(string,'table')
        class_num = 9;
    end
end
        
