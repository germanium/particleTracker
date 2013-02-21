function varargout = img_sequence(varargin)
% IMG_SEQUENCE M-file for img_sequence.fig
%      IMG_SEQUENCE, by itself, creates a new IMG_SEQUENCE or raises the existing
%      singleton*.
%
%      H = IMG_SEQUENCE returns the handle to a new IMG_SEQUENCE or the handle to
%      the existing singleton*.
%
%      IMG_SEQUENCE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMG_SEQUENCE.M with the given input arguments.
%
%      IMG_SEQUENCE('Property','Value',...) creates a new IMG_SEQUENCE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before img_sequence_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to img_sequence_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help img_sequence

% Last Modified by GUIDE v2.5 01-Nov-2012 11:39:54
% *Notes*
% 1) arreglar el gap closing en la imagen final

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @img_sequence_OpeningFcn, ...
                   'gui_OutputFcn',  @img_sequence_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


% End initialization code - DO NOT EDIT

function Menu_Callback(hObject, eventdata, handles)


% --- Outputs from this function are returned to the command line.
function varargout = img_sequence_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;


%% --- Executes just before img_sequence is made visible.
function img_sequence_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for img_sequence
handles.output = hObject;                                        
handles.PathName = '/DIskC/Data/';  % Default initial directory 
handles.fr = 1;                         % Starting frame
addpath('~/Documents/MATLAB/figure_tools/',...
    '~/Documents/MATLAB/file_tools/')

guidata(hObject, handles);


%% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)

fr = round(get(hObject,'Value'));           % Get slider position (current frame)
htext = findall(0,'Tag','text1');           % Display frame #
set(htext,'String',['Frame # ' num2str(fr)]);

imshow(handles.Idisp{fr});
hold on
if isfield(handles,'movieInfo')             % Only show detected points after detection
    for i=1:size(handles.movieInfo(fr).xCoord,1)
        R = sqrt(handles.movieInfo(fr).amp(i,1)/pi);    % Calculate R from area
        circle([handles.movieInfo(fr).xCoord(i,1), ...
                handles.movieInfo(fr).yCoord(i,1)], R, 30 , 'g');
    end
end
                                            
handles.fr = fr;                            % Save current frame to handles
guidata(hObject, handles);



% -------------Load Images-----------------------------
function load_img_Callback(hObject, ~, handles)

[ImgFileName,ImgPathName] = uigetfile({'*.tif';'*.stk';'*.dv';'*.avi';'*.*'}, ...
    'Select images', 'MultiSelect', 'on');
cd(ImgPathName) 

if ~iscell(ImgFileName)                     % If tif file is a movie
    data = bfopen([ImgPathName ImgFileName]);
    data = data{1};
    Nfr = size(data,1);                     % # of frames
    
    if ~isempty(strfind(data{3,2},'C=3/3')) % If it's RGB convert to gray
        Nfr = Nfr/3;
        I = cell(1,Nfr);
        Idisp = cell(Nfr,1);
        k = 1;
        for i=1:3:Nfr*3
            I1 = cat(3, data{i:(i+2),1});
            I{k} = rgb2gray(I1);
            Idisp{k} = imadjust(I{k}, stretchlim(I{k}, [0.01 0.995]));
            k = k+1;
        end
        
    else                                    % If gray don't convert   
        I = cell(1,Nfr);
        Idisp = cell(Nfr,1);
        for i=1:Nfr
            I{i} = data{i,1};
            Idisp{i} = imadjust(I{i}, stretchlim(I{i}, [0.01 0.995]));
        end
    end
    
    clear data
    [~, handles.FileName] = fileparts(ImgFileName); 
    
else                                        % If each tif is a frame
    Nfr = length(ImgFileName);              % # of frames
    I = cell(Nfr,1);
    Idisp = cell(Nfr,1);
    for i=1:Nfr
        I{i} = imread([ImgPathName,ImgFileName{i}]);
        Idisp{i} = imadjust(I{i}, stretchlim(I{i}, [0.01 0.995]));
    end
                                            % For 3 digits is -8
    handles.FileName = ImgFileName{1}(1:(end-7));   
end

if isdir(handles.FileName)
    warning(['Folder ' handles.FileName ' already exist'])
    cd(handles.FileName)
