function varargout = trajectory_vector(varargin)
% TRAJECTORY_VECTOR M-file for trajectory_vector.fig
%      TRAJECTORY_VECTOR, by itself, creates a new TRAJECTORY_VECTOR or raises the existing
%      singleton*.
%
%      H = TRAJECTORY_VECTOR returns the handle to a new TRAJECTORY_VECTOR or the handle to
%      the existing singleton*.
%
%      TRAJECTORY_VECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRAJECTORY_VECTOR.M with the given input arguments.
%
%      TRAJECTORY_VECTOR('Property','Value',...) creates a new TRAJECTORY_VECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trajectory_vector_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trajectory_vector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trajectory_vector

% Last Modified by GUIDE v2.5 01-Feb-2011 14:25:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trajectory_vector_OpeningFcn, ...
                   'gui_OutputFcn',  @trajectory_vector_OutputFcn, ...
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


% --- Executes just before trajectory_vector is made visible.
function trajectory_vector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trajectory_vector (see VARARGIN)

% Choose default command line output for trajectory_vector
handles.output = hObject;

addpath('~/Documents/MATLAB/traj_tools/')     

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = trajectory_vector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LoadTrajectoryButton.=============================================
function LoadTrajectoryButton_Callback(hObject, eventdata, handles)

if exist('tracksFinal.mat','file')
    handles.trajpath = [pwd '/' 'tracksFinal.mat'];
    
else
    [TrajFileName,TrajPathName] = uigetfile('*.mat','Select the trajectories data');
    handles.trajpath = [TrajPathName,TrajFileName];
    cd(TrajPathName)
end

set(handles.TrajPathString,'String',handles.trajpath);

guidata(hObject, handles);


% --- Executes on button press in select_ROI.=======================================================
function select_ROI_Callback(hObject, eventdata, handles)
% Any trajectory with less frames than the threshold won't be considered
frThreshold = str2double(get(handles.frThreshold,'String'));
A = load(handles.trajpath);

traj = tracks2cell(A.tracksFinal);      % Convert tracksFinal to cell array

traj = trajFilter(traj,frThreshold);    % Remove trajectories smaller than frThreshold

fig = figure('Name',['Trajectory Vectors - ',...    
    handles.trajpath],'NumberTitle','off');
A.im = double(A.im);
I = imadjust(A.im./max(A.im(:)));
imshow(I);
hold all, trajPlot(traj), hold off

%ROI_dialog();              
BW = roipoly;%(I);                            % Segment cell
k = 1;
for i=1:length(traj)
    %if first point of trajectory is inside ROI include trajectory
    a = round(traj{i}(1,1));
    b = round(traj{i}(1,2));
    if (a == 0)                             % Convert point (0,0) to (1,1)
        a = 1; 
    elseif (b == 0) 
        b = 1; 
    elseif (BW(b, a))
        i0j0(k,:) = traj{i}(1,:);           % first point of the trajectory
        vect(k,:) = traj{i}(end,:) - traj{i}(1,:);
        vectNorm(k) = norm(vect(k,:));
        trajROI{k} = traj{i};
        k = k + 1;
    end
end

imshow(I); hold on                          % Clear previous image
quiver(i0j0(:,1), i0j0(:,2), vect(:,1), vect(:,2),'r');
title('Unfiltered Trajectory vectors')
% normalize vectors
% Save global data, Ta: all traj inside the ROI
handles.I = I;
handles.BW = BW;                            % Cell area 
handles.Ta.traj.ij = trajROI;               % traj inside the ROI 
handles.Ta.i0j0 = i0j0;                     % first point of the traj
handles.Ta.traj.vectNorm = vectNorm;        % Norm of the vector
handles.Ta.traj.vect = vect;                % direction of the vector?
handles.fig = fig;                          % microscopy image
handles.Ta.traj.N = length(trajROI);        % number of traj inside ROI

guidata(hObject, handles);


% ====Vector Analysis=====================================================================
function vect_analysis_Callback(hObject, eventdata, handles)
linFlag = get(findall(0,'Tag','asymcheck'), 'Value');

if (linFlag)                   % load data
    vect = handles.Tl.traj.vect;
    Minusi = handles.Tl.traj.Minusi;
    Plusi = handles.Tl.traj.Plusi;
    N = length(handles.Tl.traj.ij);
    i0j0 = handles.Tl.i0j0;
