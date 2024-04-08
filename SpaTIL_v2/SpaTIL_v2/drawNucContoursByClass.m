function drawNucContoursByClass( M,I,centroids, classes, tickness )
%DRAWNUCCONTOURSBYCLASS Summary of this function goes here
%   Detailed explanation goes here


if nargin<5
    tickness=1;
end

numCent=length(centroids);

boundaries = bwboundaries(M);
numNucMask = size(boundaries,1);

colors={'b','y','g','r'};

imshow(I);
hold on;
for i=1:numNucMask
    b = boundaries{i};
    w=min(b(:,1));
    x=max(b(:,1));
    y=min(b(:,2));
    z=max(b(:,2));
    for j=1:numCent
        if centroids(j,1)>y && centroids(j,1)<z && centroids(j,2)>w && centroids(j,2)<x
            plot(b(:,2),b(:,1),colors{classes(j)+1},'LineWidth',tickness);
        end
    end
    
end
hold off;


end

