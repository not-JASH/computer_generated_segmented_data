function y = point2point_intercept(point1,point2,newpoint)
%points come in as [x,y]
%y = mx + b
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
    