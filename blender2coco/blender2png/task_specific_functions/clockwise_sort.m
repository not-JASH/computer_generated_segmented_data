function points = clockwise_sort(points)
    center = [mean(points(:,1)),mean(points(:,2))];
    angles = atan2d(points(:,1)-center(1),points(:,2)-center(2));
    [~,I] = sort(angles);
    points = points(I,:);
end