else
    mkdir(handles.FileName);                    % To save results in a new folder
    cd(handles.FileName)
end

axes('position',[0.2938  0.0642  0.6983  0.8523])

imshow(Idisp{1})
htext = findall(0,'Tag','text1');          % Display frame #
set(htext,'String','Frame # 1');

slider = findall(0,'Tag','slider1');
set(slider, 'Max', Nfr,'Min', 1, 'Value', 1, 'SliderStep', [1/Nfr 5/Nfr]);

handles.PathName = ImgPathName;
handles.Nf = Nfr;
handles.I = I;
handles.Idisp = Idisp;

if isfield(handles,'movieInfo')             % Clear movieInfo
    handles = rmfield(handles,'movieInfo');                         
end

guidata(hObject, handles);




% Load all tifs in folder
function Load_all_Callback(hObject, ~, handles)
FILES = dir('*.tif'); 
Nf = length(FILES);                         % Nuber of frames

I = cell(Nf,1);
Idisp = cell(Nf,1);
for i=1:Nf
    I{i} = imread(FILES(i).name);    
    Idisp{i} = imadjust(I{i}, stretchlim(I{i}, [0.01 0.995]));
end
                                            % Set the position of the image
axes('Position',[0.2938  0.0642  0.6983  0.8523])

imshow(Idisp{i})
htext = findall(0,'Tag','text1');          % Display frame #
set(htext,'String','Frame # 1');

slider=findall(0,'Tag','slider1');
set(slider, 'Max', Nf,'Min', 1, 'Value', 1, 'SliderStep', [1/Nf 5/Nf]);
                                            % for 3 digits is -8
handles.FileName = FILES(1).name(1:(end-7));  
handles.PathName = pwd;
handles.Nf = Nf;
handles.I = I;
handles.Idisp = Idisp;

if isfield(handles,'movieInfo')             % Clear movieInfo
    handles = rmfield(handles,'movieInfo');                         
end

guidata(hObject, handles);



% --- Executes on button press in apply_detection.
function apply_detection_Callback(hObject, ~, handles)
Nf = length(handles.I);

bitDepth = str2double(get(handles.edit_bitDepth, 'String'));
maxArea = str2double(get(handles.edit_area, 'String'));
minEcce = str2double(get(handles.edit_ecce, 'String'));

if (get(handles.ROIcheck,'Value'))
    ROI_dialog();
    handles.BW = roipoly();
    for i=1:Nf
        handles.I{i} = handles.BW.*handles.I{i};
    end
    imshow(handles.Idisp{1});
end

if get(handles.detection_popup,'Value') == 1        % Use DoG      
    movieInfo = peakDetector(handles.I, bitDepth, maxArea, minEcce, true);
    
else                                                % Use multiscale products
    % initialize structure to store info for tracking
    [movieInfo(1:Nf,1).xCoord] = deal([]);
    [movieInfo(1:Nf,1).yCoord] = deal([]);
    [movieInfo(1:Nf,1).amp] = deal([]);
    % trackCloseGapsKalmanSparse only uses xCoord y yCoord
    
    progressText(0, 'Detecting peaks')
    for i=1:Nf
        frameInfo = spotDetector(double(handles.I{i}));
        movieInfo(i,1).xCoord = frameInfo.xCoord;
        movieInfo(i,1).yCoord = frameInfo.yCoord;
        movieInfo(i,1).amp = [frameInfo.area zeros(length(frameInfo.area))];
        progressText(i/Nf, 'Detecting peaks')
    end
end

imshow(handles.Idisp{1});
hold on
for i=1:size(movieInfo(1).xCoord,1)
    R = sqrt(movieInfo(1).amp(i,1)/pi);
    circle([movieInfo(1,1).xCoord(i,1), ...
            movieInfo(1,1).yCoord(i,1)], R, 30 , 'g');
end
hold off

handles.movieInfo = movieInfo;
handles.bitDepth = bitDepth;
handles.maxArea = maxArea;
handles.minEcce = minEcce;
guidata(hObject, handles);


% --- Executes on button press in AnalyzeFrame.
function AnalyzeFrame_Callback(~, ~, handles)

