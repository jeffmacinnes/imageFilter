function imageFilter(img_path, kSigma, kLocation)
%%% imageFilter
% 2D Gaussian spatial filtering for color images. User sets kernel width (in pixels) 
% and the location in frequency space (as percentage of image dimensions)
% Output image written to same directory as source image. 
% inputs:
%   img_path: path to image you want to filter
%   kSigma: width of the Gaussian kernel
%   kLocation: center coord for kernel (expressed as fraction of image dimension)
%      frequency space goes from 0-imageDimension/2, lowest to highest freq
%      e.g. 0 would center the filter kernel on the lowest spatial freq
%           0.5 would place the kernel in the center, selecting highest freq
% outputs:
%   filteredImage

% Load in image, create an empty output image
[imgColor, cmap] = imread(img_path);
imgFilt = zeros(size(imgColor), 'uint8');

% set up output 
[imgRoot, imgName, imgExt] = fileparts(img_path);
outputImg_path = fullfile(imgRoot, [imgName '_filtered' imgExt]);

% loop through each color channel
for c = 1:3
    
    % isolate this channel only
    imgChannel = imgColor(:,:,c);
    
    % 2D FFT of the original image
    ft = fft2(imgChannel);
    %imshow(abs(ft).^0.3, []);
    
    %%% spatial filtering
    % initialize mask
    [M,N] = size(ft);
    mask = zeros(M,N);          % mask will be the full image size
    
    % since 2D frequency space is symmetrical, define top left quadrant only
    [fy, fx] = ndgrid(0:M/2, 0:N/2);
    
    %%% define the filtering kernel
    % Gaussian kernel
    sigmaf = kSigma;      % kernel width
    filterCenter = [round(kLocation(1)*M) round(kLocation(2)*N)];
    filterShape = exp(-((fx-filterCenter(1)).^2+(fy-filterCenter(2)).^2)/(2*sigmaf)^2);
    
    % add the filter to all mask quadrants
    mask(1:M/2+1, 1:N/2+1) = filterShape;
    mask(1:M/2+1, N:-1:N/2+2) = mask(1:M/2+1, 2:N/2);
    mask(M:-1:M/2+2, :) = mask(2:M/2, :);
    
    % apply the filter to the mask, and take the inverse FFT to reconstruct img
    imgFilt(:,:,c) = ifft2(mask .* ft);
end

% match the histrogram of filtered image to original histogram
imgFilt = imhistmatch(imgFilt, imgColor);

% view image and filter
figure;
subplot(1,2,1); imshow(imgFilt, []); title('Filtered Image');
filterTitle = sprintf('2D filter mask\n sigma: %d\n center: (%.d,%.d)', kSigma, filterCenter(1), filterCenter(2));
subplot(1,2,2); imshow(mask); title(filterTitle);

% write image to disk
imwrite(imgFilt, outputImg_path);


end