clear all
% [a,b]= readtext('C:\Program Files\MATLAB71\work\postfsk2 032607.txt', ' ', '%', '', 'numeric');
% %get start and end point of every particle in every frame
% index = isnan(a(:,1));          
% j = 2;
% % first sample
% points(1,1:2) = a(1, 2:3); 
% for i=2:(length(a(:,1))-1)
%     if ( (index(i+1) && index(i+2)) || (index(i-1) && index(i-2)) )
%         points(j,1:2) = a(i, 2:3);
%         j = j + 1;
%     end
% end
% points(j, 1:2) = a(length(a(:,1)), 2:3);


%New approach
fid = fopen('C:\Users\Hello\Documents\MATLAB\postfsk2 032607.txt');
C = textscan(fid, '%u8 %f %f %*f %*f %*s','commentStyle', '%%');
%traj{k}(i,j) each cell k represents a trajectory composed of points (i,j)
traj{1}(1,1) = C{2}(1);
traj{1}(1,2) = C{3}(1);
k = 1;
j = 1;
for i=2:length(C{1,1})
    if( C{1}(i) < C{1}(i-1) )
        k = k + 1;
        j = 1;    
        traj{k}(j,1) = C{2}(i);
        traj{k}(j,2) = C{3}(i);
    else
        j = j + 1;
        traj{k}(j,1) = C{2}(i);
        traj{k}(j,2) = C{3}(i);
    end
end
%take positions and trajectory vectors from every particle
Ntraj = length(traj);
ij = zeros(Ntraj, 2);
vect = zeros(Ntraj, 2);
vectNorm = zeros(Ntraj,1);
for i = 1:Ntraj
    ij(i,:) = traj{i}(1,:);
    vect(i,:) = traj{i}(end,:) - traj{i}(1,:);
    vectNorm(i) = norm(vect(i,:));
end

    
    

% %take positions and trajectory vectors from every particle
% j=1;
% ij = zeros(Ntraj, 2);
% for k=1:2:length(points(:,1))
%     %ij initial positions of particles from top left corner
%     ij(j,:) = points(k,1:2);                   
%     vect(j,:) = points(k+1,1:2) - points(k,1:2);
%     vectNorm(j) = norm(vect(j,:));
%     j=j+1;
% end

%normalize vectors
%vectNormal = vect/max(vectNorm);



I = imread('C:\Users\Hello\Documents\MATLAB\postfsk2 032607.tif');
I = imadjust(I);
figure
imshow(I);
hold on
quiver(ij(:,2), ij(:,1), vect(:,2), vect(:,1) , 'r');
title('Trajectory vectors - Select Cell')

BW = roipoly
k = 1;
for i=1:Ntraj
    if (BW(round(ij(i,1)), round(ij(i,2))))
        ijROI(k,:) = ij(i,:);
        vectROI(k,:) = vect(i,:);
        k = k + 1;
    end
end
hold on
quiver(ijROI(:,2), ijROI(:,1), vectROI(:,2), vectROI(:,1) , 'r');


% number of slices
N = 30;                                                                    
theta = 2*pi/N;
thetaarray = 0:theta:2*pi-theta;
% Get cell (-) end 
[x0,y0] = getpts;  
% sets radious of the displayed vectors
R = 70;                            
% origin is at top left corner
[xslice,yslice] = pol2cart(thetaarray,R);   
% centered at (-) end
xslice = xslice + x0;                                                      
yslice = yslice + y0;

% Slices    
vectsum = zeros(N,2);
IJ = zeros(N,2);
for i=1:N                                                                  
    sum = [0,0];
    normsum = 0;
    possum = 0;
    for j=1:Ntraj
        % If vector is inside current slice
        if (abs(atan360(x0, xslice(i), y0, yslice(i)) - atan360(x0, ij(j,2), y0, ij(j,1))) <= theta/2)
            % Add vectors (average direction)
            sum = sum + vect(j,:); 
            % Get centroid terms
            normi = vectNorm(j);
            normsum = normi + normsum;
            possum = normi * ij(j,:) + possum;
        end
    end
    vectsum(i,:) = sum;
    % Calculate centroid
    if (normsum == 0)
        normsum = NaN;
    else
        IJ(i,:) = (1/normsum) * possum;
    end
end


