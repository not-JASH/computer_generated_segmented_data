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