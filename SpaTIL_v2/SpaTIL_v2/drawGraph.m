function drawGraph( image,coords,M,lineWidth,markerSize,lineAlpha,markerAlpha,useBlackLine )
%DRAWGRAPH Summary of this function goes here
%   Detailed explanation goes here

if nargin<4
    lineWidth=4;
end

if nargin<5
    markerSize=20;
end

if nargin<6
    lineAlpha=.3;
end

if nargin<7
    markerAlpha=.8;
end

if nargin<8
    useBlackLine=true;
end

colors={'b','y','g','r','c','m','w'};

imshow(image);
hold on;

numGroups=length(coords);

for k=1:numGroups
    matrix=M{k};
    centroids=coords{k};
    numCent=length(centroids);
    for i=1:numCent
        for j=1+i:numCent
            if matrix(i,j)>0
                s=plot([centroids(i,1),centroids(j,1)],[centroids(i,2),centroids(j,2)],colors{k},'LineWidth',lineWidth);
                s.Color(4)=lineAlpha;
                if useBlackLine
                    plot([centroids(i,1),centroids(j,1)],[centroids(i,2),centroids(j,2)],'k','LineWidth',1);
                end
            end
        end
    end
    
    if markerSize>0
        
        s = scatter(centroids(:,1),centroids(:,2),markerSize,'MarkerFaceColor',colors{k},'MarkerEdgeColor','k');
        alpha(s,markerAlpha);
    end
    
end

hold off;

end