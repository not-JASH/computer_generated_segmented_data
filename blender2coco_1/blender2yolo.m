annotation_path = "C:\Users\Jashua\Documents\project_data\interior_detection\annots_8";
save_path = 'C:\Users\Jashua\Documents\MATLAB\blender2yolo\sample';

annotation_paths = dir(annotation_path);annotation_paths(1:2) = [];
for i = 1:length(annotation_paths)
    if strcmp(annotation_paths(i).name,'objects.txt')
        annotation_paths(i) = [];
        break
    end
end
no_frames = length(annotation_paths);
frames = cell(no_frames,1);
% for i = 1:no_frames
%     frames{i} = fullfile(annotation_path,annotation_paths(i).name,'frame.JPEG');
%     frame = imread(frames{i});
%     imwrite(frame,fullfile(save_path,append(annotation_paths(i).name,'.JPEG')));
% end
%%
fprintf('press a key for yes, return for no\n')
if input('load settings?     ')
    selected_objects = textscan(fopen(fullfile(save_path,'objects.txt')),'%s','delimiter','\n');
    selected_objects = selected_objects{1};
    fclose('all');
else
    objects = dir(fullfile(annotation_path,annotation_paths(1).name));
    objects(1:2) = [];
    fprintf('select relevant objects\n')
    no_objects = 1;
    for i = 1:length(objects)
        if ~strcmp(objects(i).name,'frame.JPEG')
            if input(append(objects(i).name,':   '))
                selected_objects{no_objects} = objects(i).name;
                no_objects = no_objects+1;
            end
        end
    end
    writecell(transpose(selected_objects),fullfile(save_path,'objects.txt'))
end
no_objects = length(selected_objects);

%% unique object catch, some objects consist of several files, here we combine them
%ideally, properly name the objects & components in blender
if input('load_unique objects?    ')
    load('unique_1.mat')
else
    for i = 1:no_objects
        fprintf(append(selected_objects{i},'\n'))
    end
    unique_objects = input('how many unique objects\n');
    unique_members = cell(unique_objects,2);
    object_list = selected_objects;
    for i = 1:unique_objects
        fprintf('#####################################################\n\n')
        unique_members{i,1} = input('enter the name of unique object\n','s');
        no_members = 1;
        selection = [];
        for j = 1:length(object_list)
            fprintf(append(object_list{j},'\n'))
            if input('is this item a component of unique object?   ')
                unique_members{i,2}{no_members} = object_list{j};
                selection{no_members} = j;
                no_members = no_members+1;
            end
        end
%         unique_members{i,2} = cell2table(unique_members{i,2});
        selection = cell2mat(selection);
        object_list(selection) = [];
        save('unique_1.mat',unique_members)
    end
end         

%% loading object nodes 
current_image = 124;
image_path = fullfile(save_path,append('frame_',num2str(current_image),'.JPEG'));
coord_path = fullfile(annotation_path,append('frame_',num2str(current_image)));
object_coords = cell(no_objects,3);
coord_files = dir(coord_path);coord_files(1:2) = [];
image = imread(image_path);

image_size = size(image);
j = 1;
for i = 1:length(coord_files)
    if ~strcmp(coord_files(i).name,'frame.JPEG')
        object_coords{j,1} = coord_files(i).name;
        object_coords{j,2} = fullfile(coord_path,coord_files(i).name);
        j = j+1;
    end
end
for i = 1:no_objects
    file = fopen(object_coords{i,2},'r');
    object_coords{i,3} = textscan(file,'%f %f %f','delimiter','\n');
    object_coords{i,3} = cell2mat(object_coords{i,3});
    %blender 0,0 is top left, matlab is bottom left
    object_coords{i,3}(:,2) = 1-object_coords{i,3}(:,2);
    object_coords{i,3} = [image_size(2),image_size(1),1].*object_coords{i,3};
    fclose(file);
end

%% combining object components 
unique_coords = cell(length(unique_members),2);
for i = 1:length(unique_members)
    unique_coords{i,1} = unique_members{i,1};
    unique_coords{i,2} = cell(length(unique_members{i,2}),1);
    for j = 1:length(unique_members{i,2})
        for k = 1:no_objects
            if strcmp(object_coords{k,1},unique_members{i,2}{j})
                unique_coords{i,2}{j} = object_coords{k,3};
            end
        end
    end
    unique_coords{i,2} = cell2mat(unique_coords{i,2});
end







































