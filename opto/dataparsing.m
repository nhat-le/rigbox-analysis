T = readtable('sessionlog.xlsx');

% define inclusion criteria
animals = {'F27', 'F26', 'F29'};
areas = {'rsc'};
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
          
allBlocks = parsedata(Tfilt, rigbox);

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
arr = pad_to_same_length(feedbackcell);
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

%%

num_trials = numel(allBlocks.events.trialSideValues);
nonOptoLErrors = [];
optoLErrors = [];
nonOptoRErrors = [];
optoRErrors = [];

optoErrors = [];
nonOptoErrors = [];

currSideValue = 0;
block_count = 0;
for trial = 1:num_trials-1
    if allBlocks.events.blockInit(trial)
        trial_count = 0;
        block_count = block_count + 1;
        currSideValue = allBlocks.events.trialSideValues(trial);
    else
        trial_count = trial_count + 1;
    end
    if ~allBlocks.events.feedbackValues(trial)
        if allBlocks.events.optoblockValues(trial) &&  allBlocks.events.trialSideValues(trial) ==-1
            optoLErrors = [optoLErrors [trial_count; block_count]];
        elseif ~allBlocks.events.optoblockValues(trial) &&  allBlocks.events.trialSideValues(trial) ==-1
            nonOptoLErrors = [nonOptoLErrors [trial_count; block_count]];
        elseif allBlocks.events.optoblockValues(trial) &&  allBlocks.events.trialSideValues(trial) ==1
            optoRErrors = [optoRErrors [trial_count; block_count]];
        elseif ~allBlocks.events.optoblockValues(trial) &&  allBlocks.events.trialSideValues(trial) ==1
            nonOptoRErrors = [nonOptoRErrors [trial_count; block_count]];
        end
    end
    
    if ~allBlocks.events.feedbackValues(trial)
        if allBlocks.events.optoblockValues(trial)
            optoErrors = [optoErrors [trial_count; block_count]];
        else
            nonOptoErrors = [nonOptoErrors [trial_count; block_count]];
        end
    end
end

NoptoblocksL = numel(unique(optoLErrors(2,:)));
NnonoptoblocksL = numel(unique(nonOptoLErrors(2,:)));
NoptoblocksR = numel(unique(optoRErrors(2,:)));
NnonoptoblocksR = numel(unique(nonOptoRErrors(2,:)));
Noptoblocks = NoptoblocksL + NoptoblocksR;
Nnonoptoblocks = NnonoptoblocksL + NnonoptoblocksR;

%% figure; 
fprintf('Num opto blocks L = %d, num non-opto blocks L = %d\n', NoptoblocksL,...
    NnonoptoblocksL);
fprintf('Num opto blocks R = %d, num non-opto blocks R = %d\n', NoptoblocksR,...
    NnonoptoblocksR);

%% Take the mean
[errorlocsOL, countsOL] = count_agg(optoLErrors(1,:));
[errorlocsNL, countsNL] = count_agg(nonOptoLErrors(1,:));
[errorlocsOR, countsOR] = count_agg(optoRErrors(1,:));
[errorlocsNR, countsNR] = count_agg(nonOptoRErrors(1,:));
[errorlocsO, countsO] = count_agg(optoErrors(1,:));
[errorlocsN, countsN] = count_agg(nonOptoErrors(1,:));

pOL = countsOL / NoptoblocksL;
pNL = countsNL / NnonoptoblocksL;
pOR = countsOR / NoptoblocksR;
pNR = countsNR / NnonoptoblocksR;
pO = countsO / Noptoblocks;
pN = countsN / Nnonoptoblocks;


errorsOL = sqrt(pOL .* (1 - pOL) / NoptoblocksL);
errorsNL = sqrt(pNL .* (1 - pNL) / NnonoptoblocksL);
errorsOR = sqrt(pOR .* (1 - pOR) / NoptoblocksR);
errorsNR = sqrt(pNR .* (1 - pNR) / NnonoptoblocksR);
errorsO = sqrt(pO .* (1 - pO) / Noptoblocks);
errorsN = sqrt(pN .* (1 - pN) / Nnonoptoblocks);


%%
colOpto = [69,117,180]/255;
colNOpto = [215,48,39]/255;
figure;
subplot(121)
l1 = errorbar(errorlocsOL, countsOL / NoptoblocksL * 100, ...
    errorsOL * 100, 'o', 'MarkerFaceColor', colOpto, 'MarkerEdgeColor', colOpto,...
    'LineWidth', 1, 'Color', colOpto);
hold on
plot(errorlocsOL, countsOL / NoptoblocksL * 100, 'Color', colOpto, 'LineWidth', 2)
l2 = errorbar(errorlocsNL, countsNL / NnonoptoblocksL * 100, ...
    errorsNL * 100, 'o', 'MarkerFaceColor', colNOpto, 'MarkerEdgeColor', colNOpto,...
    'LineWidth', 1, 'Color', colNOpto);
plot(errorlocsNL, countsNL / NnonoptoblocksL * 100, 'Color', colNOpto, 'LineWidth', 2)


xlim([0, 25])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10], ...
    'xytitle', 'Left blocks')


subplot(122)
l3 = errorbar(errorlocsOR, countsOR / NoptoblocksR * 100, ...
    errorsOR * 100, 'o', 'MarkerFaceColor', colOpto, 'MarkerEdgeColor', colOpto,...
    'LineWidth', 1, 'Color', colOpto);
hold on
plot(errorlocsOR, countsOR / NoptoblocksR * 100, 'Color', colOpto, 'LineWidth', 2)

l4 = errorbar(errorlocsNR, countsNR / NnonoptoblocksR * 100, ...
    errorsNR * 100, 'o', 'MarkerFaceColor', colNOpto, 'MarkerEdgeColor', colNOpto,...
    'LineWidth', 1, 'Color', colNOpto);
plot(errorlocsNR, countsNR / NnonoptoblocksR * 100, 'Color', colNOpto, 'LineWidth', 2)


legend([l3, l4], {'Opto', 'No-opto'});
xlim([0, 25])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10],...
    'xytitle', 'Right blocks')
legend([l3, l4], {'Opto', 'No-opto'});

%%
colOpto = [69,117,180]/255;
colNOpto = [215,48,39]/255;

figure;
l1 = errorbar(errorlocsO, countsO / Noptoblocks * 100, ...
    errorsO * 100, 'o', 'MarkerFaceColor', colOpto, 'MarkerEdgeColor', colOpto,...
    'LineWidth', 1, 'Color', colOpto);
hold on
plot(errorlocsO, countsO / Noptoblocks * 100, 'Color', colOpto, 'LineWidth', 2)
l2 = errorbar(errorlocsN, countsN / Nnonoptoblocks * 100, ...
    errorsN * 100, 'o', 'MarkerFaceColor', colNOpto, 'MarkerEdgeColor', colNOpto,...
    'LineWidth', 1, 'Color', colNOpto);
plot(errorlocsN, countsN / Nnonoptoblocks * 100, 'Color', colNOpto, 'LineWidth', 2)


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



    






