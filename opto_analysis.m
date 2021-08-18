f11_acc_sessions = {'2021-07-02', '2021-07-06', '2021-07-07', '2021-07-08',...
    '2021-07-09', '2021-07-14', '2020-07-20'};
no_opto_flag_f11_acc = [1, 0, 0, 0, 1, 0, 1]; %these sessions are no-opto sessions

f11_acc2_sessions = {'2021-08-03', '2021-08-04'};
no_opto_flag_f11_acc2 = [0 0];

f12_acc2_sessions = {'2021-08-03', '2021-08-04'};
no_opto_flag_f12_acc2 = [0 0];


% 7.27 did incorrect opto protocol in first file
f11_accrew_sessions = {'2021-07-26', '2021-07-27', '2021-07-28', '2021-07-29',...
    '2021-07-30'};
no_opto_flag_f11_accrew = [0, 0, 0, 0, 1];

f12_acc_sessions = {'2021-07-06', '2021-07-08', '2021-07-09',...
    '2021-07-14', '2020-07-20'};
no_opto_flag_f12_acc = [1, 0, 0, 0, 1, 0, 1];

f12_accrew_sessions = {'2021-07-26', '2021-07-27', '2021-07-28', '2021-07-29',...
    '2021-07-30'};
no_opto_flag_f12_accrew = [0, 0, 0, 0, 1];

f11_rsc_sessions = {'2021-07-12', '2021-07-13', '2021-07-15', '2021-07-16',...
    '2021-07-19', '2021-07-21', '2021-07-20', '2021-07-09'};
no_opto_flag_f11_rsc = [0 0 0 0 0 0 1 1];


f12_rsc_sessions = {'2021-07-12', '2021-07-13', '2021-07-15', '2021-07-16',...
    '2021-07-19', '2021-07-21', '2021-07-20', '2021-07-09', '2021-07-02'};
no_opto_flag_f12_rsc = [0 0 0 0 0 0 1 1 1];


filtered_sessions = f12_acc_sessions;
no_opto_flag = no_opto_flag_f12_acc;
titlestr = 'f11 ACC opto';
animal = 'f12';


% start_id = 30;
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
title('Opto')

Noptoblocks = numel(unique(optoErrors(2,:)));
Nnonoptoblocks = numel(unique(nonOptoErrors(2,:)));

fprintf('Num opto blocks = %d, num non-opto blocks = %d\n', Noptoblocks,...
    Nnonoptoblocks);

ax2 = subplot(212);
plot(nonOptoErrors(1,:), nonOptoErrors(2,:), 'ro', 'MarkerSize', 2);
title('No opto')

linkaxes([ax1 ax2], 'xy');


%% Take the mean
figure;
[errorlocs1, counts1] = count_agg(optoErrors(1,:));
[errorlocs2, counts2] = count_agg(nonOptoErrors(1,:));

l1 = plot(errorlocs1, counts1 / Noptoblocks, 'LineWidth', 2);
hold on
l2 = plot(errorlocs2, counts2/ Nnonoptoblocks, 'LineWidth', 2);
legend([l1, l2], {'Opto', 'No-opto'});
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



    