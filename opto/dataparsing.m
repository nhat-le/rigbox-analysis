% Pull the latest opto log
% fprintf('Updating the opto log...\n');
% commandStr = '/Users/minhnhatle/Documents/ExternalCode/rigbox_analysis/notebooks/src/opto_pull.py';
% [status, commandOut] = system(commandStr);
% if status == 0
%     disp(commandOut);
% else
%     error('Error updating the log files!')
% end

%%
T = readtable('logs/sessionlog.csv');
method = 1;

% define inclusion criteria
animals = {'F27', 'F26', 'F29'};
areas = {'motor'};
powertype =  '5+'; % '10+' means higher than 10

%filter
filt1 = ismember(T.Animal, animals) & ismember(T.Area, areas);
thres = str2double(powertype(1:end-1));
if powertype(end) == '+'
    filt2 = T.Power > thres;
else
    filt2 = T.Power < thres;
end

Tfilt = T(filt1 & filt2, :);


%% Iterate
titlestr = 'f26 ACC opto';

rigbox = '/Volumes/GoogleDrive/Other computers/ImagingDESKTOP-AR620FK/LocalExpData';
savefolder = '/Volumes/GoogleDrive/Other computers/ImagingDESKTOP-AR620FK/LocalExpData';
          
allBlocks = src.parsedata_helper(Tfilt, rigbox);

%% Visualize single block switches
trialside = allBlocks.events.trialSideValues;
feedback = allBlocks.events.feedbackValues;
optovals = allBlocks.events.optoblockValues;
blockinit = allBlocks.events.blockInit;

%break into blocks
blockstarts = find(blockinit);
blocksides = trialside(blockstarts);
blockopto = optovals(blockstarts);

blockstarts = [blockstarts numel(blockinit) + 1];
feedbackcell = {};
for i = 1:numel(blockstarts) - 1
    blockfb = feedback(blockstarts(i) : blockstarts(i+1) - 1);
    feedbackcell{i} = blockfb;
end

% get array of feedbacks and split to blocks
arr = src.pad_to_same_length(feedbackcell);

% For display
arr(isnan(arr)) = -0.5;
arrOptoL = arr(blocksides == -1 & blockopto == 1,:);
arrOptoR = arr(blocksides == 1 & blockopto == 1,:);
arrNoOptoL = arr(blocksides == -1 & blockopto == 0,:);
arrNoOptoR = arr(blocksides == 1 & blockopto == 0,:);
arrall = {arrOptoL, arrOptoR, arrNoOptoL, arrNoOptoR};
titles = {'opto L', 'opto R', 'no opto L', 'no opto R'};

figure;
for i = 1:4
    subplot(2,2,i)
    imagesc(arrall{i});
    colormap gray
    title(titles{i})
end

%% Combine and average
if method
    arrOptoL(arrOptoL < 0) = 1;
    arrOptoR(arrOptoR < 0) = 1;
    arrNoOptoL(arrNoOptoL < 0) = 1;
    arrNoOptoR(arrNoOptoR < 0) = 1;

    NoptoblocksL = size(arrOptoL, 1);
    NnonoptoblocksL = size(arrNoOptoL, 1);
    NoptoblocksR = size(arrOptoR, 1);
    NnonoptoblocksR = size(arrNoOptoR, 1);

    countsOL = NoptoblocksL - nansum(arrOptoL, 1);
    countsOR = NoptoblocksR - nansum(arrOptoR, 1);
    countsNL = NnonoptoblocksL - nansum(arrNoOptoL, 1);
    countsNR = NnonoptoblocksR - nansum(arrNoOptoR, 1); 

else
    %% Alternative combine and average
    arrOptoL(arrOptoL < 0) = nan;
    arrOptoR(arrOptoR < 0) = nan;
    arrNoOptoL(arrNoOptoL < 0) = nan;
    arrNoOptoR(arrNoOptoR < 0) = nan;

    NoptoblocksL = sum(~isnan(arrOptoL), 1);
    NnonoptoblocksL = sum(~isnan(arrNoOptoL), 1);
    NoptoblocksR = sum(~isnan(arrOptoR), 1);
    NnonoptoblocksR = sum(~isnan(arrNoOptoR), 1);
    
    countsOL = sum(~isnan(arrOptoL), 1) - nansum(arrOptoL, 1);
    countsOR = sum(~isnan(arrOptoR), 1) - nansum(arrOptoR, 1);
    countsNL = sum(~isnan(arrNoOptoL), 1) - nansum(arrNoOptoL, 1);
    countsNR = sum(~isnan(arrNoOptoR), 1) - nansum(arrNoOptoR, 1);
    