fr = handles.fr; 
bitDepth = str2double(get(handles.edit_bitDepth, 'String'));
area = str2double(get(handles.edit_area, 'String'));
ecce = str2double(get(handles.edit_ecce, 'String'));

movieInfo = peakDetector(handles.I(fr), bitDepth, area, ecce, true);

imshow(handles.Idisp{fr});
hold on
for i=1:size(movieInfo.xCoord,1)
    R = sqrt(movieInfo.amp(i,1)/pi);        % Calculate R from area
    circle([movieInfo.xCoord(i,1), ...
            movieInfo.yCoord(i,1)], R, 30 , 'g');
end
hold off


% --- Executes on button press in apply_track.
function apply_track_Callback(hObject, ~, handles)

% Cost functions
    % Frame-to-frame linking
costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
    % Gap closing, merging and splitting
costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';

% Kalman filter functions
    % Memory reservation
kalmanFunctions.reserveMem = 'kalmanResMemLM';
    % Filter initialization
kalmanFunctions.initialize = 'kalmanInitLinearMotion';
    % Gain calculation based on linking history
kalmanFunctions.calcGain = 'kalmanGainLinearMotion';
    %Time reversal for second and third rounds of linking
kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';

% General tracking parameters

    % Gap closing time window. Depends on SNR and fluorophore blinking. Critical
    %  if too small or too large. Robust in proper range (default 10 frames)
gapCloseParam.timeWindow = str2num(get(findall(0,'Tag','gapClose_edit'), 'String'));
    % Flag for merging and splitting
MergeCheck = findall(0,'Tag','MergeCheck');
gapCloseParam.mergeSplit = get(MergeCheck,'Value');

    % Minimum track segment length used in the gap closing, merging and
    %  splitting step. Excludes short tracks from participatin in the gap
    %  closing, mergin and splitting step.
gapCloseParam.minTrackLen = str2num(get(findall(0,'Tag','edit7'), 'String'));

    % Time window diagnostics: 1 to plot a histogram of gap lengths in
    %  the end of tracking, 0 or empty otherwise
gapCloseParam.diagnostics = 1;

% Cost function specific parameters: Frame-to-frame linking
% Flag for motion model, 0 for only random motion;
%                        1 for random + directed motion;
%                        2 for random + directed motion with the
% possibility of instantaneous switching to opposite direction (but 
% same speed),i.e. something like 1D diffusion.
linearH = findall(0,'Tag','linear_popup');
parameters.linearMotion = get(linearH,'Value') - 1;
    % Search radius lower limit
parameters.minSearchRadius = 2;
    % Search radius upper limit
parameters.maxSearchRadius = str2num(get(findall(0,'Tag','edit11'), 'String'));
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
% saveResults = 0;                              % don't save results
    % Verbose
verbose = 1;
    % Problem dimension
probDim = 2;

% tracking function call
[tracksFinal,~,~] = trackCloseGapsKalmanSparse(handles.movieInfo,...
    costMatrices,gapCloseParam,kalmanFunctions,probDim,saveResults,verbose);

% Plot trajectories 
    % Plot split as a white dash-dotted line
    % Plot merge as a white dashed line
    % Place circles at track starts and squares at track ends
if isempty(tracksFinal)   
    disp('No tracks detected to plot');
    return
else
    
    handles.tracksFinal = tracksFinal;                  % Need tracksFinal in handles
    guidata(hObject, handles);                          % for scrollbar window
    trajectories('img_sequence', handles.mainUI);       % Scrollbar window
    
    htracks = plotTracks2D(tracksFinal, [], '3', [], 0, 1, handles.Idisp{1}, [], 0);
    title({handles.PathName,handles.FileName},'Interpreter','none')
end

% Save tracking parameteres
                    
param.det.bitDepth = handles.bitDepth;              % Detection parameters
param.det.maxArea =  handles.maxArea;
param.det.minEcce = handles.minEcce;

param.tr.maxGapLength = gapCloseParam.timeWindow;   % Tracking param
param.tr.minSegmentLength = gapCloseParam.minTrackLen;
param.tr.maxSearchRadius = costMatrices(2).parameters.maxSearchRadius;

im = handles.I{1};                                  % Movie data
movieInfo = handles.movieInfo;
T = tracks2cell(tracksFinal);

