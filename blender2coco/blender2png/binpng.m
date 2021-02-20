size = [900 1600];
B = zeros(size);
%shape is arbitrarily triangle
Vertex{1} = [123 100];
Vertex{2} = [300 400];
Vertex{3} = [400 240];

triangle = [Vertex{1};Vertex{2};Vertex{3}];

allX = [1:size(2)].*ones(size);
allY = transpose([1:size(1)]).*ones(size);
allXY = [allX(:),allY(:)];

[in,on] = inpolygon(allX(:),allY(:),triangle(:,1),triangle(:,2));
A = B;
shape = [allXY(in,:);allXY(on,:)];
for i = 1:length(shape)
    A(shape(i,1),shape(i,2)) = 1;
end

imshow(A)