else
    vect = handles.Ta.traj.vect;
    Minusi = handles.Ta.traj.Minusi;
    Plusi = handles.Ta.traj.Plusi;
    N = length(handles.Ta.traj.ij);
    i0j0 = handles.Ta.i0j0;
end

for i=1:N                                                    % calculate vector length
    vectNorm(i) = norm(vect(i,:));
end

vectH = figure('Name', ['Plus & Minus end trajectories - ',...     % Show +/-end vectors
    handles.trajpath]); 
imshow(handles.I);
hold on
quiver(i0j0(Plusi,1), i0j0(Plusi,2), ...
    vect(Plusi,1), vect(Plusi,2) , 'g');
quiver(i0j0(Minusi,1), i0j0(Minusi,2), ...
    vect(Minusi,1), vect(Minusi,2) , 'r');  
if isfield(handles, 'x0')
    plot(handles.x0, handles.y0, 'x')
end
if linFlag
    title('Assymetric vectors: plus-end green, minus-end red')
else
    title('Asymmetric and symmetric vectors')
    xlabel('Symmetric: plus-end cyan, minus-end yellow ; Asymmetric: plus-end green, minus-end red')
end

x = 1:round(max(vectNorm))+1;                            % Vector Statistics
meanVN = mean(vectNorm);
medianVN = median(vectNorm);
modeVN = mode(vectNorm);
vectPlusNorm = vectNorm(Plusi);
vectMinusNorm = vectNorm(Minusi);
meanVP = mean(vectPlusNorm);
medianVP = median(vectPlusNorm);
modeVP = mode(vectPlusNorm);
meanVM = mean(vectMinusNorm);
medianVM = median(vectMinusNorm);
modeVM = mode(vectMinusNorm);
%save vectstat meanVN medianVN modeVN meanVP medianVP modeVP meanVM medianVM modeVM
figure('Name',['Vector Statistics - ', handles.trajpath]);

subplot(3,1,1)                                          % All vectors
n = hist(vectNorm, x);
[~,i] = max(n);
hist(vectNorm, x);
title(['Mean: ', num2str(meanVN), ', Median: ',num2str(medianVN), ', Mode: ',...
    num2str(x(i)), ', Number of Trajectories: ', num2str(length(vectNorm))])
xlabel('Vector length (pixels) - All trajectories')
ylabel('# of vesicles')

subplot(3,1,2)                                          % Plus end vectors
n = hist(vectPlusNorm, x);
[~,i] = max(n);
hist(vectPlusNorm, x)
title(['Mean: ', num2str(meanVP), ',  Median: ',num2str(medianVP), ...
    ',  Mode: ', num2str(x(i)), ', Number of Trajectories: ', num2str(length(vectPlusNorm))])
xlabel(['Trajectory length (pixels) - Plus end trajectories','   (', ...
    int2str(length(vectPlusNorm)*100/N), '% of all vesicles)'])
ylabel('# of vesicles')

subplot(3,1,3)                                          % Minus end vectors
n = hist(vectMinusNorm, x);
[~,i] = max(n);
hist(vectMinusNorm, x)
title(['Mean: ', num2str(meanVM), ',  Median: ',num2str(medianVM),...
    ',  Mode: ', num2str(x(i)),  ', Number of Trajectories: ', num2str(length(vectMinusNorm))])
xlabel(['Vector length (pixels) - Minus end trajectories','   (', ...
    int2str(length(vectMinusNorm)*100/N), '% of all vesicles)'])
ylabel('# of vesicles')



% --- Trajectory analysis===========================================================================
% Plots the (+) and (-) end trajectories, and calculates the distribution of it's length
function traj_analysis_Callback(hObject, eventdata, handles)
% load data
linFlag = get(findall(0,'Tag','asymcheck'), 'Value');
if (linFlag)
    traj = handles.Tl.traj.ij;
    Minusi = handles.Tl.traj.Minusi;
    Plusi = handles.Tl.traj.Plusi;
    N = length(handles.Tl.traj.ij);
else
    traj = handles.Ta.traj.ij;
    Minusi = handles.Ta.traj.Minusi;
    Plusi = handles.Ta.traj.Plusi;
    N = length(handles.Ta.traj.ij);
end
 
