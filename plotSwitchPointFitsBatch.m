summaryFiles = dir('*Fits.mat');

plotopts.plot = 0;
grandmeans = {};

figure;
hold on
for i = 1:numel(summaryFiles)
    load(fullfile(summaryFiles(i).folder, summaryFiles(i).name));

    [alldeltasGrouped, allsigmasGrouped] = findmeanSwitching(files, alldeltas, allsigmas);
    [meanDeltasArr, flag] = plotstdshade(alldeltasGrouped, plotopts);
    grandmean = nanmean(meanDeltasArr(:,~flag));
    plot(grandmean);
    grandmeans{i} = grandmean;
end

%% Aggregate and plot
nEntries = cellfun(@(x) numel(x), grandmeans);
maxN = max(nEntries);
grandmeanArr = nan(numel(grandmeans), maxN);
for i = 1:numel(grandmeans)
    grandmeanArr(i, 1:nEntries(i)) = grandmeans{i};
end

plotopts.plot = 1;
grandAggregate = nanmean(grandmeanArr, 1);
plot(grandmeanArr')
hold on
% plot(grandAggregate, 'r', 'LineWidth', 2)
stdshade(grandmeanArr, 0.5, 'b')
xlim([1,20])
ylim([-5 30])
set(gca, 'FontSize', 16);
xlabel('Session #')
ylabel('Mean switching time (trials)')



function [meanDeltasArr, flag] = plotstdshade(alldeltasGrouped, options)
%% Using stdshade
% Concat into an array
% Determine the max dimension of the array
maxdim = 0;
flag = zeros(1, numel(alldeltasGrouped));
for i = 1:numel(alldeltasGrouped)
    if numel(alldeltasGrouped{i}) > maxdim
        maxdim = numel(alldeltasGrouped{i});
    end
    
    if isempty(alldeltasGrouped{i})
        flag(i) = 1;
    end
end

meanDeltasArr = nan(maxdim, numel(alldeltasGrouped));
for i = 1:numel(alldeltasGrouped)
    L = numel(alldeltasGrouped{i});
    meanDeltasArr(1:L,i) = alldeltasGrouped{i};
end

if options.plot
    stdshade(meanDeltasArr(:,~flag), 0.2, 'b')
    hold on
    plot([1 numel(alldeltasGrouped)], [0 0], 'k--', 'LineWidth', 2);
    set(gca, 'FontSize', 16);
    xlabel('Session #')
    ylabel('Switch offset')
    title(options.title)
end
end

function [alldeltasGrouped, allsigmasGrouped] = findmeanSwitching(files, alldeltas, allsigmas)
%% Group all sessions on the same date
currdate = nan;
alldeltasGrouped = {};
allsigmasGrouped = {};
datesGrouped = {};

for i = 1:numel(files)
    currDelta = [];
    currSigma = [];
    if ~strcmp(files(i).name(1:10), currdate)
        currDelta = alldeltas{i};
        currSigma = allsigmas{i};
        currdate = files(i).name(1:10);
        if ~isnan(currdate)
            alldeltasGrouped{end+1} = currDelta;
            allsigmasGrouped{end+1} = currSigma;
        end
        datesGrouped{end+1} = files(i).name(1:10);
    else
        currDelta = [currDelta alldeltas{i}];
        currSigma = [currSigma allsigmas{i}];
    end
end

end








