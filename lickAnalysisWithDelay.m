%%
% for the analysis of licking data
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e50/2021-01-11/1';
tlfile = dir(fullfile(directory, '*Timeline.mat'));
load(fullfile(tlfile(1).folder, tlfile(1).name), 'Timeline');

bfile = dir(fullfile(directory, '*Block.mat'));
load(fullfile(bfile(1).folder, bfile(1).name), 'block');

licks = diff(Timeline.rawDAQData(:,4)) > 2;
licktimes = Timeline.rawDAQTimestamps(licks);
feedback = block.events.feedbackValues;

feedbackTimesBlock = block.events.feedbackTimes;
responseTimesBlock = block.events.responseTimes(1:end);
rewardDelay = feedbackTimesBlock - responseTimesBlock;

threshold = max(rewardDelay) / 2;



% Plot rasters of the licks aligned to reward times
syncsignal = Timeline.rawDAQData(:,3);
dsync = diff(syncsignal);
rewardTimes = Timeline.rawDAQTimestamps(dsync > 2);
responseTimes = rewardTimes - rewardDelay;

window = [-3 5]; %window around reward times to get the licks
lickAligned = {};

for i = 1:numel(rewardTimes)
    lickTrial = licktimes(licktimes > responseTimes(i) + window(1) & ...
        licktimes < responseTimes(i) + window(2));
    lickTrial = lickTrial - responseTimes(i);
    lickAligned{i} = lickTrial;
    
end

figure;
h = subplot(121);
arrCorrLate = lickAligned(feedback > 0 & rewardDelay > threshold);
arrIncorrLate = lickAligned(feedback == 0 & rewardDelay > threshold);
plotSpikeRaster(arrCorrLate, 'PlotType','vertline');
title('No reward late (1s)')
xlabel('Time (s)')
ylabel('Trial #')
set(gca, 'FontSize', 16)

h = subplot(122);
arrCorrEarly = lickAligned(feedback > 0 & rewardDelay < threshold);
arrIncorrEarly = lickAligned(feedback == 0 & rewardDelay < threshold);
plotSpikeRaster(arrCorrEarly, 'PlotType','vertline');
title('No reward early (0s)')
set(gca, 'FontSize', 16)
xlabel('Time (s)')
ylabel('Trial #')


%% Get the average lick rate ('PSTH')
binWidth = 0.1;
bins = window(1) : binWidth : window(2);
hIL = histogram(cell2mat(arrIncorrLate), bins);
avgLicksIL = hIL.Values / numel(arrIncorrLate) / binWidth;

hIE = histogram(cell2mat(arrIncorrEarly), bins);
avgLicksIE = hIE.Values / numel(arrIncorrEarly) / binWidth;

hCL = histogram(cell2mat(arrCorrLate), bins);
avgLicksCL = hCL.Values / numel(arrCorrLate) / binWidth;

hCE = histogram(cell2mat(arrCorrEarly), bins);
avgLicksCE = hCE.Values / numel(arrCorrEarly) / binWidth;

figure;
l1 = plot(bins(2:end), avgLicksIL, 'r');
hold on
l2 = plot(bins(2:end), avgLicksIE, 'r--');
l3 = plot(bins(2:end), avgLicksCL, 'b');
l4 = plot(bins(2:end), avgLicksCE, 'b--');

legend([l1, l2, l3, l4], {'Incor. late', 'Incor. Early', 'Corr. late', 'Corr. early'});
set(gca, 'FontSize', 16);
xlabel('Time (s)')
ylabel('Lick rate (per s)');











