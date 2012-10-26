function [movieInfo] = peakDetector(I,bitDepth,savePlots,outDir, VERBOSE)
% [movieInfo] = peakDetector(I,bitDepth,savePlots,outDir, VERBOSE)
%
%
%INPUT  I                 : Image stack, cell array with one frame per array
%       bitDepth          : bit depth of the images - should be 12, 14, or 16
%       savePlots         : 1 to save overlay plots of detection results, 
%                           0 if not. Default true
%       outDir            : Output directory. Default pwd
%       VERBOSE           : Verbose option. Default true
%
%OUTPUT movieInfo         : nFrames-structure containing x/y coordinates
%       stdList           : nFrames-vector containing the standard
%                           deviation of the difference of Gauss-filtered
%                           images corresponding to each frame. this is
%                           based on either the user-selected ROI (if
%                           provided) or a region estimated to be within the
%                           cell from the background (cell) point (if ROI wasn't
%                           provided). both the ROI and bg (cell) point 
%                           are saved during setupRoiDirectories.m

warningState = warning;
% warning('off','MATLAB:divideByZero')

% CHECK INPUT AND SET UP DIRECTORIES

% get projData in correct format
% if nargin<1 || isempty(projData)
%     % if not given as input, ask user for ROI directory
%     % assume images directory is at same level
%     projData.imDir = uigetdir('~/Documents/Data','Please select image directory');
% 
% end

% count number of images in image directory
% [listOfImages] = searchFiles('.tif', [], projData.imDir, 0);
% nImTot = size(listOfImages,1);
nIm = length(I);

% check timeRange input, assign start and end frame
% if nargin<2 || isempty(timeRange)
%     startFrame = 1;
%     endFrame = nIm;
% elseif isequal(unique(size(timeRange)),[1 2])
%     if timeRange(1)<=timeRange(2) && timeRange(2)<=nIm
%         startFrame = timeRange(1);
%         endFrame = timeRange(2);
%     else
%         startFrame = 1;
%         endFrame = nIm;
%     end
% 
% else
%     error('--plusTipCometDetector: timeRange should be [startFrame endFrame] or [] for all frames')
% end
% nFrames = endFrame-startFrame+1;

% get image dimensions, max intensity from first image
% fileNameIm = [char(listOfImages(1,2)) filesep char(listOfImages(1,1))];
% img = double(imread(fileNameIm));
[imL,imW] = size(I{1});
maxIntensity = max(I{1}(:));

% get bit depth if not given
if nargin < 2 || isempty(bitDepth)
    fileNameIm = uigetfile('*.tif','Please select an image to estimate bit depth',...
        '~/Documents/Data');
    imgData = imfinfo(fileNameIm);
    bitDepth = imgData.BitDepth;
    disp(['bitDepth estimated to be' bitDepth])
end

% check bit depth to make sure it is 12, 14, or 16 and that its dynamic
% range is not greater than the provided bitDepth
if sum(bitDepth==[8 12 14 16])~=1 || maxIntensity > 2^bitDepth-1
    error('--plusTipCometDetector: bit depth should be 12, 14, or 16');
end

% check input for savePlots
if nargin<3 || isempty(savePlots)
    savePlots = 1;
end

% If ouDir wasn't inputed then use pwd
if nargin<4 || isempty(outDir)
    outDir = pwd;
end

if nargin<5 
    VERBOSE = true;
end

% make feat directory if it doesn't exist from batch
featDir = [outDir '/feat'];
if isdir(featDir)
    rmdir(featDir,'s')
end
mkdir(featDir)
mkdir([featDir '/filterDiff']);    
if savePlots==1
    mkdir([featDir '/overlayImages']);
end


% look for region of interest info from project setup step
if ~exist([outDir '/roiMask.tif'],'file')
    % not roi selected; use the whole image
    roiMask = true(imL,imW);
    roiYX = [1 1; imL 1; imL imW; 1 imW; 1 1];
else
    % get roi edge pixels and make region outside mask NaN
    roiMask = double(imread([outDir '/roiMask.tif']));
    roiYX = load([outDir '/roiYX']);
    roiYX = roiYX.roiYX;
end


% string for number of files
s1 = length(num2str(nIm));
strg1 = sprintf('%%.%dd',s1);


% START DETECTION

% initialize structure to store info for tracking
[movieInfo(1:nIm,1).xCoord] = deal([]);
[movieInfo(1:nIm,1).yCoord] = deal([]);
[movieInfo(1:nIm,1).amp] = deal([]);
[movieInfo(1:nIm,1).int] = deal([]);

% get difference of Gaussians image for each frame and standard deviation
% of the cell background, stored in stdList
stdList = nan(nIm,1);
count = 1;
if VERBOSE
    progressText(0,'Filtering images for peak detection');
