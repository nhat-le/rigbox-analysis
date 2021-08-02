obj = VideoReader('C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Pupil_diameter_testing\F16pupil.avi');
NumberOfFrames = obj.NumFrames;
startFrame = 3;
refImage = read(obj,startFrame);
refImage=rgb2gray(refImage);
threshold = find_threshold(refImage, 'histAuto');
refImage = logical(refImage<threshold);

figure;
radius_lst = [];
%f = waitbar(0, 'Processing frames...');
subplot(131);
imshow(refImage);
title('Create mask');
message = sprintf('Left click and hold to begin drawing.\nSimply lift the mouse button to finish');
uiwait(msgbox(message));
hFH = imfreehand();
% Create a binary image ("mask") from the ROI object.
binaryImage = hFH.createMask();

for frame_id = startFrame:NumberOfFrames
    %waitbar(frame_id / NumberOfFrames, f, 'Processing frames...')
    frame=read(obj,frame_id);
    if size(frame,3)==3
        frame=rgb2gray(frame);
    end
    
    % Apply the drawn mask and modify by threshold
    threshold = find_threshold(frame, 'histAuto');
    processed_frame = logical(frame<threshold);
    processed_frame(binaryImage == 0) =0;
    subplot(131)
    title("Mask & threshold applied")
    imshow(processed_frame);
    
    % Connecting pixels and getting rid of noise
    processed_frame = imfill(processed_frame,'holes');
    processed_frame=bwmorph(processed_frame,'bridge');
    processed_frame=bwareaopen(processed_frame,5);
    processed_frame=bwmorph(processed_frame,'close');
    processed_frame=bwmorph(processed_frame,'open');
    processed_frame=bwareaopen(processed_frame,70);
    subplot(132)
    title("After bwmorph processing")
    imshow(processed_frame);
    
    % Finding the minbound circle
    [row, col] = find(processed_frame==1);
    [center, radius] =  minboundcircle(row, col);
    %radius_lst = [radius_lst radius];
    subplot(133);
    imshow(frame);
    title("Minbound circle")
    hold on
    viscircles(fliplr(center),radius);
    hold off
    sgtitle(['frame ' num2str(frame_id)]);
    drawnow;
    %waitforbuttonpress;
end

function threshold = find_threshold(frame, option, max)
    if strcmp(option,'modeInRange')
        threshold = mode(frame(frame<max));
    elseif strcmp(option,'manual')
        threshold = max;
    elseif strcmp(option,'histAuto')
        [N,E] = histcounts(frame);
        localMax = islocalmax(N);
        th = E(localMax);
        threshold = th(1);
    end
   
end
