load F03rigboxSwitchingFits.mat

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




%% Plot the results
figure;
hold on
meandeltas = [];
for i = 1:numel(alldeltasGrouped)
    plot(ones(1,numel(alldeltasGrouped{i})) * i, alldeltasGrouped{i}, 'bo');
    meandeltas(i) = nanmean(alldeltasGrouped{i});
end
plot(meandeltas, 'r');


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
title('F01 switching offset')