figure 
imshow(I);
hold on
%quiver(xslice', yslice', vectsum(:,2), vectsum(:,1), 'b')
quiver(IJ(:,2), IJ(:,1), vectsum(:,2), vectsum(:,1), 'g')
title('Average of trajectories over angular slices')



% Calculate polarity of trajectories
j = 1;
m = 1;
% maximum angle that is considered to be (+) or (-) end directed
rho = pi/4;
for i=1:Ntraj
    % angle between vector, and radial vector pointing to the initial point
    % of the trajectory
    phi = atan360(x0, ij(i,2), y0, ij(i,1)) - atan360(ij(i,2), traj{i}(end,2), ij(i,1), traj{i}(end,1));
    if (abs(phi) <= rho)
        vectPlusi(j) = i; 
        ijPlus(j,:) = ij(i,:);
        vectPlusNorm(j) = vectNorm(i);
        j = j + 1;
    end
    if (abs(phi) > (pi - rho) && abs(phi) < (pi + rho))
        vectMinusi(m) = i;
        ijMinus(m,:) = ij(i,:);
        vectMinusNorm(m) = vectNorm(i);
        m = m + 1;
    end
end
%Show (+) and (-) end trajectories
figure
imshow(I);
hold on
quiver(ijPlus(:,2), ijPlus(:,1), vect(vectPlusi,2), vect(vectPlusi,1) , 'b');
quiver(ijMinus(:,2), ijMinus(:,1), vect(vectMinusi,2), vect(vectMinusi,1) , 'g');


%Vector Statistics
x = 1:round(max(vectNorm))+1;
figure
subplot(3,1,1)
hist(vectNorm, x)
title('Vector histogram of all trajectories')
xlabel('Vector length(pixels)')
ylabel('# of occurrences')
subplot(3,1,2)
hist(vectPlusNorm, x)
title('Vector histogram of (+) end trajectories')
xlabel('Vector length(pixels)')
ylabel('# of occurrences')
subplot(3,1,3)
hist(vectMinusNorm, x)
title('Vector histogram of (-) end trajectories')
xlabel('Vector length(pixels)')
ylabel('# of occurrences')


% Smoothing of the trajectories
trajSmooth = cell(1,Ntraj);
for i=1:Ntraj
    trajSmooth{i}(:,1) = smooth(traj{i}(:,1));
    trajSmooth{i}(:,2) = smooth(traj{i}(:,2));
end

%Plot smoothed trajectories goint to the (+) or (-) end 
figure
imshow(I)
hold all
for i=vectPlusi
    plot(trajSmooth{i}(:,2), trajSmooth{i}(:,1),'Color','g')
end
for i=vectMinusi
    plot(trajSmooth{i}(:,2), trajSmooth{i}(:,1),'Color','r')
end
title('Filtered trajectories, (+) end green, (-) end red')

%Plot unfiltered trajectories
figure
imshow(I)
hold all
for i=1:Ntraj
    line(traj{i}(:,2), traj{i}(:,1),'Color','r')
end


%Calculate length of the trajectories
trajNorm = zeros(Ntraj,1);
for i=1:Ntraj
    aux = 0;
    for j=1:(length(traj{i}(:,1))-1)
        aux = norm(traj{i}(j+1,:)-traj{i}(j,:));
        trajNorm(i) = trajNorm(i) + aux;
    end   
end
%statics of the smoothed trajectories
x = 1:2:round(max(trajNorm))+1;
figure
subplot(3,1,1)
hist(trajNorm, x)
title('Trajectory histogram of all trajectories')
xlabel('Trajectory length(pixels)')
ylabel('# of occurrences')
subplot(3,1,2)
hist(trajNorm(vectPlusi), x)
title('Trajectory histogram of (+) end trajectories')
xlabel('Trajectory length(pixels)')
ylabel('# of occurrences')
subplot(3,1,3)
hist(trajNorm(vectMinusi), x)
title('Trajectory histogram of (-) end trajectories')
xlabel('Trajectory length(pixels)')
ylabel('# of occurrences')

%Trajectory linearity test
for i=1:Ntraj
    for j=1:trajSmooth{i}(:,1)
        stepNorm = norm(trajSmoot{i}(j+1,:) - trajSmoot{i}(j,:));
        if 
        
        
        