end
Noptoblocks = NoptoblocksL + NoptoblocksR;
Nnonoptoblocks = NnonoptoblocksL + NnonoptoblocksR;
countsO = countsOL + countsOR;
countsN = countsNL + countsNR;

    
errorlocs = 1:size(arr, 2);

pOL = countsOL ./ NoptoblocksL;
pNL = countsNL ./ NnonoptoblocksL;
pOR = countsOR ./ NoptoblocksR;
pNR = countsNR ./ NnonoptoblocksR;
pO = countsO ./ Noptoblocks;
pN = countsN ./ Nnonoptoblocks;

errorsOL = sqrt(pOL .* (1 - pOL) ./ NoptoblocksL);
errorsNL = sqrt(pNL .* (1 - pNL) ./ NnonoptoblocksL);
errorsOR = sqrt(pOR .* (1 - pOR) ./ NoptoblocksR);
errorsNR = sqrt(pNR .* (1 - pNR) ./ NnonoptoblocksR);
errorsO = sqrt(pO .* (1 - pO) ./ Noptoblocks);
errorsN = sqrt(pN .* (1 - pN) ./ Nnonoptoblocks);


%% figure; 
fprintf('Num opto blocks L = %d, num non-opto blocks L = %d\n', NoptoblocksL,...
    NnonoptoblocksL);
fprintf('Num opto blocks R = %d, num non-opto blocks R = %d\n', NoptoblocksR,...
    NnonoptoblocksR);


%%
colOpto = [69,117,180]/255;
colNOpto = [215,48,39]/255;
figure;
subplot(121)
l1 = errorbar(errorlocs, pOL * 100, ...
    errorsOL * 100, 'o', 'MarkerFaceColor', colOpto, 'MarkerEdgeColor', colOpto,...
    'LineWidth', 1, 'Color', colOpto);
hold on
plot(errorlocs, pOL * 100, 'Color', colOpto, 'LineWidth', 2)
l2 = errorbar(errorlocs, pNL * 100, ...
    errorsNL * 100, 'o', 'MarkerFaceColor', colNOpto, 'MarkerEdgeColor', colNOpto,...
    'LineWidth', 1, 'Color', colNOpto);
plot(errorlocs, pNL * 100, 'Color', colNOpto, 'LineWidth', 2)


xlim([0, 25])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10], ...
    'xytitle', 'Left blocks')


subplot(122)
l3 = errorbar(errorlocs, pOR * 100, ...
    errorsOR * 100, 'o', 'MarkerFaceColor', colOpto, 'MarkerEdgeColor', colOpto,...
    'LineWidth', 1, 'Color', colOpto);
hold on
plot(errorlocs, pOR * 100, 'Color', colOpto, 'LineWidth', 2)

l4 = errorbar(errorlocs, pNR * 100, ...
    errorsNR * 100, 'o', 'MarkerFaceColor', colNOpto, 'MarkerEdgeColor', colNOpto,...
    'LineWidth', 1, 'Color', colNOpto);
plot(errorlocs, pNR * 100, 'Color', colNOpto, 'LineWidth', 2)


legend([l3, l4], {'Opto', 'No-opto'});
xlim([0, 25])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10],...
    'xytitle', 'Right blocks')
legend([l3, l4], {'Opto', 'No-opto'});

%%
colOpto = [69,117,180]/255;
colNOpto = [215,48,39]/255;

figure;
l1 = errorbar(errorlocs, pO * 100, ...
    errorsO * 100, 'o', 'MarkerFaceColor', colOpto, 'MarkerEdgeColor', colOpto,...
    'LineWidth', 1, 'Color', colOpto);
hold on
plot(errorlocs, pO * 100, 'Color', colOpto, 'LineWidth', 2)
l2 = errorbar(errorlocs, pN * 100, ...
    errorsN * 100, 'o', 'MarkerFaceColor', colNOpto, 'MarkerEdgeColor', colNOpto,...
    'LineWidth', 1, 'Color', colNOpto);
plot(errorlocs, pN * 100, 'Color', colNOpto, 'LineWidth', 2)


xlim([0, 25])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10],...
    'xytitle', 'Combined')
legend([l1, l2], {'Opto', 'No-opto'});

set(gca, 'FontSize', 16);



function [locs, counts] = count_agg(arr)
errorsort = sort(arr);
[locs, ia,~] = unique(errorsort);
ia(end + 1) = numel(errorsort) + 1;
counts = diff(ia);

% fill with zeros
maxrange = min(locs) : max(locs);
remaining = setdiff(maxrange, locs);
locs = [locs remaining];
counts = [counts; zeros(numel(remaining), 1)];

[locs, ids] = sort(locs);
counts = counts(ids);


end



    