trajCL = zeros(N,1);                                    % Calculate contourlength (not smoothed)
k = 1;
for i=1:N
    aux = 0;
    for j=1:(length(traj{i}(:,1))-1)                    % Number of trajectory points
        aux = norm(traj{i}(j+1,:)-traj{i}(j,:));
        trajCL(i) = trajCL(i) + aux;
    end
end

trajSmooth = cell(1,N);                                 % Smoothing of the trajectories
for i=1:N
    trajSmooth{i}(:,1) = smooth(traj{i}(:,1));
    trajSmooth{i}(:,2) = smooth(traj{i}(:,2));
end

trajH = figure('Name',['Trajectories - ',handles.trajpath]);    % Plot +/- end smoothed trajectories 
imshow(handles.I)
hold all
for i=Plusi
    if ~linFlag     % si no se filtra las simetricas, diferenciar entre sym y asym
        if handles.asyFlag(i)  
            plot(trajSmooth{i}(:,1), trajSmooth{i}(:,2),'g')
        else
            plot(trajSmooth{i}(:,1), trajSmooth{i}(:,2),'c')
        end
    else
        plot(trajSmooth{i}(:,1), trajSmooth{i}(:,2),'g')
    end
end
for i=Minusi
    if (~linFlag)   % si no se filtra las simetricas, diferenciar entre sym y asym
        if handles.asyFlag(i)  
            plot(trajSmooth{i}(:,1), trajSmooth{i}(:,2),'r')
        else
            plot(trajSmooth{i}(:,1), trajSmooth{i}(:,2),'y')
        end
    else
        plot(trajSmooth{i}(:,1), trajSmooth{i}(:,2),'r')
    end
end
if isfield(handles, 'x0')                           % Plot minus end origin
    plot(handles.x0, handles.y0, 'x')
end
if linFlag                                  % Title 
    title('Assymetric trajectories: plus-end green, minus-end red')
else
    title('Assymetric and symmetric trajectories')
    xlabel('Symetric: plus-end cyan, minus-end yellow ; Asymmetric: plus-end green, minus-end red')
end

x = 1:2:round(max(trajCL)) + 1;                     % statics for the raw trajectories
meanTN = mean(trajCL);
medianTN = median(trajCL);
modeTN = mode(trajCL);
meanTP = mean(mean(trajCL(Plusi)));
medianTP = median(trajCL(Plusi));
modeTP = mode(trajCL(Plusi));
meanTM = mean(trajCL(Minusi));
medianTM = median(trajCL(Minusi));
modeTM = mode(trajCL(Minusi));
%save trajstat meanTN medianTN modeTN meanTP medianTP modeTP meanTM medianTM modeTM
figure('Name',['Trajectory Statistics - ',handles.trajpath]);

subplot(3,1,1)                                      % All trajectories
n = hist(trajCL, x);
[~,i] = max(n);
hist(trajCL, x)
title(['Mean: ', num2str(meanTN), ',  Median: ',num2str(medianTN), ...
    ',  Mode: ', num2str(x(i)), ', Number of Trajectories: ', num2str(length(trajCL))])
xlabel('Trajectory contourlength (pixels) - All trajectories')
ylabel('# of occurrences')

subplot(3,1,2)                                      % Plus end trajectories
n = hist(trajCL(Plusi), x);
[~,i] = max(n);
hist(trajCL(Plusi), x)
title(['Mean: ', num2str(meanTP), ',  Median: ',num2str(medianTP), ...
    ',  Mode: ', num2str(x(i)), ', Number of Trajectories: ', num2str(length(trajCL(Plusi)))])
xlabel('Trajectory contourlength (pixels) - Plus end trajectories')
ylabel('# of occurrences')

subplot(3,1,3)                                      % Minus end trajectories
n = hist(trajCL(Minusi), x);
[~,i] = max(n);
hist(trajCL(Minusi), x)
title(['Mean: ', num2str(meanTM), ',  Median: ',num2str(medianTM), ...
    ',  Mode: ', num2str(x(i)), ', Number of Trajectories: ', num2str(length(trajCL(Minusi)))])
xlabel('Trajectory contourlength (pixels) - Minus end trajectories')
ylabel('# of occurrences')



