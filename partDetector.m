function movieInfo = partDetector(I, area, maxEcce, VERBOSE)
% movieInfo = partDetector(I,bitDepth,area, maxEcce, VERBOSE)
%
%


if nargin < 2 || isempty(area)
    area = [2 20];
end

if nargin < 3 || isempty(maxEcce)
    maxEcce = 0.8;
end

if nargin < 4 
    VERBOSE = true;
end

Nfr = length(I);
[h, w] = size(I{1});
maxIntensity = max(I{1}(:));


% START DETECTION

% initialize structure to store info for tracking
[movieInfo(1:Nfr,1).xCoord] = deal([]);
[movieInfo(1:Nfr,1).yCoord] = deal([]);
[movieInfo(1:Nfr,1).amp] = deal([]);
[movieInfo(1:Nfr,1).int] = deal([]);


if VERBOSE
    progressText(0,'Detecting Peaks');
end

for iF = 1:Nfr                   % Loop though frames and filter 
                                 % Binary image with thr at half maxIntensity   
    Ii = I{iF} > 0.5*maxIntensity;
    
    featProp = regionprops( Ii, 'PixelIdxList', 'Area', 'Eccentricity');
                                % Sort through features and retain only 
                                % the "good" ones
    goodFeatIdx = vertcat(featProp(:,1).Area) > area(1) &...
                   vertcat(featProp(:,1).Area) < area(2) &...
                   vertcat(featProp(:,1).Eccentricity) < maxEcce;
%     goodFeatIdxI = find(vertcat(featProp2(:,1).MaxIntensity)>2*cutOffValueInitInt);

    % make new label matrix and get props
    featureMap = zeros(h,w);
    featureMap(vertcat(featProp(goodFeatIdx,1).PixelIdxList)) = 1;
    [featMapFinal,nFeats] = bwlabel(featureMap);
    
    featPropFinal = regionprops(featMapFinal, Ii,...
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
    movieInfo(iF,1).xCoord = xCoord;         % Can't save it as single for Khuloud's tracker
    movieInfo(iF,1).yCoord = yCoord;
    movieInfo(iF,1).amp = amp;          % amp should be intensity not area!
    movieInfo(iF,1).int = featI;

    
    if VERBOSE
        progressText(iF/Nfr,'Detecting peaks');
    end
end

