%%
% for the analysis of licking data
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e54/2020-12-28/1';
tlfile = dir(fullfile(directory, '*Timeline.mat'));
load(fullfile(tlfile(1).folder, tlfile(1).name), 'Timeline');

bfile = dir(fullfile(directory, '*Block.mat'));
load(fullfile(bfile(1).folder, bfile(1).name), 'block');

licks = diff(Timeline.rawDAQData(:,4)) > 2;
licktimes = Timeline.rawDAQTimestamps(licks);
feedback = block.events.feedbackValues;

% Plot rasters of the licks aligned to reward times
syncsignal = Timeline.rawDAQData(:,3);
dsync = diff(syncsignal);
rewardTimes = Timeline.rawDAQTimestamps(dsync > 2);

window = [-3 5]; %window around reward times to get the licks
lickAligned = {};

for i = 1:numel(rewardTimes)
    lickTrial = licktimes(licktimes > rewardTimes(i) + window(1) & ...
        licktimes < rewardTimes(i) + window(2));
    lickTrial = lickTrial - rewardTimes(i);
    lickAligned{i} = lickTrial;
    
end

figure;
h = subplot(121);
plotSpikeRaster(lickAligned(feedback > 0), 'PlotType','vertline')
title('Reward')
xlabel('Time (s)')
ylabel('Trial #')
set(gca, 'FontSize', 16)

h = subplot(122);
plotSpikeRaster(lickAligned(feedback == 0), 'PlotType','vertline')
title('No reward')
set(gca, 'FontSize', 16)
xlabel('Time (s)')
ylabel('Trial #')