% --- Executes on button press in Apply.================================================================
function Apply_Callback(hObject, eventdata, handles)   
% Minus end point selection
asymPercent = str2double(get(handles.edit6,'String'));  %percentile above which is considered asymetric
pntFlag = get(handles.radio_point,'Value');
nuclFlag = get(handles.radio_nucleus,'Value');
manFlag = get(handles.radio_manual, 'Value');
phiThresh = str2double(get(handles.edit1,'String'))*pi/180;

if (pntFlag == 1)                   % Minus end point selection
    %minus_end_dialog();
    [handles.x0, handles.y0] = getpts(figure(handles.fig));
elseif (nuclFlag == 1)              % Minus end cell nucleus selection
    figure(handles.fig)             % deberia incluir un dialog
    BW = roipoly(handles.I);
    L = bwlabel(BW);
    s = regionprops(L, 'centroid');
    handles.x0 = s.Centroid(1);
    handles.y0 = s.Centroid(2);
end
                                                       % Polarity of all segments   
[handles.Ta.seg.Plusi, handles.Ta.seg.Minusi] = Polarity(handles.Ta.traj.ij, ...
    handles.x0, handles.y0, phiThresh, 1);
                                                       % Polarity of all trajectories   
[handles.Ta.traj.Plusi, handles.Ta.traj.Minusi] = Polarity(handles.Ta.traj.ij, ...
    handles.x0, handles.y0, phiThresh, 0);
 
handles.asyFlag = false(1,handles.Ta.traj.N);          % Calculate asymmetry of the whole trajectory
for i=1:handles.Ta.traj.N
    [~,handles.asyFlag(i)] = asym(handles.Ta.traj.ij{i}, length(handles.Ta.traj.ij{i}), asymPercent); 
end
                                                       % Get lineal tracks
handles.Tl.traj.ij = handles.Ta.traj.ij(handles.asyFlag);
                                                       % Polarity of lineal trajectories   
[handles.Tl.traj.Plusi, handles.Tl.traj.Minusi] = Polarity(handles.Tl.traj.ij, ...
    handles.x0, handles.y0, phiThresh, 0);
                                                       % Polarity of the segments in the lineal tracks   
handles.Tl.seg.Minusi = handles.Ta.seg.Minusi(handles.asyFlag);     
handles.Tl.seg.Plusi = handles.Ta.seg.Plusi(handles.asyFlag); 

handles.Tl.i0j0 = handles.Ta.i0j0(handles.asyFlag,:);
handles.Tl.traj.N = length(handles.Tl.i0j0);
handles.Tl.traj.vect = handles.Ta.traj.vect(handles.asyFlag,:);


handles.segH = figure('Name', ...                              % Plot lineal +/-end segments
    ['Plus & Minus end segments - ', handles.trajpath]); 
imshow(handles.I);
hold on
for i=1:length(handles.Tl.seg.Plusi)
    for j=handles.Tl.seg.Plusi{i} 
        plot([handles.Tl.traj.ij{i}(j,1), handles.Tl.traj.ij{i}(j+1,1)],...
            [handles.Tl.traj.ij{i}(j,2), handles.Tl.traj.ij{i}(j+1,2)], 'g');
    end
end
for i=1:length(handles.Tl.seg.Minusi)
    for j=handles.Tl.seg.Minusi{i} 
        plot([handles.Tl.traj.ij{i}(j,1),handles.Tl.traj.ij{i}(j+1,1)],...
            [handles.Tl.traj.ij{i}(j,2), handles.Tl.traj.ij{i}(j+1,2)], 'r');
    end
end
axis equal 
if isfield(handles, 'x0')                                       % Plot minus end origin
    plot(handles.x0, handles.y0, 'x')
end
title('Segments from lineal trajectories: plus-end green, minus-end red','FontSize',11)

handles.trajH = figure('Name',['Trajectories - ',handles.trajpath]);    % Plot +/- end lineal trajectories 
imshow(handles.I)
hold all
for i=handles.Tl.traj.Plusi
    plot(handles.Tl.traj.ij{i}(:,1), handles.Tl.traj.ij{i}(:,2),'g')
end
for i=handles.Tl.traj.Minusi
    plot(handles.Tl.traj.ij{i}(:,1), handles.Tl.traj.ij{i}(:,2),'r')
end
axis equal
if isfield(handles, 'x0')                                       % Plot minus end origin
    plot(handles.x0, handles.y0, 'x')
