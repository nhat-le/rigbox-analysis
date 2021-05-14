%% Example of how to get hardware info from json file
folderPath = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e53exampleSession';
info = jsondecode(fileread(fullfile(folderPath, '2021-02-25_1_e53_hardwareInfo.json')));


%%
% for analysis of wheel movement aligned to reward times
% directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e54/2020-12-28/1';
% directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e35/2020-12-31/1';
% directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/examplesubject-050621/4';
% good session:
% directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e43/2020-11-05/1';
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f05/2021-05-03/1';

bfile = dir(fullfile(directory, '*Block.mat'));
load(fullfile(bfile(1).folder, bfile(1).name), 'block');

feedbackTimes = block.events.feedbackTimes;
responseTimes = block.events.responseTimes;
stimOnTimes = block.events.stimulusOnTimes(1:numel(responses));

feedback = block.events.feedbackValues;
responses = block.events.responseValues;
target = block.events.contrastLeftValues * (-2) + 1; %1 for leftmovement target,
%-1 for rightmovement target (target == responses for correct trials)
target = target(1:numel(feedbackTimes));

pos = block.inputs.wheelMMValues;
tRaw = block.inputs.wheelMMTimes;

pos2 = block.inputs.wheelValues;
t2 = block.inputs.wheelTimes;

% Resample values
Fs = 1000; %frequency to resample at
t = 0:1/Fs:tRaw(end);
pos = interp1(tRaw, pos, t, 'linear');

%% Compute velocity
smoothSize = 0.03;
[vel, acc] = wheel.computeVelocity2(pos, smoothSize, Fs);

% Detecting the wheel movements
[onsets, offsets, displacement, peakVelTimes, peakAmps] = ...
  wheel.findWheelMovesWithRefs(pos, t, Fs, stimOnTimes, 'makePlots', true, 'posThresh', 3,...
    'tThresh', 0.2, 'minDur', 0.02);


%% Distribution of movement times aligned to stimOnset
stimOnTimes = block.events.stimulusOnTimes(1:numel(responses));
itis = [block.paramsValues.interTrialDelay];
% feedbackTimes = block.events.feedbackTimes;

mvTimesAligned = {};

for i = 1:numel(stimOnTimes) - 1
    currTime = stimOnTimes(i);
    nextTime = stimOnTimes(i+1);
    mvtimes = onsets(onsets > currTime & onsets < nextTime);
    if numel(mvtimes) > 0        
        mvTimesAligned{i} = mvtimes(1) - currTime;
    else
        mvTimesAligned{i} = -1;
    end
    
end

idx1 = find(itis == 0.5);
idx2 = find(itis == 0.75);
idx3 = find(itis == 1);

idx1(idx1 >= numel(stimOnTimes)-1) = [];
idx2(idx2 >= numel(stimOnTimes)-1) = [];
idx3(idx3 >= numel(stimOnTimes)-1) = [];


mvArr1 = mvTimesAligned(idx1 + 1);
mvArr2 = mvTimesAligned(idx2 + 1);
mvArr3 = mvTimesAligned(idx3 + 1);

