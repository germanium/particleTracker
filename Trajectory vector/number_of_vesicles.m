DIRS = {'*/CT*/cell_*.mat'; '*/HC1min*/cell_*.mat'; '*/HC5min*/cell_*.mat'; ...
    '*/HC10min*/cell_*.mat'; '*/HC20min*/cell_*.mat'};
BASE_DIR = '/home/alfajor/picasso/Documents/Data/hypercapnia_2011/1-17-11/';
cd(BASE_DIR)                                                    % Load all trajectory file's path
for i=1:length(DIRS)                                            % Iterate over all the conditions
    CELLS{i} = ls(DIRS{i}, '-m');                               % Get path of the cell*.mat files 
    CELLS{i} = regexp(CELLS{i}, ',', 'split');
    for j=1:length(CELLS{i})                                    % Get rid of the white space characters
        k = strfind(char(CELLS{i}{j}), ' ');
        CELLS{i}{j}(k) = [];
        k = strfind(char(CELLS{i}{j}), char(10));               % Get rid of other weird character
        CELLS{i}{j}(k) = [];
    end
end

number = cell(1,5);
for i=1:length(CELLS)
    number{i} = [];
    for j=1:length(CELLS{i})
        load([BASE_DIR,CELLS{i}{j}], 'Tall');
        number{i} = [number{i} , length(Tall.i0j0)];
    end
end

T1Label = 'Control';
T2Label = '1'' post-hyper';
T3Label = '5'' post-hyper';
T4Label = '10'' post-hyper';
T5Label = '20'' post-hyper';
  
T1CL = number{1};                                           % Contourlengths
T2CL = number{2};
T3CL = number{3};
T4CL = number{4};
T5CL = number{5};

figure;                                                     % bar plots
barerror((1:5)',[mean(T1CL); mean(T2CL); mean(T3CL); mean(T4CL); mean(T5CL)],...
    [std(T1CL)/sqrt(length(T1CL)); std(T2CL)/sqrt(length(T2CL)); ...
    std(T3CL)/sqrt(length(T3CL)); std(T4CL)/sqrt(length(T4CL)); std(T5CL)/sqrt(length(T5CL))], ...
    1,'b','k', {[T1Label,': ',num2str(mean(T1CL),3)], [T2Label,': ',num2str(mean(T2CL),3)]...
    [T3Label,': ',num2str(mean(T3CL),3)], [T4Label,': ',num2str(mean(T4CL),3)]...
    [T5Label,': ',num2str(mean(T5CL),3)] });
title('Number of vesicles at the perisfery','FontSize',12)