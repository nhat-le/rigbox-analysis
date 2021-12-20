%% Basic session information
% good session:
% directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e43/2020-11-05/1';
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f05/2021-05-03/1';
% directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f12/2021-05-31/1';


bfile = dir(fullfile(directory, '*Block.mat'));
load(fullfile(bfile(1).folder, bfile(1).name), 'block');

feedbackTimes = block.events.feedbackTimes;
responseTimes = block.events.responseTimes;

feedback = block.events.feedbackValues;
responses = block.events.responseValues;
stimOnTimes = block.events.stimulusOnTimes(1:numel(responses));

N = min([numel(stimOnTimes), numel(feedbackTimes)]);
stimOnTimes = stimOnTimes(1:N);
feedbackTimes = feedbackTimes(1:N);

%-1 for rightmovement target (target == responses for correct trials)
target = block.events.contrastLeftValues * (-2) + 1; %1 for leftmovement target,
target = target(1:numel(feedbackTimes));

pos = block.inputs.wheelMMValues;
tRaw = block.inputs.wheelMMTimes;

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

leftOnsets = onsets(displacement > 0);
rightOnsets = onsets(displacement < 0);



%% Distribution of movement times aligned to stimOnset
[allmvOnsetAligned, mvTimesAlignedOnset] = getAlignedMvTimes(onsets, stimOnTimes, stimOnTimes);

[allmvOnsetLeftAligned, mvTimesLeftAlignedOnset] = getAlignedMvTimes(leftOnsets, stimOnTimes, stimOnTimes);
[allmvOnsetRightAligned, mvTimesRightAlignedOnset] = getAlignedMvTimes(rightOnsets, stimOnTimes, stimOnTimes);


%% Distribution of movement times aligned to prev reward
[allmvPrevRew, mvTimesAlignedPrevRew] = getAlignedMvTimes(onsets, feedbackTimes, feedbackTimes);
[allmvPrevRewLeftAligned, mvTimesLeftAlignedPrevRew] = getAlignedMvTimes(leftOnsets, feedbackTimes, feedbackTimes);
[allmvPrevRewRightAligned, mvTimesRightAlignedPrevRew] = getAlignedMvTimes(rightOnsets, feedbackTimes, feedbackTimes);



%% 
dt = stimOnTimes(2:end-1) - feedbackTimes(1:end-2);

[dtsorted,idxITI] = sort(dt);
mvtimesITISort = mvTimesAlignedPrevRew(idxITI);

mvtimesITISortLeft = mvTimesLeftAlignedPrevRew(idxITI);
mvtimesITISortRight = mvTimesRightAlignedPrevRew(idxITI);



LineFormat1 = struct();
LineFormat1.Color = [1 0 0];
LineFormat1.LineWidth = 1;


LineFormat2 = struct();
LineFormat2.Color = [0 0 1];
LineFormat2.LineWidth = 1;
% LineFormat.LineStyle = ':';
plotSpikeRaster(mvtimesITISortLeft, 'PlotType', 'vertline', 'LineFormat', LineFormat1,...
    'VertSpikeHeight', 1)
hold on
plotSpikeRaster(mvtimesITISortRight, 'PlotType', 'vertline', 'LineFormat', LineFormat2,...
    'VertSpikeHeight', 1)
xlim([-3, 10])
xlabel('Time (s)')
ylabel('Trial #')
set(gca, 'FontSize', 16)


%% Plot the wheel trace together with response times in the session
figure;

plot(t, pos);
hold on
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

function [allMv, mvTimesAligned] = getAlignedMvTimes(onsets, tpoints, refTimes)
mvTimesAligned = {};
mvTimesAligned{1} = -1;
for i = 1:numel(tpoints) - 1
    currTime = tpoints(i);
    nextTime = tpoints(i+1);
    mvtimes = onsets(onsets > currTime & onsets < nextTime);
    if numel(mvtimes) > 0        
        mvTimesAligned{i} = mvtimes' - refTimes(i);
    else
        mvTimesAligned{i} = nan;
    end
    
end

allMv = cell2mat(mvTimesAligned);

end