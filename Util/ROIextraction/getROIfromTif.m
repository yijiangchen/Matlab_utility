% Returns the ROI defined by the annotation.  This replaces a half dozen
% cobbled together functions

% Inputs:
% imgPath         - string, path to image file
% annotation      - struct, with fields X and Y containing the X and Y coordinates of the ordered set of verticies defining the ROI boundary
% inputMag        - integer, the original magnification of the image
% outputMag       - integer, the desired output magnification
% rot             - not used, kept just for compatability reasons

% Output:
% ROI             - 3D uint8, RGB image of ROI, cropped from original as rectangular image
% mask            - 2D logical, mask to be applied to get ROI from rectangle
% Patrick Leo - 2017

% October 2017: removed rotation from input list, added nargout
% consideration

% July 2018: changed imgWidths = extractfield(imgInfo,'Width') to
% imgWidths = [imgInfo.Width] to avoid checking out MAP toolbox license

% October 2018: Boldy removed the magnfication-based image extraction and
% replaced it with an MPP based system that relies on the Bioformats
% package and the image-reported MPP. If Bioformats fails, it tries to use
% Openslide to get the MPP
function [ROI mask] = getROIfromTif(imgPath,annotation,outputMPP)

% If we were given a BF reader object in imgPath
if(~isstring(imgPath) && ~ischar(imgPath))
    reader = imgPath;
    imgPath = 'dummy.czi';
else
    if(~exist(imgPath,'file'))
        error('Error: %s not found \n',imgPath)                
    end
end

% BF is twice as fast a Openslide for ndpi images
formatsThatNeedBF = {'czi','ndpi','scn'}; % These are formats that aren't supported by imread or openslide. scn is readable by openslide but it gets the slide dimensions wrong

% Matlab rotates some files (.scn, .tiff) when reading them in, need to undo this
if(strcmp(imgPath(end-3:end),'.scn'))
    rotation = 270;
elseif(strcmp(imgPath(end-3:end),'.tiff'))
    rotation = 180; % not actually implemented here
else
    rotation = 0;
end

imgExtension = strsplit(imgPath,'.');
imgExtension = imgExtension{end};
if(any(strcmp(imgExtension,formatsThatNeedBF)))
    if(~exist('reader','var'))
        reader = bfGetReader(imgPath);
    end
    
    omeMeta = reader.getMetadataStore();
    
    numMags = omeMeta.getImageCount;
    imgMPPs = zeros(1,numMags);
    imgWidths = zeros(1,numMags);
    imgHeights = zeros(1,numMags);
    for(k = 1:omeMeta.getImageCount)
        imgMPPs(k) = omeMeta.getPixelsPhysicalSizeX(k-1).value();
        imgWidths(k) = omeMeta.getPixelsSizeX(k-1).getValue();
        imgHeights(k) = omeMeta.getPixelsSizeY(k-1).getValue();
    end
       
    
    % Make 0.999 = 1
    imgMPPs = round(imgMPPs,3);
    
    baseMPP = min(imgMPPs);
    
    % if the physical pixel size was untrustworthy
    if(length(unique(imgMPPs)) == 1)        
        imgMPPs = baseMPP .* max(imgWidths)./imgWidths;
        imgMPPs = round(imgMPPs,3);
    end
    
    % Only consider layers larger than the desired output, downsize later if
    % needed.
    validLayers = find((outputMPP - imgMPPs) >= 0);
    
    if(isempty(validLayers))
        fprintf('Warning: outputMPP is lower than minimum image MPP of %.2f \n',min(imgMPPs))
        [~,targetLayer] = min(imgMPPs);
    else
        [~,vTarget] = min(abs(imgMPPs(validLayers) - outputMPP));
        targetLayer = validLayers(vTarget);
    end
    matlabTargetLayer = targetLayer;
    resFactor = baseMPP / outputMPP;
    
else
    %     fprintf('BioFormats failed, trying Openslide \n');
    %     imgInfo = imfinfo(imgPath);
    slidePtr = openslide_open(imgPath);
    baseMPP = str2double(openslide_get_property_value(slidePtr,'openslide.mpp-x'));
    resFactor = baseMPP / outputMPP;
    
    [baseMPP,mppY,width,height,numberOfLevels,downsampleFactors,objectivePower] = openslide_get_slide_properties(slidePtr);
    imgMPPs = baseMPP .* downsampleFactors;
    
    validLayers = find((outputMPP - imgMPPs) >= 0);
    if(isempty(validLayers))
        fprintf('Warning: outputMPP is lower than minimum image MPP of %.2f \n',min(imgMPPs))
        [~,matlabTargetLayer] = min(imgMPPs);
    else
        [~,vTarget] = min(abs(imgMPPs(validLayers) - outputMPP));
        matlabTargetLayer = validLayers(vTarget);
    end
    %     openslideTargetLayer = openslide_get_best_level_for_downsample(slidePtr, 1/resFactor);
    %     matlabTargetLayer = openslideTargetLayer + 1;
    openslideTargetLayer = matlabTargetLayer - 1;
    
    %     imgHeights = round(double(width) ./ downsampleFactors);
    imgHeights = round(double(height) ./ downsampleFactors);
    %     imgWidths = [imgInfo.Width];
    %     imgHeights = [imgInfo.Height];
    %     imgMPPs = baseMPP .*(max(imgWidths)./imgWidths);
