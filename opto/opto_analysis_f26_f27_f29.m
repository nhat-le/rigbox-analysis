f26_sessions = {'2021-10-26', '2021-10-27'};
f26_flag = [0 0];


filtered_sessions = f26_sessions;
no_opto_flag = f26_flag;
titlestr = 'f26 ACC opto';
animal = 'f26';


% start_id = 30;
%%
[~,computername] = system('hostname');

switch computername(1:end-1)
    case {'dhcp-10-29-99-156.dyn.MIT.EDU', 'LMNMacbook.local'}
%         for f11/f12 analysis
%         rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
%         savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';

          % for f26,f27,f29 analysis
          rigbox = '/Volumes/GoogleDrive/Other computers/ImagingDESKTOP-AR620FK/LocalExpData';
          savefolder = '/Volumes/GoogleDrive/Other computers/ImagingDESKTOP-AR620FK/LocalExpData';
    case 'LAPTOP-HGDQ2Q94'
        rigbox = 'C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Rigbox';
        savefolder = 'C:\Users\Cherry Wang\Desktop\UROP-Nhat\HMM';
    otherwise
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
end
% rigbox = 'C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Rigbox';
root = fullfile(rigbox, animal);
folders = dir(fullfile(root, '202*'));
allBlocks = struct;
allBlocks.events = struct;
allBlocks.events.trialSideValues = [];
allBlocks.events.optoblockValues = [];
allBlocks.events.feedbackValues = [];
allBlocks.events.blockInit = [];
% Going through each day of training for the animal specified





for id = 1:numel(folders)
    % Only process the sessions with the relevant brain area..
    if ~ismember(folders(id).name, filtered_sessions)
        continue
    end
    disp(folders(id).name);
    % Concatenate sessions from the same day into one session
    files = dir(fullfile(root, folders(id).name, '*/*Block.mat'));
    allchoices = [];
    alltargets = [];
    skipping = 0;
    for i = 1:numel(files)
        try
            load(fullfile(files(i).folder, files(i).name));
        catch
        end
        parts = strsplit(block.expDef, '\');
        filename = parts{end};

        if ~startsWith(filename, 'blockWorld')
            skipping = 1;
            fprintf('Skipping id = %d: %s...\n', id, filename);
        else
            last_direction = block.events.trialSideValues(end);
            trialSide = block.events.trialSideValues;
            N = numel(trialSide);
            while trialSide(N) == last_direction
                N = N-1;
                if N ==0
                    break
                end
            end
            
            feedback = block.events.feedbackValues(1:N);
            if N == 0
                blocks = [];
            else
                blocks = logical(diff(trialSide(1:N)) ~= 0);
                blocks = [1 blocks];
            end

            if no_opto_flag(strcmp(folders(id).name, filtered_sessions))
                opto = zeros(N);
            else
                opto = block.events.optoblockValues;
                opto = opto(2:end); %IMPT: opto is offset by 1
            end
%             try
%                 opto = block.events.optoblockValues;
%             catch
%                 opto = zeros(N);
%             end
%             fprintf('Process
            disp(N)
            disp(numel(blocks));
            allBlocks.events.trialSideValues = [allBlocks.events.trialSideValues trialSide(1:N)];
            allBlocks.events.optoblockValues = [allBlocks.events.optoblockValues opto(1:N)];
            allBlocks.events.feedbackValues = [allBlocks.events.feedbackValues feedback(1:N)];
            allBlocks.events.blockInit = [allBlocks.events.blockInit blocks];
        end
    end
end

%% visualizeOpto(allBlocks);

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
% ax1 = subplot(211);
% plot(optoLErrors(1,:), optoLErrors(2,:), 'ro', 'MarkerSize', 2);
% title('Opto')
% 
% NoptoblocksL = numel(unique(optoLErrors(2,:)));
% NnonoptoblocksL = numel(unique(nonOptoLErrors(2,:)));
% NoptoblocksR = numel(unique(optoRErrors(2,:)));
% NnonoptoblocksR = numel(unique(nonOptoRErrors(2,:)));
% 
fprintf('Num opto blocks L = %d, num non-opto blocks L = %d\n', NoptoblocksL,...
    NnonoptoblocksL);
fprintf('Num opto blocks R = %d, num non-opto blocks R = %d\n', NoptoblocksR,...
    NnonoptoblocksR);
% 
% ax2 = subplot(212);
% plot(nonOptoLErrors(1,:), nonOptoLErrors(2,:), 'ro', 'MarkerSize', 2);
% title('No opto')
% 
% linkaxes([ax1 ax2], 'xy');


%% Take the mean

% optoRErrors = optoRErrors(:, optoRErrors(2,:) <=20);
% figure;
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


% l1 = plot(errorlocsOL, countsOL / NoptoblocksL * 100, 'LineWidth', 2);
% hold on
% l2 = plot(errorlocsNL, countsNL/ NnonoptoblocksL * 100, 'LineWidth', 2);
xlim([0, 15])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10])


subplot(122)
% l3 = plot(errorlocsOR, countsOR / NoptoblocksR * 100, 'LineWidth', 2);
% hold on
% l4 = plot(errorlocsNR, countsNR/ NnonoptoblocksR * 100, 'LineWidth', 2);
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
xlim([0, 15])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10])
legend([l3, l4], {'Opto', 'No-opto'});



% xlabel('Trials from block start')
% ylabel('Error fraction')
% title(titlestr)25    11     5     7     3     4     1     3     2     1     2     5     5     3     1     1     2

%   Columns 18 through 26
% 
%      4     2     2     1     1     1     1     1     1

% set(gca, 'FontSize', 16)

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


xlim([0, 13])
mymakeaxis('x_label', 'Trials', 'y_label', '% errors', 'xticks', [0, 5, 10])
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



    