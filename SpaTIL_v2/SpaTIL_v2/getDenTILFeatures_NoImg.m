function [ features,featureNames ] = getDenTILFeatures_NoImg(tileArea,lympCentroids,nonLympCentroids,lympAreas)
%GETDENTILFEATURES Summary of this function goes here
%   Detailed explanation goes here

numLymp=length(lympCentroids);
totNuclei=numLymp+length(nonLympCentroids);

%% Regular-density-based measures
%A=tileSize^2;
%totLympArea=sum(nucleiFeatures(prediction==1,1));
totLympArea=sum(lympAreas);

densLymp=numLymp/tileArea;
densAreaLymp=totLympArea/tileArea;
ratioLymp=numLymp/totNuclei;

%% Grouping-based measures
%groupingFactor=sum(1./pdist(lympCent))/length(lympCent);
groupingVector=getSumNodeWeightsThreshold(lympCentroids,'euclidean',.005);
normVect = normalizeVector(groupingVector,0);

maxGr=max(groupingVector);
minGr=min(groupingVector);
avgGr=mean(groupingVector);
stdGr=std(groupingVector);
medGr=median(groupingVector);
modeGr=mode(groupingVector);

numHighlyGroupedLymp=length(normVect(normVect>.5));

%% Convex-hull-based measures
if length(lympCentroids)>2
    [~,areaConvHull]=convhull([lympCentroids;nonLympCentroids]);
    [convHullLymp,areaConvHullLymp]=convhull(lympCentroids);
    convHullLymp=lympCentroids(convHullLymp,:);
    if length(nonLympCentroids)>2
        [convHullNonLymp,~]=convhull(nonLympCentroids);
        convHullNonLymp=nonLympCentroids(convHullNonLymp,:);
        intersArea=getIntersectedArea(convHullLymp,convHullNonLymp);
    else
        intersArea=0;
    end
    densLympConvHull=numLymp/areaConvHull;
    ratioConvHulls=areaConvHullLymp/areaConvHull;
else
    densLympConvHull=0;
    ratioConvHulls=0;
    intersArea=0;
end

%% Density-Matrix-based meatures
M=getDensityMatrixCore(sqrt(tileArea) ,5,lympCentroids);
M(M==0)=[];

maxM=max(M);
minM=min(M);
avgM=mean(M);
stdM=std(M);
medM=median(M);
modeM=mode(M);

%% compiling features

features=[densLymp,densAreaLymp,ratioLymp,maxGr,minGr,avgGr,...
    stdGr,medGr,modeGr,numHighlyGroupedLymp,densLympConvHull,...
    ratioConvHulls,intersArea,maxM,minM,avgM,stdM,medM,modeM,...
    ];

featureNames={'#Lymp/TissueArea','LympTotalArea/TissueArea',...
    '#Lymp/#TotalNuclei','MaxLympGroupingFactor','MinLympGroupingFactor',...
    'AvgLympGroupingFactor','StdLympGroupingFactor',...
    'MedianLympGroupingFactor','ModeLympGroupingFactor','NumHighlyGroupedLymp',...
    '#Lymp/TotalConvHullArea','LympConvHullArea/TotalConvHullArea',...
    'IntersectedAreaConvHullLymp&NonLymp','MaxDensityMatrixVal',...
    'MinDensityMatrixVal','AvgDensityMatrixVal','StdDensityMatrixVal',...
    'MedianDensityMatrixVal','ModeDensityMatrixVal',...
    };

%     features=[numLymp,densLymp,densAreaLymp,ratioLymp,groupingFactor];
%
%     featNames={'#Lymp','#Lymp/TissueArea','LympTotalArea/TissueArea',...
%         '#Lymp/#TotalNuclei','GroupingFactor',...
%         };

end

function M=getDensityMatrixCore(imgDim,partitions,centroids)

tileDim=imgDim/partitions;
M=[];
for i=1:tileDim:imgDim
    for j=1:tileDim:imgDim
        coords=centroids(centroids(:,1)>=i & centroids(:,1)<i+tileDim & ...
            centroids(:,2)>=j & centroids(:,2)<j+tileDim,:);
        M=[M;length(coords)];
    end
end
%N=reshape(M,[partitions,partitions]);
%drawDensityMatrix(N,30);
end

function A=getIntersectedArea(pointsShape1,pointsShape2)

polyarray1 = polyshape(pointsShape1);
polyarray2 = polyshape(pointsShape2);
polyout = intersect([polyarray1 polyarray2]);
A=polyarea(polyout.Vertices(:,1),polyout.Vertices(:,2));

%     [xp1,yp1]=my_poly2cw(pointsShape1(:,1),pointsShape1(:,2));
%     [xp2,yp2]=my_poly2cw(pointsShape2(:,1),pointsShape2(:,2));
%     [xi, yi] = my_polybool('intersection',xp1,yp1,xp2,yp2);
%     A = polyarea(xi,yi);
end