end



amountToReduceByLater = imgMPPs(matlabTargetLayer) / outputMPP; % if targetLayer doesn't match outputMag
targetAnnoDown = imgMPPs(matlabTargetLayer) / baseMPP; % how much to downsize annotation by when getting region, corresponds to magnification of targetLayer


imgExtension = strsplit(imgPath,'.');
imgExtension = imgExtension{end};
if(any(strcmp(imgExtension,formatsThatNeedBF)))
    %     x = min(annotation.X);
    %     y = min(annotation.Y);
    %     w = max(annotation.X)-min(annotation.X);
    %     h = max(annotation.Y)-min(annotation.Y);
    %
    
    switch rotation
        case 0
            x = min(annotation.X/targetAnnoDown);
            y = min(annotation.Y/targetAnnoDown);
            w = max(annotation.X/targetAnnoDown)-min(annotation.X/targetAnnoDown);
            h = max(annotation.Y/targetAnnoDown)-min(annotation.Y/targetAnnoDown);
            
            x = round(x); y = round(y); w = round(w); h = round(h);
            
        case 270
            
            y = imgHeights(matlabTargetLayer) - max(annotation.X/targetAnnoDown);
            x = min(annotation.Y/targetAnnoDown);
            h = max(annotation.X/targetAnnoDown) - min(annotation.X/targetAnnoDown);
            w = max(annotation.Y/targetAnnoDown)-min(annotation.Y/targetAnnoDown);
            
            x = round(x); y = round(y); w = round(w); h = round(h);
    end
    
    
    ef = bfopenSpecificLayer(reader,targetLayer,x,y,w,h);
    rgb = cat(3,ef{1}{1,1},ef{1}{2,1},ef{1}{3,1});
    %     r = bfGetPlane(reader,1,x,y,w,h);
    %     g = bfGetPlane(reader,2,x,y,w,h);
    %     b = bfGetPlane(reader,3,x,y,w,h);
    %     rgb = cat(3,r,g,b);
    
else
    
    Xstart = round(min(annotation.X/targetAnnoDown));
    Xend = round(max(annotation.X/targetAnnoDown));
    Xlength = abs(Xstart - Xend);
    
    Ystart = round(min(annotation.Y/targetAnnoDown));
    Yend = round(max(annotation.Y/targetAnnoDown));
    Ylength = abs(Ystart - Yend);
    
    slideread = openslide_read_region(slidePtr,Xstart,Ystart,Xlength,Ylength,'level',openslideTargetLayer);
    rgb = slideread(:,:,2:4);
    
    %     catch
    %         fprintf('Openslide openning failed, reverting to imread')
    % Need to account for possible rotation
    %         switch rotation
    %             case 0
    %                 rgb = imread(imgPath,'Index',targetLayer,'PixelRegion',{[round(min(annotation.Y/targetAnnoDown)),round(max(annotation.Y/targetAnnoDown))],...
    %                     [round(min(annotation.X/targetAnnoDown)),round(max(annotation.X/targetAnnoDown))]});
    %             case 270
    %                 rgb = imread(imgPath,'Index',targetLayer,'PixelRegion',{[round(imgHeights(targetLayer) - max(annotation.X/targetAnnoDown)),round(imgHeights(targetLayer) - min(annotation.X/targetAnnoDown))],...
    %                     [round(min(annotation.Y/targetAnnoDown)),round(max(annotation.Y/targetAnnoDown))]});
    %
    %         end
    %     end
end

rgb = imrotate(rgb,rotation);
rgb = imresize(rgb,amountToReduceByLater);

mask = poly2mask(round(annotation.X * resFactor - min(annotation.X * resFactor)),round(annotation.Y * resFactor - min(annotation.Y * resFactor)),...
    round(max(annotation.Y * resFactor)-min(annotation.Y * resFactor)),round(max(annotation.X * resFactor)-min(annotation.X * resFactor)));

% zero pad or reduce mask to match size of image
% rgb and mask can have different sizes due to rounding
if(size(mask,1) > size(rgb,1))
    mask = mask(1:size(rgb,1),:);
elseif(size(mask,1) < size(rgb,1))
    mask = padarray(mask,[size(rgb,1) - size(mask,1) 0],'post');
end

if(size(mask,2) > size(rgb,2))
    mask = mask(:,1:size(rgb,2));
elseif(size(mask,2) < size(rgb,2))
    mask = padarray(mask,[0 size(rgb,2) - size(mask,2) 0],'post');
end

ROI = rgb;

if(nargout == 1)
    ROI = ROI .* uint8(repmat(mask,1,1,size(ROI,3)));
    ROI = ROI + uint8(repmat(~mask,1,1,3))*255;
end