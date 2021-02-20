annotations_path = "C:\project_data\fastrcnn_walls\yoloannots";
image_list = [];
renders = dir(annotations_path);
renders(1:2) = [];
for i = 1:length(renders)
    render_path = fullfile(annotations_path,renders(i).name);
    frames = dir(render_path);
    frames(1:2) = [];
    for j = 1:length(frames)
        frame_path = fullfile(render_path,frames(i).name);
        files = dir(frame_path);
        if length(files)>2
            image_file = fullfile(frame_path,'image.JPEG');
            image_list = [image_list;[{image_file},{append(image_file,'.txt')}]];
        end
    end
end