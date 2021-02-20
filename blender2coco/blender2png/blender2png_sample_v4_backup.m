clc
%% selecting a render
sample_render = "C:\project_data\interiors_2\renders\room_1";
sample = dir(sample_render);
sample(1:2) = [];
%% selecting a frame
frame = ceil(1000*rand(1));
% frame = 86;
sample_frame = sample(frame);
sample_frame_contents = dir(fullfile(sample_frame.folder,sample_frame.name));
sample_frame_contents(1:2) = [];
%% sorting contents
unsorted_contents = sample_frame_contents;
image_file = [];
room = {'walls';'ceiling';'floor';'door';'bed';'drawer';'chair';'table';'couch'};
%labels,files,coords,depth,shapes
room = [room,cell(length(room),4)];
objectswhosenamesiforgottochange = [];
while exist('unsorted_contents','var')&&~isempty(unsorted_contents)
    latest_file = fullfile(unsorted_contents(1).folder,unsorted_contents(1).name);
    if contains(lower(unsorted_contents(1).name),'frame')
        image_file = {latest_file};
        unsorted_contents(1) = [];
    elseif contains(unsorted_contents(1).name,'Door')
        room{6,2} = [room{6,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'wall')
        room{1,2} = [room{1,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'ceiling')
        room{2,2} = [room{2,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'floor')
        room{3,2} = [room{3,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'door')
        room{4,2} = [room{4,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'bed')
        room{5,2} = [room{5,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'drawer')
        room{6,2} = [room{6,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(unsorted_contents(1).name,'Knob')
        room{6,2} = [room{6,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'chair')
        room{7,2} = [room{7,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'table')
        room{8,2} = [room{8,2};{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'couch')
        room{9,2} = [room{9,2};{latest_file}];
        unsorted_contents(1) = [];
    else 
        objectswhosenamesiforgottochange = [objectswhosenamesiforgottochange;{latest_file}];
        unsorted_contents(1) = [];
    end
end
clear unsorted_contents

%% image 
image = imread(image_file{1});
dims = size(image);
image_shape = [0 0;0 dims(1);dims(2) dims(1);dims(2) 0];
image_shape = polyshape(image_shape);

%% walls
room{1,5} = findwalls(room{1,2},dims,image_shape);

%% floor and ceiling 
[room{3,5},room{2,5}] = findfloorceil(room{1,5},image_shape);

%% the rest
%consider deleting all door.knob fies from dataset
boundcoeffs = [0,0.25,0,0.25,0.1,0.5];
for i = 4:9
    [room{i,3},room{i,4},room{i,5}] = findobjects(room{i,2},dims,image_shape,boundcoeffs(i-3));
end

%% clipping by depth
room_surf ={};
for i = 1:3
    for j = 1:length(room{i,5})
        room_surf = [room_surf;{room{i,1},0,room{i,5}{j}}];
    end
end
object_list = {};
%category depth shape
for i = 4:9
    for j = 1:length(room{i,5})
        object_list = [object_list;{room{i,1},room{i,4}{j}(3),room{i,5}{j}}];
    end
end
i = 1;
while i <= length(object_list)
    temp = subtract(image_shape,object_list{i,3});
    if object_list{i,2}<0
        object_list(i,:) = [];
        i = 0;
    elseif isempty(temp.Vertices)
        object_list(i,:) = [];
        i = 0;
    end
    i = i+1;
end
object_list = sortrows(object_list,2,'descend');
no_objects = length(object_list);
if no_objects > 1
    for i = 1:no_objects-1
        for j = i+1:no_objects
            object_list{i,3} = subtract(object_list{i,3},object_list{j,3});
        end
    end
end
i = 1;
while i <= size(object_list,1)
    if isempty(object_list{i,3}.Vertices)
        object_list(i,:) = [];
        i = 0;
    end
    i = i+1;
end           
no_objects = size(object_list,1);
for i = 1:length(room_surf)
    for j = 1:no_objects
        room_surf{i,3} = subtract(room_surf{i,3},object_list{j,3});
    end
end
final_list = [room_surf;object_list];


%% saving to png

savepath = 'C:\project_data\blender2coco\blender2png\sample';

blank_image = zeros(dims);
for i = 1:length(final_list)
    imshow(blank_image)
    hold on 
    plot(final_list{i,3},'facecolor','white','facealpha',1)
    hold off
    filename = append('object_',num2str(i),'_',final_list{i,1});
    filename = fullfile(savepath,filename);
    saveas(gcf,append(filename,'.png'))
end


imshow(image)
hold on 
for i = 1:length(final_list)
    plot(final_list{i,3})
end

%% task specific functions
function [object_coords,object_depth,objects] = findobjects(object_files,dims,image_shape,boundarycoeffs)
    [object_coords,no_objects,filesperobject] = multifile_object_load(object_files,dims);
    objects = multiobjectparse(object_coords,no_objects,filesperobject,boundarycoeffs);
    object_depth = depthlocs(object_coords);
    for i = 1:no_objects
        objects{i} = intersect(objects{i},image_shape);
    end
end

function [floor,ceiling] = findfloorceil(walls,image_shape)
    floor = {};ceiling = {};
    floorceil = image_shape;
    for i = 1:length(walls)
        floorceil = subtract(floorceil,walls{i});
    end
    floorceil = sortboundaries(floorceil,'centroid','ascend');
    floorceil = regions(floorceil);
    for i = 1:length(floorceil)
        if any(floorceil(i).Vertices(:,2)<0.1)
            ceiling = {floorceil(i)};
        else
            floor = {floorceil(i)};
        end
    end
end

function walls = findwalls(wall_files,dims,image_shape)
    %points 1 & 4 share a y coordinate, same with p 3 & 2
    %point 1 is always to the right of point 3 
    %point 4 is always above point 1
    %wall 2 is always left of wall 1
    %wall 3 is always left of wall 2
    %wall 4 is always left of wall 3
    %wall 1 is always left of wall 4
    %left to right
    wall_order = [1,4,3,2,1];
    walls = cell(4,1);
    for i = 1:4
        walls{i} = parseblender(wall_files{i},dims);
    end
    mainwalls = [];
    wall_indices = [];
    for i = wall_order(1:4)
        if ~isempty(walls{i})
            if noparallax(walls{i})
                if ~isbehindcamera(walls{i})
                    mainwalls = [mainwalls;{walls{i}}];
                    wall_indices = [wall_indices;i];
                end
            end
        end
    end
    hold off
    if length(mainwalls)>1
        for i = 1:length(mainwalls)-1
            if all(wall_indices(i:i+1) == [1;2])
                temp = mainwalls{i};
                mainwalls{i} = mainwalls{i+1};
                mainwalls{i+1} = temp;
                clear temp
                wall_indices(i:i+1) = [2;1];
            end
        end
    elseif isempty(mainwalls)
        fprintf('No walls detected in this image :( \n')
        return
    end
    mainlimits = cell(size(mainwalls));
    for i = 1:length(mainlimits)
        p = mainwalls{i}(:,(1:2));
        mainlimits{i} = p;
        if p(1,1)>dims(2)
            y = point2point_intercept(p(2,:),p(1,:),dims(2));
            mainlimits{i}(1,:) = [dims(2) y];
            y = point2point_intercept(p(3,:),p(4,:),dims(2));
            mainlimits{i}(4,:) = [dims(2) y];
            if mainlimits{i}(4,1)-mainlimits{i}(1,1) ~= 0
                if p(4,2) < 0 
                    mainlimits{i} = [mainlimits{i};[dims(2) 0]];
                elseif p(1,2) > dims(1)
                    mainlimits{i} = [mainlimits{i};[dims(2) dims(1)]];
                end
            end
        end
        if p(3,1)<0
            y = point2point_intercept(p(2,:),p(1,:),0);
            mainlimits{i}(3,:) = [0 y];
            y = point2point_intercept(p(3,:),p(4,:),0);
            mainlimits{i}(2,:) = [0 y];
            if mainlimits{i}(3,1)-mainlimits{i}(2,1)~=0
                if p(3,2) < 0
                    mainlimits{i} = [mainlimits{i};[0 0]];
                elseif p(2,2) > limits(1)
                    mainlimits{i} = [mainlimits{i};[0 dims(1)]];
                end
            end
        end
        mainlimits{i} = clockwise_sort(mainlimits{i});
    end
    %if the main walls do not occupy the width of the image, select the
    %adjacent walls and continue
    %walls in image that are not in mainwalls are flipped because of parallax
    if mainlimits{1}(1,1)>0
        newwall = wall_indices(1)+1;
        newwall(newwall>4) = 1;
        wall_indices = [newwall;wall_indices];
        newwall = walls{newwall}(:,(1:2));
        newwall = clockwise_sort(newwall);
        newwall = [-1 -1].*newwall;
        deltax = min(mainlimits{1}(:,1))-max(newwall(:,1));
        newwall = clockwise_sort(newwall);
        deltay = mainlimits{1}(1,2)-newwall(4,2);
        newwall = newwall + [deltax deltay];
        mainlimits = [{newwall};mainlimits];  
    end
    if mainlimits{end}(4,1)<dims(2)
        newwall = wall_indices(end)-1;
        newwall(newwall<1) = 4;
        wall_indices = [wall_indices;newwall];
        newwall = walls{newwall}(:,(1:2));
        newwall = clockwise_sort(newwall);
        newwall = [-1 -1].*newwall;
        deltax = max(mainlimits{end}(:,1))-min(newwall(:,1));
        newwall = clockwise_sort(newwall);
        deltay = mainlimits{end}(4,2)-newwall(1,2);
        newwall = newwall+[deltax deltay];    
        mainlimits = [mainlimits;{newwall}];
    end
    %this does not always produce an exact fit. Differences between actual wall
    %and current fit will hopefully be picked up with roof & ceiling.
    walls_in_image = cell(size(mainlimits));
    for i = 1:length(walls_in_image)
        walls_in_image{i} = polyshape(mainlimits{i});
        walls_in_image{i} = intersect(walls_in_image{i},image_shape);
    end
    walls = walls_in_image;
end

function object_depth = depthlocs(coords)
    object_depth = cell(size(coords,1),1);
    for i = 1:length(object_depth)
        for j = 1:size(coords,2)
            object_depth{i} = [object_depth{i};coords{i,j}];
        end
        object_depth{i} = [max(object_depth{i}(:,3)),min(object_depth{i}(:,3)),mean(object_depth{i}(:,3))];
    end
end

function objects = multiobjectparse(coords,no_objects,filesperobject,boundcoeff)
    objects = cell(no_objects,1);
    for i = 1:no_objects
        temp = cell(filesperobject,1);
        for j = 1:filesperobject
            temp{j} = boundary(coords{i,j}(:,[1,2]),boundcoeff);
            temp{j} = polyshape(coords{i,j}(temp{j},[1,2]));
            if j == 1
                objects{i} = temp{j};
            else
                objects{i} = union(objects{i},temp{j});
            end
        end
    end
end

function coords = parseblender(file,dims)
    active_file = fopen(file);
    coords = textscan(active_file,'%f %f %f','delimiter','\n');
    coords = cell2mat(coords);
    coords = blender2matlabcoords(coords,dims);
    fclose(active_file);
end  

function [objects,count,filesperobject] = multifile_object_load(files,dims)
    %the world isnt ready yet
    %% cant use this if some files are omitted 
    [count,filesperobject] = howmany(files);
    objects = cell(count,filesperobject);
    current_file = ones(count,1);
    for i = 1:length(files)
        if contains(files{i},'.001')
            objects{2,current_file(2)} = parseblender(files{i},dims);
            current_file(2)=current_file(2)+1;
        elseif contains(files{i},'.002')
            objects{3,current_file(3)} = parseblender(files{i},dims);
            current_file(3) = current_file(3)+1;
        elseif contains(files{i},'.003')
            objects{4,current_file(4)} = parseblender(files{i},dims);
            current_file(4) = current_file(4)+1;
        else
            objects{1,current_file(1)} = parseblender(files{i},dims);
            current_file(1) = current_file(1)+1;
        end
    end
end
    
function [count,filesperobj] = howmany(object_files)
    count = 1;
    for i = 1:length(object_files)
        if contains(object_files{i},'.001')&&count<2
            count = 2;
        elseif contains(object_files{i},'.002')&&count<3
            count = 3;
        elseif contains(object_files{i},'.003')&&count<4
            count = 4;
        end
    end     
    filesperobj = length(object_files)/count;
end

function points = clockwise_sort(points)
    center = [mean(points(:,1)),mean(points(:,2))];
    angles = atan2d(points(:,1)-center(1),points(:,2)-center(2));
    [~,I] = sort(angles);
    points = points(I,:);
end

function state = noparallax(points)
    state = 1;
    cc = sign([points(1,2)-points(4,2);
        points(2,2)-points(1,2);
        points(3,2)-points(2,2);
        points(4,2)-points(3,2)]);
    parallax = [1;-1;1;-1];
    if (all(cc==parallax)||all(cc==-parallax))
        state = 0;
    end
end

function coords = blender2matlabcoords(coords,dims)
    coords(:,2) = 1-coords(:,2);
    coords = [dims(2),dims(1),1].*coords;
end

function state = isbehindcamera(coords)
    state = 0;
    if all(coords(:,3)<0) 
        state = 1;
    end
end