assignin('base','tracksFinal',tracksFinal)          % Save to workspace 
assignin('base','im',im)
assignin('base','Tr_parameters', param)

if ~exist([saveResults.dir,'/tracksFinal.mat'] ,'file') % Don't overwrite if exists
    save('tracksFinal.mat', 'tracksFinal', 'im', 'param');
    save('T.mat', 'T')
    save('detections.mat', 'movieInfo')
    print(gcf,'-dpng','-r200','Trajectories.png');
else                                                    % If file exists in the folder 
    overwrite = overwrite_dialog();                     % it's in the trajectory vector folder
    if overwrite
        save('tracksFinal.mat', 'tracksFinal', 'im', 'param');
        save('T.mat', 'T')
        save('detections.mat', 'movieInfo')
        print(gcf,'-dpng','-r200','Trajectories.png');
    else
        disp('Didn''t save tacksFinal.mat, a file with that name already exists')
    end
end


% --------------------Cage Diameter-------------------------
function cage_diameter_Callback(~, ~, handles)
window = 20;
CD = cell(length(handles.T), 1);
for i=1:length(handles.T)
    for j=1:(length(handles.T{i}(:,1)) - window)
        for k=1:window
            aux(k) = sqrt( (handles.T{i}(j+k,1)-handles.T{i}(j,1))^2 ...
                + (handles.T{i}(j+k,2)-handles.T{i}(j,2))^2 );
        end
        CD{i}(j) = max(aux);
    end
end
                        
figure                  % plot cage diameters 
n = 10;                 % number of traj to analyse
for i=1:n
    subplot(n,1,i)
    colorplot(CD{i});
end


% --- Executes on selection change in detection_popup.
function detection_popup_Callback(hObject, eventdata, handles)
% hObject    handle to detection_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns detection_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from detection_popup

method = get(hObject,'Value');
if method == 1
    set(handles.text_area, 'Visible', 'on')
    set(handles.text_ecce, 'Visible', 'on')
    set(handles.edit_area, 'Visible', 'on')
    set(handles.edit_ecce, 'Visible', 'on')

elseif method ==2
    set(handles.text_area, 'Visible', 'off')
    set(handles.text_ecce, 'Visible', 'off')
    set(handles.edit_area, 'Visible', 'off')
    set(handles.edit_ecce, 'Visible', 'off')
end


%% Unused UI functions ------------------------------------------------------------

function edit8_Callback(~, ~, ~)

function analysis_Callback(~, ~, ~)

% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, ~, ~)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)


function edit9_Callback(~, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, ~)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit10_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MergeCheck.
function MergeCheck_Callback(hObject, ~, ~)

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, ~, handles)


function gapClose_edit_Callback(~, eventdata, ~)


function gapClose_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit7_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ROIcheck.
function ROIcheck_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_bitDepth_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%--- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox1_CreateFcn(hObject, eventdata, handles)
set(hObject,'Value',0)

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function edit_bitDepth_Callback(hObject, eventdata, handles)

function edit11_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LinealCheck.
function LinealCheck_Callback(hObject, eventdata, handles)


% --- Executes on button press in DetectDotsCheck.
function DetectDotsCheck_Callback(hObject, eventdata, handles)


% --- Executes on button press in PlotAlphaCheck.
function PlotAlphaCheck_Callback(hObject, eventdata, handles)


function edit4_Callback(hObject, eventdata, handles)


function edit5_Callback(hObject, eventdata, handles)


% --- Executes on selection change in linear_popup.
function linear_popup_Callback(hObject, eventdata, handles)
% hObject    handle to linear_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns linear_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from linear_popup


% --- Executes during object creation, after setting all properties.
function linear_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to linear_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function detection_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detection_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_area_Callback(hObject, eventdata, handles)
% hObject    handle to edit_area (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_area as text
%        str2double(get(hObject,'String')) returns contents of edit_area as a double


% --- Executes during object creation, after setting all properties.
function edit_area_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_area (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ecce_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ecce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ecce as text
%        str2double(get(hObject,'String')) returns contents of edit_ecce as a double


% --- Executes during object creation, after setting all properties.
function edit_ecce_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ecce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