end
title('Lineal trajectories: plus-end green, minus-end red','FontSize',11)

guidata(hObject, handles);                                      % save global data to handles
set(handles.vect_analysis, 'Enable', 'on')                      % Enable plot buttons
set(handles.traj_analysis, 'Enable', 'on')

    
% --- Otherwise, executes on mouse press in 5 pixel border or over quiver.==========================
function quiver_ButtonDownFcn(hObject, eventdata, GUIhandle)
handles = guidata(GUIhandle);
if linFlag                                                      % If the linear checkbox is checked
    % find is about 16 times faster than using a FOR loop. Multiply arrays to do AND.
    selectionType = get(gcf, 'SelectionType');
    if strcmp(selectionType, 'normal')                          % select minus-end
        handles.Tl.Minusi(length(handles.Tl.Minusi) + 1) = ...
            find((handles.Tl.i0j0(:,1)==get(gco,'XData')).*(handles.Tl.i0j0(:,2)==get(gco,'YData')));
        set(hObject,'Color','r')
    elseif strcmp(selectionType,'alt')                          % select plus-end
        handles.Tl.Plusi(length(handles.Tl.Plusi) + 1) = ...
            find((handles.Tl.i0j0(:,1)==get(gco,'XData')).*(handles.Tl.i0j0(:,2)==get(gco,'YData')));
        set(hObject,'Color','g')
    end
else
    selectionType = get(gcf, 'SelectionType');
    if strcmp(selectionType, 'normal')                          % select minus-end
        handles.Ta.Minusi(length(handles.Ta.Minusi) + 1) = ...
            find((handles.Ta.i0j0(:,1)==get(gco,'XData')).*(handles.Ta.i0j0(:,2)==get(gco,'YData')));
        set(hObject,'Color','r')
    elseif strcmp(selectionType,'alt')                          % select plus-end
        handles.Ta.Plusi(length(handles.Ta.Plusi) + 1) = ...
            find((handles.Ta.i0j0(:,1)==get(gco,'XData')).*(handles.Ta.i0j0(:,2)==get(gco,'YData')));
        set(hObject,'Color','g')
    end
end
guidata(GUIhandle, handles);


% --- Executes on button press in save_workspace.===================================================
function save_workspace_Callback(hObject, eventdata, handles)
% Save to workspace
evalin('base', 'clear Tall Tlin');
assignin('base','Tall',handles.Ta)
assignin('base','Tlin',handles.Tl)


% --- Executes on button press in save_to_disk.
function save_to_disk_Callback(hObject, eventdata, handles)
% save(get(handles.file_name,'String'),'-struct', 'handles', 'Ta', 'Tl')
Tall = handles.Ta;
Tlin = handles.Tl;
BW = handles.BW;
x0y0 = [handles.x0, handles.y0];
param = {['Frame threshold: ', get(handles.frThreshold,'String')];...
    ['Asymmetry Percentile: ', get(handles.edit6,'String')];...
    ['Angle threshold: ', get(handles.edit1,'String')]};
fileName = get(handles.file_name,'String');
if ~exist([fileName,'.mat'],'file')
    save(fileName, 'Tall', 'Tlin', 'param', 'BW', 'x0y0');
else
    overwrite = overwrite_dialog();
    if overwrite
        save(fileName, 'Tall', 'Tlin', 'param', 'BW', 'x0y0');
    end
end
if isfield(handles, 'trajH')                             % Check if the vector figure handle exists
    print(handles.trajH,'-dpng ',[fileName,'_traj']);    % Save vector figure
end
if isfield(handles, 'segH')                              % Check if the segment figure handle exists
    print(handles.segH,'-dpng ',[fileName,'_seg']);      % Save segments figure
end


%===================================================================================================
%===================================================================================================
% --- Executes on button press in radio_nucleus.
function radio_nucleus_Callback(~, ~, ~)

% --- Executes on button press in radio_point.
function radio_point_Callback(~, ~, ~)

function pixels_Callback(~, ~, ~)

function edit1_Callback(~, ~, ~)

% --- Executes during object creation, after setting all properties.
function pixels_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function frThreshold_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function frThreshold_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in asymcheck. It filters the trajectories. 
function asymcheck_Callback(hObject, eventdata, handles)

function file_name_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function file_name_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit6_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