end

% create kernels for gauss filtering
blurKernelLow  = fspecial('gaussian', 21, 1);
blurKernelHigh = fspecial('gaussian', 21, 4);
                        
for iFrame = 1:nIm          % Loop though frames and filter 
    if VERBOSE
        progressText(count/nIm,'Filtering images for peak detection');
    end
    
    % load image and normalize to 0-1
%     fileNameIm = [char(listOfImages(iFrame,2)) filesep char(listOfImages(iFrame,1))];
%     img = double(imread(fileNameIm))./((2^bitDepth)-1);
    img = double(I{iFrame})./((2^bitDepth)-1);

    % use subfunction that calls imfilter to take care of edge effects
    lowPass = filterRegion(img,roiMask,blurKernelLow);
    highPass = filterRegion(img,roiMask,blurKernelHigh);

    % get difference of gaussians image
    filterDiff = lowPass-highPass;

    % if bg point was chosen and saved, get bgMask from first frame
    if iFrame==1 && exist([outDir '/bgPtYX.mat'],'file')~=0
        bgPtYX = load([outDir '/bgPtYX.mat']);
        bgPtYX = bgPtYX.bgPtYX;
        [bgMask] = eb3BgMask(filterDiff,bgPtYX); % Make mask
        saveas(gcf,[featDir filesep 'filterDiff' filesep 'bgMask.tif']);
        close(gcf)
    end
    % if bg point wasn't chosen, use ROI
    if iFrame==1 && exist([outDir '/bgPtYX.mat'],'file')==0
        bgMask = logical(roiMask);
    end

    stdList(iFrame) = std(filterDiff(bgMask));      % STD of the cell area controls the 
                                                    % thresh step size
    indxStr1 = sprintf(strg1,iFrame);
    save([featDir filesep 'filterDiff' filesep 'filterDiff' indxStr1],'filterDiff')
    save([featDir filesep 'stdList'],'stdList')
    
    count = count+1;
end



count = 1;
if VERBOSE
    progressText(0,'Detecting peaks');
end

for iFrame = 1:nIm                          % loop thru frames and detect
    if VERBOSE
        progressText(count/nIm,'Detecting peaks');
    end
    if iFrame==1
        tic
    end

    indxStr1 = sprintf(strg1,iFrame);
    filterDiff = load([featDir '/filterDiff/filterDiff' indxStr1]);
    filterDiff = filterDiff.filterDiff;

    % thickness of intensity slices is average std from filterDiffs over
    % from one frame before to one frame after
    if iFrame==1
        sF = iFrame;
    else
        sF = iFrame-1;
    end
    if iFrame==nIm
        eF = iFrame;
    else
        eF = iFrame+1;
    end
    stepSize = mean(stdList(sF:eF));        % stdList is the std on the (estimated) cell
    thresh = 3*stepSize;                    %  area.
    
    % we assume each step size down the intensity profile should be on
    % the order of the size of the background std; here we find how many
    % steps we need and what their spacing should be. we also assume peaks
    % should be taller than 3*std
    nSteps = round((nanmax(filterDiff(:))-thresh)/stepSize);
    threshList = linspace(nanmax(filterDiff(:)),thresh,nSteps);
    slice2 = zeros(size(img));              % In case it doesn't detect anything
    
    % compare features in z-slices startest from the highest one
    for p = 1:length(threshList)-1

        % slice1 is top slice; slice2 is next slice down
        % here we generate BW masks of slices
        if p==1
            slice1 = filterDiff > threshList(p);
        else
            slice1 = slice2;
        end
        slice2 = filterDiff > threshList(p+1);

        % now we label them
        featMap1 = bwlabel(slice1);
        featMap2 = bwlabel(slice2);
        featProp2 = regionprops(featMap2,'PixelIdxList');

        % loop thru slice2 features and replace them if there are 2 or
        % more features from slice1 that contribute
        for iFeat = 1:max(featMap2(:))
            pixIdx = featProp2(iFeat,1).PixelIdxList; % pixel indices from slice2
            featIdx = unique(featMap1(pixIdx)); % feature indices from slice1 using same pixels
            featIdx(featIdx==0) = []; % 0's shouldn't count since not feature
            if length(featIdx)>1 % if two or more features contribute...
                slice2(pixIdx) = slice1(pixIdx); % replace slice2 pixels with slice1 values
            end
        end

    end

    % label slice2 again and get region properties
    featMap2 = bwlabel(slice2);
    featProp2 = regionprops(featMap2,'PixelIdxList','Area','Eccentricity');

    % here we sort through features and retain only the "good" ones
    % we assume the good features have area > 2 pixels
    goodFeatIdxA = vertcat(featProp2(:,1).Area) > 2;
    goodFeatIdxE = vertcat(featProp2(:,1).Eccentricity) < 0.8;
