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
wall_files = [];
ceiling_files = [];
floor_files = [];
door_files = [];
bed_files = [];
drawer_files = [];
chair_files = [];
table_files = [];
couch_files = [];
objectswhosenamesiforgottochange = [];
while exist('unsorted_contents','var')&&~isempty(unsorted_contents)
    latest_file = fullfile(unsorted_contents(1).folder,unsorted_contents(1).name);
    if contains(lower(unsorted_contents(1).name),'frame')
        image_file = {latest_file};
        unsorted_contents(1) = [];
    elseif contains(unsorted_contents(1).name,'Door')
        drawer_files = [drawer_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(unsorted_contents(1).name,'Knob')
        drawer_files = [drawer_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'wall')
        wall_files = [wall_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'ceiling')
        ceiling_files = {latest_file};
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'floor')
        floor_files = [floor_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'door')
        door_files = [door_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'bed')
        bed_files = [bed_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'drawer')
        drawer_files = [drawer_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'chair')
        chair_files = [chair_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'table')
        table_files = [table_files;{latest_file}];
        unsorted_contents(1) = [];
    elseif contains(lower(unsorted_contents(1).name),'couch')
        couch_files = [couch_files;{latest_file}];
        unsorted_contents(1) = [];
    else 
        objectswhosenamesiforgottochange = [objectswhosenamesiforgottochange;{latest_file}];
        unsorted_contents(1) = [];
    end
end
clear unsorted_contents

%objects per wall           1
%objects per ceiling        1
%objects per floor          1
%objects per door           2
%objects per bed            2
%objects per drawer         11
%objects per chair          13
%objects per table          3
%objects per couch          1
%unassigned objects:        1


%% reading image 
image = imread(image_file{1});
dims = size(image);
image_shape = [0 0;0 dims(1);dims(2) dims(1);dims(2) 0];
image_shape = polyshape(image_shape);

%% parse walls
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

%% floor and ceiling 
floorceil = image_shape;
for i = 1:length(walls_in_image)
    floorceil = subtract(floorceil,walls_in_image{i});
end
floorceil = sortboundaries(floorceil,'centroid','ascend');
floorceil = regions(floorceil);
floor = [];ceiling = [];
for i = 1:length(floorceil)
    if any(floorceil(i).Vertices(:,2)<0.1)
        ceiling = floorceil(i);
    else
        floor = floorceil(i);
    end
end
%% parse doors
%differentiate between door,door.001,door.002...
%ignore doorknob (door_2.txt)
[no_doors,~] = howmany(door_files);
door_coords = cell(no_doors,1);
doors = cell(no_doors,1);
for i = 1:length(door_files)
    door_coords{i} = parseblender(door_files{i},dims);
    doors{i} = boundary(door_coords{i}(:,[1,2]),1e-5);
    doors{i} = polyshape(door_coords{i}(doors{i},[1,2]));
    doors{i} = intersect(doors{i},image_shape);    
    plot(doors{i})
end

%% parse beds
[bed_coords,no_beds,filesperbed] = multiobject_file_load(bed_files,dims);
beds = multiobjectparse(bed_coords,no_beds,filesperbed,0.25);
for i = 1:no_beds
    beds{i} = intersect(beds{i},image_shape);
    plot(beds{i})
end

%% parse drawers 
[drawer_coords,no_drawers,filesperdrawer] = multiobject_file_load(drawer_files,dims);
drawers = multiobjectparse(drawer_coords,no_drawers,filesperdrawer,0);
for i = 1:no_drawers
    drawers{i} = intersect(drawers{i},image_shape);
    plot(drawers{i})
end

%% parse chairs
[chair_coords,no_chairs,filesperchair] = multiobject_file_load(chair_files,dims);
chairs = multiobjectparse(chair_coords,no_chairs,filesperchair,0.25);
for i = 1:no_chairs
    chairs{i} = intersect(chairs{i},image_shape);
    plot(chairs{i})
end

%% parse tables
[table_coords,no_tables,filespertable] = multiobject_file_load(table_files,dims);
tables = multiobjectparse(table_coords,no_tables,filespertable,0.1);
for i = 1:no_tables
    tables{i} = intersect(tables{i},image_shape);
    plot(tables{i})
end

%% parse couches
[no_couches,~] = howmany(couch_files);
couch_coords = cell(no_couches,1);
couches = cell(no_couches,1);
for i = 1:no_couches
    couch_coords{i} = parseblender(couch_files{i},dims);
    couches{i} = boundary(couch_coords{i}(:,[1,2]),0.5);
    couches{i} = polyshape(couch_coords{i}(couches{i},[1,2]));
    couches{i} = intersect(couches{i},image_shape);
    plot(couches{i})
end
%% arrange by depth and clip
fprintf('Doors\n')
maxminmeanZ(door_coords)
fprintf('beds\n')
maxminmeanZ(bed_coords)
fprintf('drawers\n')
maxminmeanZ(drawer_coords)
fprintf('chairs\n')
maxminmeanZ(chair_coords)
fprintf('tables\n')
maxminmeanZ(table_coords)
fprintf('couches\n')
maxminmeanZ(couch_coords)





%% saving to png







%% task specific functions
function maxminmeanZ(coords)
   for i = 1:size(coords,1)
       for j = 1:size(coords,2)
           fprintf('%g %g %g\n',max(coords{i,j}(:,3)),min(coords{i,j}(:,3)),mean(coords{i,j}(:,3)))
       end
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

function [objects,count,filesperobject] = multiobject_file_load(files,dims)
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
