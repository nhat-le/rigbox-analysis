animal = 'f12';
start_id = 30;
%%
[~,computername] = system('hostname');

switch computername(1:end-1)
    case 'dhcp-10-29-99-156.dyn.MIT.EDU'
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
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

f12_acc_sessions = {'2021-07-02', '2021-07-06', '2021-07-07', '2021-07-08',...
    '2021-07-14'};


for id = 1:numel(folders)
    % Only process the sessions with the relevant brain area..
    if ~ismember(folders(id).name, f12_acc_sessions)
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
            blocks = logical(diff(trialSide) ~= 0);
            blocks = [1 blocks];

            try
                opto = block.events.optoblockValues;
            catch
                opto = zeros(N);
            end
            allBlocks.events.trialSideValues = [allBlocks.events.trialSideValues trialSide(1:N)];
            allBlocks.events.optoblockValues = [allBlocks.events.optoblockValues opto(1:N)];
            allBlocks.events.feedbackValues = [allBlocks.events.feedbackValues feedback(1:N)];
            allBlocks.events.blockInit = [allBlocks.events.blockInit blocks];
        end
    end
end

%% visualizeOpto(allBlocks);

num_trials = numel(allBlocks.events.trialSideValues);
nonOptoErrors = [];
optoErrors = [];
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
        if allBlocks.events.optoblockValues(trial)
            optoErrors = [optoErrors [trial_count; block_count]];
        else
            nonOptoErrors = [nonOptoErrors [trial_count; block_count]];
        end
    end

end

figure;
ax1 = subplot(211);
plot(optoErrors(1,:), optoErrors(2,:), 'ro', 'MarkerSize', 2);

ax2 = subplot(212);
plot(nonOptoErrors(1,:), nonOptoErrors(2,:), 'ro', 'MarkerSize', 2);

linkaxes([ax1 ax2], 'xy');





    