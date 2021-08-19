f17_sessions = {'2021-08-10', '2021-08-11', '2021-08-13', ...
    '2021-08-15', '2021-08-16', '2021-08-17', '2021-08-18'};
no_cno_flag_f17 = [1 1 0 0 1 0 1];

f16_sessions = {'2021-08-10', '2021-08-11', '2021-08-12', '2021-08-13', ...
    '2021-08-15', '2021-08-16', '2021-08-17', '2021-08-18'};
no_cno_flag_f16 = [1 1 0 0 0 1 0 1];

f21_sessions = {'2021-08-12', '2021-08-13', '2021-08-16', '2021-08-17', '2021-08-18'};
no_muscimol_flag_f21 = [1, 0, 1, 0, 0];

% f20_sessions = {'2021-08-12', '2021-08-13', '2021-08-16', '2021-08-17', '2021-08-18'};
% no_muscimol_flag_f20 = [1, 0, 1, 0, 0];

filtered_sessions = f21_sessions;
no_inact_flag = no_muscimol_flag_f21;
titlestr = 'f21 Muscimol';
animal = 'f21';

%%
[~,computername] = system('hostname');

switch computername(1:end-1)
    case 'dhcp-10-29-99-156.dyn.MIT.EDU'
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
    case 'LAPTOP-HGDQ2Q94'
        rigbox = 'C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Rigbox';
        savefolder = 'C:\Users\Cherry Wang\Desktop\UROP-Nhat\Rigbox';
    otherwise
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
end

%%
% rigbox = 'C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Rigbox';
root = fullfile(rigbox, animal);
folders = dir(fullfile(root, '202*'));
allBlocks = struct;
allBlocks.events = struct;
allBlocks.events.trialSideValues = [];
allBlocks.events.inactblockValues = [];
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

            if no_inact_flag(strcmp(folders(id).name, filtered_sessions))
                inact = zeros(N);
            else
                inact = ones(N);
            end
            disp(N)
            disp(numel(blocks));
            allBlocks.events.trialSideValues = [allBlocks.events.trialSideValues trialSide(1:N)];
            allBlocks.events.inactblockValues = [allBlocks.events.inactblockValues inact(1:N)];
            allBlocks.events.feedbackValues = [allBlocks.events.feedbackValues feedback(1:N)];
            allBlocks.events.blockInit = [allBlocks.events.blockInit blocks];
        end
    end
end

%% visualizeOpto(allBlocks);

num_trials = numel(allBlocks.events.trialSideValues);
nonInactErrors = [];
InactErrors = [];
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
        if allBlocks.events.inactblockValues(trial)
            InactErrors = [InactErrors [trial_count; block_count]];
        else
            nonInactErrors = [nonInactErrors [trial_count; block_count]];
        end
    end

end

figure;
ax1 = subplot(211);
plot(InactErrors(1,:), InactErrors(2,:), 'ro', 'MarkerSize', 2);
title('Inactivation')

NInactblocks = numel(unique(InactErrors(2,:)));
NnonInactblocks = numel(unique(nonInactErrors(2,:)));

fprintf('Num inactivation blocks = %d, num non-inactivation blocks = %d\n', NInactblocks,...
    NnonInactblocks);

ax2 = subplot(212);
plot(nonInactErrors(1,:), nonInactErrors(2,:), 'ro', 'MarkerSize', 2);
title('No Inactivation')

linkaxes([ax1 ax2], 'xy');


%% Take the mean
figure;
[errorlocs1, counts1] = count_agg(InactErrors(1,:));
[errorlocs2, counts2] = count_agg(nonInactErrors(1,:));

l1 = plot(errorlocs1, counts1 / NInactblocks, 'LineWidth', 2);
hold on
l2 = plot(errorlocs2, counts2/ NnonInactblocks, 'LineWidth', 2);
legend([l1, l2], {'Inactivation', 'No-inactivation'});
xlim([0, 30])

xlabel('Trials from block start')
ylabel('Error fraction')
title(titlestr)
set(gca, 'FontSize', 16)





function [locs, counts] = count_agg(arr)
errorsort = sort(arr);
[locs, ia,~] = unique(errorsort);
ia(end + 1) = numel(errorsort) + 1;
counts = diff(ia);

end



    