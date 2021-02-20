warning('off')
% parfevalOnAll(gcp(), @warning, 0, 'off', 'all')
path_to_renders = "C:\project_data\interiors_2\renders";
save_path = "C:\project_data\interiors_2\png_renders";
frames = [{},{}];
renders = dir(path_to_renders);
renders(1:2) = [];
dims = [900 1600 3];
progress_file = fopen('progress_log.txt','r');
progress = textscan(progress_file,'%s','delimiter','\n');
progress = progress{1};fclose(progress_file);
for i = 1:length(renders)
    render_frames = dir(fullfile(path_to_renders,renders(i).name));
    render_frames(1:2) = [];
    render_save_path = fullfile(save_path,renders(i).name);
    if ~exist(render_save_path,'dir')
        mkdir(save_path,renders(i).name);
    end
    for j = 1:length(render_frames)
        progressbar(j/length(render_frames))
        render_frame_path = fullfile(path_to_renders,renders(i).name,render_frames(j).name);
        render_frame_save_path = fullfile(render_save_path,render_frames(j).name);
        if ~exist(render_frame_save_path,'dir')
            mkdir(render_save_path,render_frames(j).name);
        end
        frames = [frames;[{render_frame_path},{render_frame_save_path}]];
    end
end
i = 1;
while i <= length(frames)
    for j = 1:length(progress)
        if strcmp(progress{j},frames{i,1})
            frames(i,:) = [];
            i = 0;
            break
        end
    end
    i = i+1;
end
i =1;
batch_size = 100;
progress_log = fopen('progress_log.txt','w');
error_log = fopen('error_log.txt','w');
% progressbar(i/length(frames));
while 1
    fprintf('\n\napproximate completion\t:%.3g%%\n\n',100*i/length(frames));
    range = [i:i+batch_size-1];
    range(range>length(frames))=[];
    range_status = cell(length(range),1);
    range_images = cell(length(range),1);
    range_shapes = cell(length(range),1);
%     parfor j = 1:length(range)
    for j = 1:length(range)
        try
            [range_images{j},range_shapes{j}] = process_frame(frames{range(j),1});
            fprintf('%s\t\tcomplete\n',frames{range(j),1})
            range_status{j} = 'complete';
        catch 
            fprintf('%s\t\terror\n',frames{range(j),1})
            range_status{j} = 'error';
        end
    end
    for j = 1:length(range)
%         progressbar(range(j)/length(frames))
        switch range_status{j}
            case 'complete'
                shapes2png(dims,range_shapes{j},frames{range(j),2});
                image = imread(range_images{j}{1});
                imwrite(image,fullfile(frames{range(j),2},'image.JPEG'));
                fprintf(progress_log,'%s\n',frames{range(j),1});
            case 'error'
                fprintf(error_log,'%s\n',frames{range(j),1});
        end
    end
    i = i+batch_size;
    if range(end)==length(frames)
        break;
    end
end
fclose('all');          
        
    
   
%% functions 
function shapes2png(dims,shapes,savepath)
    blank_image = zeros(dims);
    for i = 1:length(shapes)
        imshow(blank_image);
        hold on 
        plot(shapes{i,3},'facecolor','white','facealpha',1)
        hold off
        filename = append('object_',num2str(i),'_',shapes{i,1});
        filename = fullfile(savepath,filename);
        saveas(gcf,append(filename,'.png'))
    end
end
    


function [image_file,final_list] = process_frame(path_to_frame)
    frame_contents = dir(path_to_frame);
    frame_contents(1:2) = [];
    unsorted_contents = frame_contents;
    image_file = [];
    room = {'walls';'ceiling';'floor';'door';'bed';'drawer';'chair';'table';'couch'};
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
    image = imread(image_file{1});
%     imwrite(image,fullfile(savepath,'image.JPEG'));
    dims = size(image);
    image_shape = [0 0;0 dims(1);dims(2) dims(1);dims(2) 0];
    image_shape = polyshape(image_shape);
    room{1,5} = findwalls(room{1,2},dims,image_shape);
    if isempty(room{1,5})
        fprintf('no walls found in this frame: %s\n',path_to_frame);
        return
    end
    [room{3,5},room{2,5}] = findfloorceil(room{1,5},image_shape);
    boundcoeffs = [0,0.25,0,0.25,0.1,0.5];
    for i = 4:9
        [room{i,3},room{i,4},room{i,5}] = findobjects(room{i,2},dims,image_shape,boundcoeffs(i-3));
    end
    room_surf ={};
    for i = 1:3
        for j = 1:length(room{i,5})
            room_surf = [room_surf;{room{i,1},0,room{i,5}{j}}];
        end
    end
    object_list = {};
    for i = 4:9
        for j = 1:length(room{i,5})
            object_list = [object_list;{room{i,1},room{i,4}{j}(3),room{i,5}{j}}];
        end
    end
    i = 1;
    while i <= size(object_list,1)
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
    no_objects = size(object_list,1);
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
    for i = 1:size(room_surf,1)
        for j = 1:no_objects
            room_surf{i,3} = subtract(room_surf{i,3},object_list{j,3});
        end
    end
    final_list = [room_surf;object_list];
end

function y = point2point_intercept(point1,point2,newpoint)
    if point1(1)>point2(1)
        temp = point1;
        point1=point2;
        point2 = temp;
        clear temp
    end
    m = (point2(2)-point1(2))/(point2(1)-point1(1));
    b = point2(2)-m*point2(1);
    y = m*newpoint+b;
end
    
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
        walls = {};
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
