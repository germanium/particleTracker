% FALTA:
% -DONT REFRESH ALL TRAJ AT THE SAME TIME, USE HOLD ON, OR LINE() QUE ES MAS LOW LEVEL QUE
%    PLOT

function varargout = trajectories(varargin)
% TRAJECTORIES M-file for trajectories.fig
%      TRAJECTORIES, by itself, creates a new TRAJECTORIES or raises the existing
%      singleton*.
%
%      H = TRAJECTORIES returns the handle to a new TRAJECTORIES or the handle to
%      the existing singleton*.
%
%      TRAJECTORIES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRAJECTORIES.M with the given input arguments.
%
%      TRAJECTORIES('Property','Value',...) creates a new TRAJECTORIES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trajectories_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trajectories_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trajectories

% Last Modified by GUIDE v2.5 05-Feb-2010 17:05:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trajectories_OpeningFcn, ...
                   'gui_OutputFcn',  @trajectories_OutputFcn, ...
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


% --- Executes just before trajectories is made visible.
function trajectories_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
                                            % Load main UI data
mainGuiInput = find(strcmp(varargin, 'img_sequence'));
handles.main = varargin{mainGuiInput+1};    % store main GUI handles in the local handles
mainHandles = guidata(handles.main);
                                            % Set up slider properties
slider=findall(0,'Tag','slider1');
set(slider, 'Max', mainHandles.Nf,'Min', 1, 'Value', 1, 'SliderStep',...
    [1/mainHandles.Nf 5/mainHandles.Nf]);

% Set up the trajectories matrix
inputStructure = mainHandles.tracksFinal;
% Get number of tracks and number of time points
numTracks = length(mainHandles.tracksFinal);
tmp = vertcat(mainHandles.tracksFinal.seqOfEvents);
numTimePoints = max(tmp(:,1));
clear tmp
% Get number of segments making each track
numSegments = zeros(numTracks,1);
for i = 1 : numTracks
    numSegments(i) = size(inputStructure(i).tracksCoordAmpCG,1);
end
% If all tracks have only one segment ...
if max(numSegments) == 1
    
    % Indicate that there are no compound tracks with merging and splitting branches
    mergeSplit = 0;
    
    % Locate the row of the first track of each compound track in the
    % Big matrix of all tracks (to be constructed in the next step)
    % in this case of course every compound track is simply one track
    % without branches
    trackStartRow = (1:numTracks)';
    
    % Store tracks in a matrix
    trackedFeatureInfo = NaN(numTracks,8*numTimePoints);
    times = zeros(numTracks,2);
    for i = 1 : numTracks
        times(i,1) = inputStructure(i).seqOfEvents(1,1);        % Start time
        times(i,2)   = inputStructure(i).seqOfEvents(end,1);    % End time
        trackedFeatureInfo(i,8*(times(i,1)-1)+1:8*times(i,2)) = ...
            inputStructure(i).tracksCoordAmpCG;
    end
    
else %if some tracks have merging/splitting branches
    
    %indicate that in the variable mergeSplit
    mergeSplit = 1;
    
    %locate the row of the first track of each compound track in the
    %big matrix of all tracks (to be constructed in the next step)
    trackStartRow = ones(numTracks,1);
    for iTrack = 2 : numTracks
        trackStartRow(iTrack) = trackStartRow(iTrack-1) + numSegments(iTrack-1);
    end
    
    %put all tracks together in a matrix
    trackedFeatureInfo = NaN(trackStartRow(end)+numSegments(end)-1,8*numTimePoints);
    times = zeros(numTracks,2);
    for i = 1 : numTracks
        times(i,1) = inputStructure(i).seqOfEvents(1,1);        % Start time
        times(i,2)   = inputStructure(i).seqOfEvents(end,1);    % End time
        trackedFeatureInfo( trackStartRow(i):trackStartRow(i)+...
            numSegments(i)-1,8*(times(i,1)-1)+1:8*times(i,2) ) = ...
            inputStructure(i).tracksCoordAmpCG;
    end
end

% Save data in handles
                % Define colors to loop through in case colorTime = '2'
handles.colorLoop = [.8 .8 .8; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1]; %colors: k,r,g,b,y,m,c
handles.Isize = size(mainHandles.I{1});
                % Get the times, and x,y-coordinates of features in all tracks
handles.tracksX = trackedFeatureInfo(:,1:8:end)';
handles.tracksY = trackedFeatureInfo(:,2:8:end)';
handles.times = times;
                % First zoom includes the whole image
handles.zoomxy = [1 1; handles.Isize(2) handles.Isize(1)];
handles.trackStartRow = trackStartRow(end);         % matters if there are splitted tracks
handles.numSegments = numSegments(end);

    % plot trajectories 
imshow(mainHandles.Idisp{1});

guidata(hObject, handles);


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)

mainHandles = guidata(handles.main);                      % Load main UI data

t = round(get(hObject,'Value'));                          % Slider gives the time
hold all
imshow(mainHandles.Idisp{t});     % Max & min taken from 1st frame

% Select plot area (zoom), take the max/min since the zoom square
% can have different 1st and 2nd points
set(gca, 'XLim', [min(handles.zoomxy(:,1)) max(handles.zoomxy(:,1))],...
    'YLim', [min(handles.zoomxy(:,2)) max(handles.zoomxy(:,2))])

trkIndx = find(handles.times(:,1) < t & ...            % Index of tracks that begin 
               handles.times(:,2) > t)';                %  before the slider position
                                                        %  & and and after it.
for i = trkIndx                                      
    
    obsAvail = find(~isnan(handles.tracksX(1:t,i)));    % Aca obtiene los gap intervals
    % plot in dotted lines all non NaN points
    plot(handles.tracksX(obsAvail,i), handles.tracksY(obsAvail,i),'w:');
    % Plot in colored line all points up to time t
    plot(handles.tracksX(1:t,i), handles.tracksY(1:t,i),'color',...
        handles.colorLoop(mod(i-1,7)+1,:), 'marker','none');
end

clear inputStructure;


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --------------------------------------------------------------------
function uipushtool2_ClickedCallback(hObject, eventdata, handles)
% zoom out
set(gca, 'XLim', [1 handles.Isize(2)], 'YLim', [1 handles.Isize(1)])
handles.zoomxy = [1 1; handles.Isize(2) handles.Isize(1)];
guidata(hObject, handles);

% --------------------------------------------------------------------
function varargout = trajectories_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

% --------------------------------------------------------------------
function uipushtool3_ClickedCallback(hObject, eventdata, handles)
%zoom in
waitforbuttonpress;
point1 = get(gca,'CurrentPoint');                   % button down detected
rbbox;                                              % return figure units
point2 = get(gca,'CurrentPoint');                   % button up detected
handles.zoomxy = [point1(1,1:2);point2(1,1:2)];     % extract x and y
set(gca, 'XLim', [min(handles.zoomxy(:,1)) max(handles.zoomxy(:,1))],...
    'YLim', [min(handles.zoomxy(:,2)) max(handles.zoomxy(:,2))])
guidata(hObject, handles);
