%% selecting a render
sample_render = "C:\project_data\interiors_2\renders\room_1";
sample = dir(sample_render);
sample(1:2) = [];
%% selecting a frame
frame = ceil(1000*rand(1));
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

%% reading walls
walls = cell(4,1);
for i = 1:4
    active_file = fopen(wall_files{i},'r');
    walls{i} = textscan(active_file,'%f %f %f','delimiter','\n');
    walls{i} = cell2mat(walls{i});
    walls{i} = blender2matlabcoords(walls{i},dims);
    fclose(active_file);
end

mainwalls = [];
clc
imshow(image)
hold on 
for i = 1:4
    if ~isempty(walls{i})
%         display(walls{i})
        if noparallax(walls{i})
            if ~isbehindcamera(walls{i})
                mainwalls = [mainwalls;{walls{i}}];
                plot(walls{i}(:,1),walls{i}(:,2),'-o')
                fprintf('%g\n',walls{i}(2,2)-walls{i}(4,2))
            end
        end
    end
end
hold off
mainlimits = cell(size(mainwalls));
for i = 1:length(mainlimits)
    p = mainwalls{i}(:,(1:2));
    %points 1 & 4 share a y coordinate, same with p 3 & 2
    %point 1 is always to the right of point 3 
    %point 4 is always above point 1
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
 end

%% task specific functions


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