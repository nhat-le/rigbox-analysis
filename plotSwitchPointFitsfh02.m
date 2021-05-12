%% Load data
load fh02rigboxSwitchingFitsC.mat

% Group all sessions on the same date
currdate = nan;
alldeltasGrouped = {};
allsigmasGrouped = {};
datesGrouped = {};
% Because the data is already grouped, here we do not 
% perform the grouping code again

alldeltasGrouped = alldeltas;
allsigmasGrouped = allsigmas;




% for i = 1:numel(files)
%     currDelta = [];
%     currSigma = [];
%     if ~strcmp(files(i).name(1:10), currdate)
%         currDelta = alldeltas{i};
%         currSigma = allsigmas{i};
%         currdate = files(i).name(1:10);
%         if ~isnan(currdate)
%             alldeltasGrouped{end+1} = currDelta;
%             allsigmasGrouped{end+1} = currSigma;
%         end
%         datesGrouped{end+1} = files(i).name(1:10);
%     else
%         currDelta = [currDelta alldeltas{i}];
%         currSigma = [currSigma allsigmas{i}];
%     end
% end




%% Plot the results
figure;
meandeltas = [];
meansigmas = [];
subplot(121)
hold on
for i = 1:numel(alldeltasGrouped) 
    deltasGroup = alldeltasGrouped{i};
    deltasGroup(deltasGroup < -20 | deltasGroup > 100) = [];
    plot(ones(1,numel(deltasGroup)) * i, deltasGroup, 'bo');
    alldeltasGrouped{i} = deltasGroup;
    meandeltas(i) = nanmean(deltasGroup);
end
plot(meandeltas, 'r');

subplot(122)
hold on
for i = 1:numel(allsigmasGrouped)
    plot(ones(1,numel(allsigmasGrouped{i})) * i, allsigmasGrouped{i}, 'bo');
    sigmasGroup = allsigmasGrouped{i};
    sigmasGroup(sigmasGroup < -20 | sigmasGroup > 100) = [];
    allsigmasGrouped{i} = sigmasGroup;
    meansigmas(i) = nanmean(sigmasGroup);
end
plot(meansigmas, 'r');
% ylim([0 100])

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

figure;
stdshade(meanDeltasArr(:,~flag), 0.2, 'b')
hold on
plot([1 numel(alldeltasGrouped)], [0 0], 'k--', 'LineWidth', 2);
set(gca, 'FontSize', 16);
xlabel('Session #')
ylabel('Switch offset')
title('fh02 switching offset')


%% Plot all offsets over time
alldeltasArr = cell2mat(alldeltas);
sesslengths = cellfun(@(x) numel(x), alldeltas);
alldeltasArr(alldeltasArr < -20) = nan;
plot(alldeltasArr, 'o')
hold on
vline(cumsum(sesslengths))


%% Relationship between previous block lengths and switch times
figure;
prevRewards = [];
currSwitchTimes = [];
for i = 1:numel(alldeltas)
    blockstarts = allBlockStarts{i};
    blockLengths = diff(blockstarts);
    deltas = alldeltas{i};
    prevRewardLengths = blockLengths(1:end-2) - deltas(1:end-1);
    plot(prevRewardLengths, deltas(2:end), 'bo',...
        'MarkerFaceColor', 'b');
    hold on
    prevRewards = [prevRewards prevRewardLengths];
    currSwitchTimes = [currSwitchTimes deltas(2:end)];
end

% Do regression
goodids = find(prevRewards < 200 & currSwitchTimes < 200);
% currSwitchTimes = prev
mdl = fitlm(prevRewards(goodids), currSwitchTimes(goodids));

% Plot regression line
[ypred,yci] = predict(mdl, sort(prevRewards)');
plot(sort(prevRewards), ypred, 'r', 'LineWidth', 1.5);
plot(sort(prevRewards),  yci, 'r--', 'LineWidth', 1.5);


xlabel('# rewards (N-1)')
ylabel('Switch time (N)')
title('fh02')
xlim([-20 130])
set(gca, 'FontSize', 16)