mvArr1 = cell2mat(mvArr1');
mvArr2 = cell2mat(mvArr2');
mvArr3 = cell2mat(mvArr3');
allmv = cell2mat(mvTimesAligned');

edges = linspace(-1,10,100);
histogram(mvArr1, edges)
hold on
histogram(mvArr2, edges)
histogram(mvArr3, edges)



% mvTimesArr = cell2mat(mvTimesAligned');
% plot(rand(1, numel(mvTimesArr)), mvTimesArr, 'o');
% histogram(mvTimesArr);

%% Distribution of movement times aligned to prev reward

mvTimesAligned = {};
mvTimesAligned{1} = -1;
for i = 2:numel(stimOnTimes) - 1
    currTime = stimOnTimes(i);
    nextTime = stimOnTimes(i+1);
    mvtimes = onsets(onsets > currTime & onsets < nextTime);
    if numel(mvtimes) > 0        
        mvTimesAligned{i} = mvtimes' - feedbackTimes(i-1);
    else
        mvTimesAligned{i} = -1;
    end
    
end

idx1 = find(itis == 0.75);
idx2 = find(itis == 1);
idx3 = find(itis == 1.25);

idx1(idx1 >= numel(stimOnTimes)-1) = [];
idx2(idx2 >= numel(stimOnTimes)-1) = [];
idx3(idx3 >= numel(stimOnTimes)-1) = [];


mvArr1 = mvTimesAligned(idx1 + 1);
mvArr2 = mvTimesAligned(idx2 + 1);
mvArr3 = mvTimesAligned(idx3 + 1);

mvArr1 = cell2mat(mvArr1);
mvArr2 = cell2mat(mvArr2);
mvArr3 = cell2mat(mvArr3);
allmv = cell2mat(mvTimesAligned);

edges = linspace(-1,10,100);
histogram(mvArr1, edges)
hold on
histogram(mvArr2, edges)
histogram(mvArr3, edges)


%% 
dt = stimOnTimes(2:end) - feedbackTimes(1:end-1);
dt1 = dt(idx1);
dt2 = dt(idx2);
dt3 = dt(idx3);


% plot(sort(dt1));
% hold on
% plot(sort(dt2));
% plot(sort(dt3));

[~,idxITI] = sort(dt);
mvtimesITISort = mvTimesAligned(idxITI);


LineFormat = struct();
LineFormat.Color = [0.3 0.3 0.3];
LineFormat.LineWidth = 1;
% LineFormat.LineStyle = ':';
plotSpikeRaster(mvtimesITISort, 'PlotType', 'vertline', 'LineFormat', LineFormat,...
    'VertSpikeHeight', 5)
hold on
xlim([-3, 10])
xlabel('Time (s)')
ylabel('Trial #')
set(gca, 'FontSize', 16)

% where the block switch happens..
% switchPos = find(diff(block.events.contrastLeftValues) ~= 0);
% hline(switchPos)



%%
%Wait times
histogram(diff(onsets), edges)



%% Plot the wheel trace together with response times in the session
figure;
% ax = axes;
% hold(ax, 'on');
% plot(ax, wheelTimes, wheel)
% plotBlockStructure(ax,t2, pos2, target, feedbackTimes, responses, 'wheel')
% plot(ax,block.events.azimuthTimes, block.events.azimuthValues)
plot(t, pos);
hold on
% vline(feedbackTimes, 'b-')
vline(block.events.stimulusOnTimes, 'r-')
vline(block.events.stimulusOnTimes + [block.paramsValues.interactiveDelay], 'r--')

vline(block.events.responseTimes(block.events.responseValues == 1), 'b-')
vline(block.events.responseTimes(block.events.responseValues == -1), 'b--')


%% View the event triggered average of wheel position
window = [-1 2];
interactiveOnTimes = block.events.stimulusOnTimes + [block.paramsValues.interactiveDelay];
interactiveOnLeft = interactiveOnTimes(block.events.responseValues == -1);
interactiveOnRight = interactiveOnTimes(block.events.responseValues == 1);

[traceL, stdevL, allTracesL] = eventTrigAvgAllTraces(pos, interactiveOnLeft, window, Fs);
[traceR, stdevR, allTracesR] = eventTrigAvgAllTraces(pos, interactiveOnRight, window, Fs);
tpoints = linspace(window(1), window(2), numel(traceL));

% Set average pre-movement position to zero
premovL = allTracesL(:, tpoints < 0 & tpoints > -1);
premovR = allTracesR(:, tpoints < 0 & tpoints > -1);
meanpremovL = nanmean(premovL, 2);
meanpremovR = nanmean(premovR, 2);

allTracesL = allTracesL - meanpremovL;
allTracesR = allTracesR - meanpremovR;
traceL = mean(allTracesL);
traceR = mean(allTracesR);

figure;
subplot(121)
plot(tpoints, allTracesL', 'b');
hold on
plot(tpoints, traceL, 'r', 'LineWidth', 2);
vline(0, 'k')
title('Left movement')
xlabel('Time (s)')
ylabel('Wheel position')
set(gca, 'FontSize', 16);


subplot(122)
plot(tpoints, allTracesR', 'b');
hold on
plot(tpoints, traceR, 'r', 'LineWidth', 2);
vline(0, 'k')
title('Right movement')
xlabel('Time (s)')
ylabel('Speed')
set(gca, 'FontSize', 16);


%% Now plot the wheel movements aligned to movement onsets
onsetSubset = onsets;
offsetSubset = offsets;
dispSubset = displacement;
% diffonoff = offsetSubset - onsetSubset;
window = [-0.5 2];

onsetLeft = onsetSubset(dispSubset > 0);
onsetRight = onsetSubset(dispSubset < 0);


[traceL, stdevL, allTracesL] = eventTrigAvgAllTraces(pos, onsetLeft, window, Fs);
[traceR, stdevR, allTracesR] = eventTrigAvgAllTraces(pos, onsetRight, window, Fs);
tpoints = linspace(window(1), window(2), numel(traceL));

% Set wheel at t = 0 to zero
allTracesL = allTracesL - allTracesL(:, tpoints == 0);
allTracesR = allTracesR - allTracesR(:, tpoints == 0);
traceL = mean(allTracesL);
traceR = mean(allTracesR);

figure;
subplot(121)
plot(tpoints, allTracesL', 'b');
hold on
plot(tpoints, traceL, 'r', 'LineWidth', 2);
vline(0, 'k')
title('Left movement')
xlabel('Time (s)')
ylabel('Wheel pos')
set(gca, 'FontSize', 16);


subplot(122)
plot(tpoints, allTracesR', 'b');
hold on
plot(tpoints, traceR, 'r', 'LineWidth', 2);
vline(0, 'k')
title('Right movement')
xlabel('Time (s)')
ylabel('Wheel pos')
set(gca, 'FontSize', 16);


%% Histogram of distributions at 0.5s
posLdist = allTracesL(:, abs(tpoints - 0.4) < 0.0005);
posRdist = allTracesR(:, abs(tpoints - 0.4) < 0.0005);
histogram(posLdist, -40:5:40)
hold on
histogram(posRdist, -40:5:40)



%%
figure;
for i = 1:100
    subplot(10,10,i)
    plot(tpoints, allTracesL(i,:))
    ylim([-30 30])
    
end



%% Compare alignment with previous action
window = [-0.5 2];

feedbackTimes = block.events.feedbackTimes;
N = min([numel(feedbackTimes), numel(interactiveOnTimes), numel(block.events.responseValues)]);

nextResp = block.events.responseValues(2:N);
feedbackTimesNextLeft = feedbackTimes(nextResp == -1) + 2;
feedbackTimesNextRight = feedbackTimes(nextResp == 1) + 2;

[traceL, stdevL, allTracesL] = eventTrigAvgAllTraces(pos, feedbackTimesNextLeft, window, Fs);
[traceR, stdevR, allTracesR] = eventTrigAvgAllTraces(pos, feedbackTimesNextRight, window, Fs);
tpoints = linspace(window(1), window(2), numel(traceL));

% Set wheel at t = 0 to zero
allTracesL = allTracesL - allTracesL(:, tpoints == 0);
allTracesR = allTracesR - allTracesR(:, tpoints == 0);
traceL = mean(allTracesL);
traceR = mean(allTracesR);

figure;
subplot(121)
plot(tpoints, allTracesL', 'b');
hold on
plot(tpoints, traceL, 'r', 'LineWidth', 2);
vline(0, 'k')
title('Left movement')
xlabel('Time (s)')
ylabel('Wheel position')
set(gca, 'FontSize', 16);


subplot(122)
plot(tpoints, allTracesR', 'b');
hold on
plot(tpoints, traceR, 'r', 'LineWidth', 2);
vline(0, 'k')
title('Right movement')
xlabel('Time (s)')
ylabel('Speed')
set(gca, 'FontSize', 16);





function plotBlockStructure(ax, timg, dff, target, rewardTimes, responses, root)
sig = dff;
plot(ax, timg, sig);
hold on
% leftTimes = rewardTimes(responses == 1);
% rightTimes = rewardTimes(responses == -1);
% missTimes = rewardTimes(responses == 0);
for i = 1:numel(responses)
    if responses(i) == target(i)
        style = 'k';
    else
        style = 'k--';
    end
    
    plot(ax,[rewardTimes(i) rewardTimes(i)], [min(sig)*0.8 max(sig) * 0.8], style);
end

% Determine the block switch times
switchTrials = [1 find(diff(target) ~= 0) + 1 numel(target)]; %first trial of each block
switchTimes = rewardTimes(switchTrials);
blockTargets = target(switchTrials);

options = struct;
options.alpha = 0.2;
for i = 1:numel(switchTimes) - 1
    % Plot the blocks
    xmin = switchTimes(i);
    xmax = switchTimes(i + 1);
    ymin = min(sig);
    ymax = max(sig);
    x = [xmin xmax xmax xmin];
    y = [ymin ymin ymax ymax];
    if blockTargets(i) == 1
        options.color = 'b';
    else
        options.color = 'r';
    end
    plotBlockLines(ax, xmin, xmax, ymin, ymax, options);
end

plot(ax, timg, sig, 'b');
xlabel('Time (s)')
ylabel('df/f');
% title(sprintf('e46-unit%d-%s', unitid, root));
title(root);
set(gca, 'FontSize', 16);
end

function plotBlockLines(ax, xmin, xmax, ymin, ymax, options)
if ~isfield(options, 'alpha')
    alpha = 0.3;
else
    alpha = options.alpha;
end

if ~isfield(options, 'color')
    color = 'b';
else
    color = options.color;
end
x = [xmin xmax xmax xmin];
y = [ymin ymin ymax ymax];

plot(ax, [xmin xmin], [ymin ymax], color, 'LineWidth', 2);

% patch(x,y,color, 'FaceAlpha', alpha, 'EdgeColor', 'none')
end