%     goodFeatIdxI = find(vertcat(featProp2(:,1).MaxIntensity)>2*cutOffValueInitInt);
    goodFeatIdx = goodFeatIdxA & goodFeatIdxE;


    % make new label matrix and get props
    featureMap = zeros(imL,imW);
    featureMap(vertcat(featProp2(goodFeatIdx,1).PixelIdxList)) = 1;
    [featMapFinal,nFeats] = bwlabel(featureMap);
    
    featPropFinal = regionprops(featMapFinal,filterDiff,...
        'PixelIdxList','Area','WeightedCentroid','MaxIntensity'); %'Extrema'

    if nFeats==0
        yCoord = [];
        xCoord = [];
        amp = [];
        featI = [];
        
    else
        % centroid coordinates with 0.5 uncertainties for Khuloud's tracker
        yCoord = 0.5*ones(nFeats,2);
        xCoord = 0.5*ones(nFeats,2);
        temp = vertcat(featPropFinal.WeightedCentroid);
        yCoord(:,1) = temp(:,2);
        xCoord(:,1) = temp(:,1);

        % area
        featArea = vertcat(featPropFinal(:,1).Area);
        amp = zeros(nFeats,2);
        amp(:,1) = featArea;

        % intensity
        featInt = vertcat(featPropFinal(:,1).MaxIntensity);
        featI = zeros(nFeats,2);
        featI(:,1) = featInt;
    end

    % make structure compatible with Khuloud's tracker
    movieInfo(iFrame,1).xCoord = xCoord;
    movieInfo(iFrame,1).yCoord = yCoord;
    movieInfo(iFrame,1).amp = amp;          % amp should be intensity not area!
    movieInfo(iFrame,1).int = featI;


    indxStr1 = sprintf(strg1,iFrame); % frame

    %plot feat outlines and centroid on image
    if savePlots==1
        img = double(I{iFrame})./((2^bitDepth)-1);

        figure
        imagesc(img);
        hold on
        scatter(xCoord(:,1),yCoord(:,1),'c.'); % plot centroid in cyan
        colormap gray
        plot(roiYX(2),roiYX(1),'w')
        axis equal
        saveas(gcf,[featDir '/overlayImages/overlay' indxStr1 '.tif']);
        saveas(gcf,[featDir '/overlayImages/overlay' indxStr1 '.fig']);
        close(gcf)
    end

    count=count+1;
end
save([featDir '/movieInfo'],'movieInfo');

rmdir([featDir '/filterDiff'],'s');

warning(warningState);



function filteredIm = filterRegion(im, mask, kernel)
% Filtered image nomalized by filtered mask...

im(mask~=1) = 0;                    
filteredIm = imfilter(im, kernel);
W = imfilter(double(mask), kernel);
filteredIm = filteredIm ./ W;
filteredIm(~mask) = nan;


function [bgMask] = eb3BgMask(filterDiff,bgPtYX)
% Finds a mask for the cell based on the peaks percentile and the distance to bgPtXY

% local max detection
fImg = locmax2d(filterDiff,[20 20],1);

% get indices of local maxima
idx = find(fImg);
[r, c] = find(fImg);

% calculate percentiles of max intensities to use for rough idea of cell
% region
p1 = prctile(fImg(idx),80);
p2 = prctile(fImg(idx),90);

% get indices of those maxima within the percentile range ("good" features)
goodIdx = find(fImg(idx)>p1 & fImg(idx)<p2);

% get indices for nearest fifty points to user-selected point.
D = createDistanceMatrix([bgPtYX(1) bgPtYX(2)],[r(goodIdx) c(goodIdx)]);
[~,closeIdx] = sort(D);
closeIdx = closeIdx(1:min(50,length(closeIdx)));    
% Gets the closest 50 points from the point selected inside the cell. They are in between 
% the percentile 80 and 90 of all the maximas brightness 

% get convex hull and create ROI from that
K = convhull(c(goodIdx(closeIdx)),r(goodIdx(closeIdx)));
[bgMask,xi,yi] = roipoly(fImg,c(goodIdx(closeIdx(K))),r(goodIdx(closeIdx(K))));


figure 
imagesc(filterDiff); 
colormap gray;
axis equal
hold on
scatter(bgPtYX(2),bgPtYX(1),'*y')           % user-selected point
scatter(c(goodIdx),r(goodIdx),'.g')         % all "good" features in green
scatter(c(goodIdx(closeIdx)),r(goodIdx(closeIdx)),'r') % nearest fifty to point in red
plot(xi,yi)                                 % plot mask outline in blue


