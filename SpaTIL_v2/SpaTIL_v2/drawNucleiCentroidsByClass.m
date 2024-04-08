function drawNucleiCentroidsByClass( image,centroids,class, markerSize, colors )

 if nargin<3 || isempty(class)
     class=zeros(size(centroids,1),1);
 end
 
 if nargin<4
     markerSize=10;    
 end

if nargin<5
    colors={'g','b','r','c','y'};
end



imshow(image);
hold on;

cl=unique(class);
numClass=length(cl);

for i=1:numClass
    cent=centroids(class==cl(i),:);
    %plot(cent(:,1),cent(:,2),[colors{i} '*'],'MarkerSize',markerSize);
    scatter(cent(:,1),cent(:,2),markerSize,'MarkerFaceColor',colors{i},'MarkerEdgeColor','k');
    %scatter(cent(:,1),cent(:,2),markerSize,colors{i},'filled');
end

hold off;
end