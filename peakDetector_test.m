
I = imread('/DIskC/Data/HIV_movies/detection_test_set/sas032211beads-F.03_R3D-1.tif');

figure, imshow(imadjust(I))

%%
peakDetector({I}, 16, 0, [])

%%
img = double(I)./((2^16)-1);
% sigma1 = 0.21*676/(1.4*322)
% sigma2 = sqrt(2)*5/2 
sigma1 = 1.5;
sigma2 = 4;
blurKernelHigh  = fspecial('gaussian', 21, sigma1);
blurKernelLow = fspecial('gaussian', 21, sigma2);

% use subfunction that calls imfilter to take care of edge effects
lowPass = imfilter(img,blurKernelLow);
highPass = imfilter(img,blurKernelHigh);

% get difference of gaussians image
filterDiff = highPass - lowPass;
figure,imshow(imadjust(filterDiff))

%%
e = edge(filterDiff, 'canny');
figure, imshow(e);
%%
radii = 1:0.5:5;
h = circle_hough(e, radii, 'same', 'normalise');
stackSlider(h), axis ij

%% Find some peaks in the accumulator
% We use the neighbourhood-suppression method of peak finding to ensure
% that we find spatially separated circles. We select the 10 most prominent
% peaks, because as it happens we can see that there are 10 coins to find.

peaks = circle_houghpeaks(h, radii, 'nhoodxy', 11, 'nhoodr', 5, 'Threshold',4);

%% Look at the results
% We draw the circles found on the image, using both the positions and the
% radii stored in the |peaks| array. The |circlepoints| function is
% convenient for this - it is also used by |circle_hough| so comes with it.
figure,
imshow(imadjust(img));
hold on;
for peak = peaks
    [x, y] = circlepoints(peak(3));
    plot(x+peak(1), y+peak(2), 'g-');
end
hold off

