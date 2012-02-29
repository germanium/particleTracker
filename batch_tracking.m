% EL ERROR PARECE VENIR DEL JAVA VM. PUEDO USAR MATLAB SIN JAVA PERO IMSHOW LO NECESITA

function batch_tracking

% dbstop if error                 % Start debugger if error 

addpath('~/Documents/MATLAB/file_tools/',...
    genpath('~/Documents/MATLAB/u-track110523_peakDetector'))

%% Load Image folders to process
PWD = pwd;
T_DIR = uipickfiles('Prompt','Select folders where the *.tif files are');

%% Detection parameters

bitDepth = 16;

%% Tracking parameters

% General tracking parameters

    % Gap closing time window. Depends on SNR and fluorophore blinking. Critical
    %  if too small or too large. Robust in proper range (default 10 frames)
gapCloseParam.timeWindow = 6;
    % Flag for merging and splitting
gapCloseParam.mergeSplit = 0;

    % Minimum track segment length used in the gap closing, merging and
    %  splitting step. Excludes short tracks from participatin in the gap
    %  closing, mergin and splitting step.
gapCloseParam.minTrackLen = 3;

    % Time window diagnostics: 1 to plot a histogram of gap lengths in
    %  the end of tracking, 0 or empty otherwise
gapCloseParam.diagnostics = 0;

% Cost functions

    % Frame-to-frame linking
costMatrices(1).funcName = 'costMatLinearMotionLink2';
    % Gap closing, merging and splitting
costMatrices(2).funcName = 'costMatLinearMotionCloseGaps2';

    % Kalman filter functions
    % Memory reservation
kalmanFunctions.reserveMem = 'kalmanResMemLM';
    % Filter initialization
kalmanFunctions.initialize = 'kalmanInitLinearMotion';
    % Gain calculation based on linking history
kalmanFunctions.calcGain = 'kalmanGainLinearMotion';
    %Time reversal for second and third rounds of linking
kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';

% Cost function specific parameters: Frame-to-frame linking

    % Flag for motion model, 0 for random motion, 1 for linear
parameters.linearMotion = 0;
    % Search radius lower limit
parameters.minSearchRadius = 2;
    % Search radius upper limit
parameters.maxSearchRadius = 5;
    % Standard deviation multiplication factor -> default is 3 INFLUYE MUCHO
parameters.brownStdMult = 3;
    % Flag for using local density in search radius estimation
parameters.useLocalDensity = 1;
    % Number of past frames used in nearest neighbor calculation
parameters.nnWindow = gapCloseParam.timeWindow;

    % Optional input for diagnostics: To plot the histogram of linking distances
    %  up to certain frames. For example, if parameters.diagnostics = [2 35],
    %  then the histogram of linking distance between frames 1 and 2 will be
    %  plotted, as well as the overall histogram of linking distance for frames
    %  1->2, 2->3, ..., 34->35. The histogram can be plotted at any frame except
    %  for the first and last frame of a movie.
    % To not plot, enter 0 or empty
parameters.diagnostics = [];

    % Store parameters for function call
costMatrices(1).parameters = parameters;
clear parameters

% Cost function specific parameters: Gap closing, merging and splitting

    % Same parameters as for the frame-to-frame linking cost function
parameters.linearMotion = costMatrices(1).parameters.linearMotion;
parameters.useLocalDensity = costMatrices(1).parameters.useLocalDensity;
parameters.maxSearchRadius = costMatrices(1).parameters.maxSearchRadius;
parameters.minSearchRadius = costMatrices(1).parameters.minSearchRadius;
parameters.brownStdMult = costMatrices(1).parameters.brownStdMult*...
    ones(gapCloseParam.timeWindow,1);
parameters.nnWindow = costMatrices(1).parameters.nnWindow;

    % Formula for scaling the Brownian search radius with time.
    % Power for scaling the Brownian search radius with 
    %  time, before and after timeReachConfB (next parameter).     
parameters.brownScaling = [0.5 0.01]; 
    % Before timeReachConfB, the search radius grows with time with the power in 
    %  brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
parameters.timeReachConfB = 4; 

    % Amplitude ratio lower and upper limits
parameters.ampRatioLimit = [0.7 4];
    % Minimum length (frames) for track segment analysis
parameters.lenForClassify = 5;
    % Standard deviation multiplication factor along preferred direction of
    %  motion -> default 3
parameters.linStdMult = 3*ones(gapCloseParam.timeWindow,1);

    % Formula for scaling the linear search radius with time.
parameters.linScaling = [0.5 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
parameters.timeReachConfL = gapCloseParam.timeWindow;
    % Maximum angle between the directions of motion of two linear track
    %  segments that are allowed to get linked ->Default 30 creo que no esta
    %  implementado, no hace un sorete al menos.
parameters.maxAngleVV = 35;

    % Gap length penalty (disappearing for n frames gets a penalty of gapPenalty^n)
    % Note that a penalty = 1 implies no penalty, while a penalty < 1 implies
    %  that longer gaps are favored 
parameters.gapPenalty = 1.5;

    % Resolution limit in pixels, to be used in calculating the merge/split search radius
    % Generally, this is the Airy disk radius, but it can be smaller when
    %  iterative Gaussian mixture-model fitting is used for detection
parameters.resLimit = 3.4;

    % Store parameters for function call
costMatrices(2).parameters = parameters;
clear parameters

% Additional input

saveResults.dir = cd;                           % save results to current folder 
saveResults.filename = 'TrackingParam.mat';     % name of file where input and output are saved
saveResults = 0;                                % don't save results
    % Verbose
verbose = 0;
    % Problem dimension
probDim = 2;


%% Cycle through folders 
for i=1:length(T_DIR);                          
    clear movieInfo tracksFinal
%     clear java
    
    cd(T_DIR{i})
    disp(T_DIR{i})
    
    TIFS = dir('*.tif');                       % VERY IMPORTANT THAT RESULTS ARE SORTED
    N = length(TIFS);                          % ALPHABETICALLY                     
    I = cell(1,N);

    for j=1:N
        I{j} = imread(TIFS(j).name);   
    end
    
    % Detection     
    movieInfo = peakDetector(I, bitDepth, 0, []);
    
    % tracking function call
    [tracksFinal,~,~] = trackCloseGapsKalmanSparse(movieInfo,...
        costMatrices,gapCloseParam,kalmanFunctions,probDim,saveResults,verbose);
    
    
    if isempty(tracksFinal)
                                            % No tracks 
        disp('No tracks detected to plot');
    else
                                            % Plot trajectories
                                            % OpenGL por hardware is faster
        htracks = figure('Renderer','OpenGL','Visible','off'); 
        imshow(I{1},[])
        plotTracks2D(tracksFinal, [], '3', [], 0, 0, [], [], 0);
        title(T_DIR{i}, 'Interpreter', 'none')
        
        % save results
        Tr_parameters = {['Maximum gap length: ', num2str(gapCloseParam.timeWindow)];...
            ['Minimum track segment length: ', num2str(gapCloseParam.minTrackLen)]};
        im = I{1};
        
        if ~exist('/tracksFinal.mat' ,'file')        % Don't overwrite if exists
            save('tracksFinal.mat', 'tracksFinal', 'im', 'Tr_parameters');
            print(htracks,'-dpng','Trajectories.png');
            close(htracks)
        end
    end
end

cd(PWD)
