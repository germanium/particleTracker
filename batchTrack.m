function batchTrack(pathList, detParam, trackParam, VERBOSE)
% batch_tracking(pathList, bitDepth, pxSize, DT, VERBOSE)
% pathList   - Path list to the movies to proccess. Same format as the
%              uipickfiles() output. If no input it will prompt to select movies.
% detParam   - Has the fields
%               bitDepth: Image bit depth. Default 16
%               pxSize: Pixel size. Default 0.322 um (HIV movies)
%               DT: Time between frames. Default 0.15 seconds (HIV movies)
% trackParam - Has the fields required for u-track
% VERBOSE    - Verbose output. Default false (for parallel)
%
% File tools and u-track_peakDetector have to be on the path
% 
% gP 10/31/2012


PWD = pwd;
if nargin < 1 || isempty(pathList)      % If didn't provide pathList prompt to select it
    pathList = uipickfiles('Prompt','Select *.dv movies');
    VERBOSE = true;
end

if nargin < 2 || isempty(detParam)
    detParam.bitDepth = 16;
    detParam.pxSize = 0.322;                     % In um/px
    detParam.DT = 0.15;                          % In seconds
end

if nargin < 3 || isempty(trackParam)
    error('Need to input track parameters')
end

if nargin < 4 || isempty(VERBOSE)
    VERBOSE = false;
end

tauAna = round(1.5/detParam.DT);       % Tau for analysis, 1.5 seconds to frames

%% Cycle through movies 
if VERBOSE
    tic;
end
for i=1:length(pathList);
    
    movieInfo=[];  tracksFinal=[];
%     clear java
    
    [pathstr, movName] = fileparts(pathList{i});
    cd(pathstr)
    if isdir(movName)
        error(['Folder' movName 'already exist'])
    else
        mkdir(movName)
        cd(movName)
    end
    
    if VERBOSE
        fprintf(['\n--------Processing movie ' movName '--------\n\n'])
    end
                                            
    data = bfopen(pathList{i});                % Load data 
    I = {data{1}{:,1}};
    
                                            % Detection     
    movieInfo = peakDetector(I, detParam.bitDepth, detParam.area,...
        detParam.ecce, VERBOSE);
                                            % Tracking function call
    tracksFinal = trackCloseGapsKalmanSparse(movieInfo,...
        trackParam.costMatrices, trackParam.gapCloseParam,...
        trackParam.kalmanFunctions, trackParam.probDim,...
        trackParam.saveResults, VERBOSE);
    
% -----------------------Analysis---------------------------------
    
    T = tracks2cell(tracksFinal);       
    T_msd = msdAtTau(T, tauAna, detParam.DT, detParam.pxSize);
    [D, alpha] = diffCoeff(T_msd, tauAna, 2);
    DA = [D', alpha'];
    DAmean = nanmean(DA, 1);
    
% -----------------------Save Results------------------------------

    if isempty(tracksFinal)                 % If no tracks
        disp('No tracks detected to plot');
    else
                                            % Plot trajectories
        htracks = figure('Visible','off'); % OpenGL por hardware is faster
        imagesc(imadjust(I{1}))
        axis image off; colormap(gray(256))
        plotTracks2D(tracksFinal, [], '3', [], 0, 0, [], [], 0);
        title(movName, 'Interpreter', 'none','FontSize',16)
                                            % Save parameters 
        Tr_parameters = {['Maximum gap length: ', num2str(trackParam.gapCloseParam.timeWindow)];...
            ['Minimum track segment length: ', num2str(trackParam.gapCloseParam.minTrackLen)]};
        im = I{1};
                                            % Don't overwrite if exists
        if ~exist('tracksFinal.mat' ,'file')        
            parsave('tracksFinal.mat', tracksFinal, im, Tr_parameters,...
                DA, DAmean);
            
            DT = detParam.DT; pxSize = detParam.pxSize;
            parsave('T.mat', T, DT, pxSize)
                                            % Save to ascii
%             parsave('D_and_alpha.txt', DA, '-ascii')
%             parsave('mean_D_and_A.txt',DAmean, '-ascii')
%             saveASCII(tracksFinal)             

            print(htracks,'-dpng','-r200','Trajectories.png');
            close(htracks)
        end
    end
end

if VERBOSE
    toc
end

cd(PWD)


function saveASCII(tracksFinal)
% Save tracksFinal in Gianguido format
T = tracks2cellT(tracksFinal);      % Gaps are not interpolated.
for i=1:length(T)
    Tfilename = 'tracks.txt';
    M = [i*ones(length(T{i}),1) - 1, T{i}];
    
    if (exist(Tfilename,'file') ~= 2)
        dlmwrite(Tfilename, M, 'delimiter', '\t','precision', 6)
    elseif (exist(Tfilename,'file') == 2)
        dlmwrite(Tfilename, M,'-append','delimiter', '\t','precision', 6)
    end
end


function msd = msdAtTau(T, tauAna, DT, pxSize)
% tauAna - Tau at which MSD is calculated. In frames
% DT     - Time interval, in seconds
% pxSize - Pixel size in um

Nt = length(T);                             % Number of walkers
msd = cell(1,Nt);

for i = 1:Nt
    Np = size(T{i},1);
    msd{i} = zeros(tauAna,2);
    
    for dt = 1:tauAna                     % Time interval (Dt)
        
        lag = 1:(Np-dt);                    % Shift
                                            % Average of all shifted time windows of length dt
        meanRsq = mean(sum((T{i}(lag+dt,:) - T{i}(lag,:)).^2, 2));
        
        msd{i}(dt+1,1) = dt*DT;             % dt+1 to make first point cero
        msd{i}(dt+1,2) = pxSize^2*meanRsq;  
    end
end


