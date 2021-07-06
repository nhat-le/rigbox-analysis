animal = 'f01';
root = fullfile('/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox', animal);
folders = dir(fullfile(root, '202*'));
warning('on', 'verbose') 
s = warning('error', 'stats:hmmtrain:NoConvergence');
Tcollection = {};
Ecollection = {};
Pcollection = {};
maxdelays = [];
statuses = [];
foldernames = {};

%% Initial guesses for 2states and 3 states HMM
Tinit2 = [0.95 0.05; 0.05 0.95];
Einit2 = [0.9 0.1; 0.1 0.9];


Tinit3 = [0.9 0.05 0.05; 0.05 0.9 0.05; 0.05 0.05 0.9];
Einit3 = [0.9 0.1; 0.5 0.5; 0.1 0.9];

%% Fit 2-state HMM

logllh2states = [];
AIClst = [];
BIClst = [];
k = 4; % number of estimated parameters

for id = 1:numel(folders)
    [allchoices, alltargets, skipping] = get_choice_sequence(id, root, folders);
    
    if skipping
        Tcollection{end+1} = nan;
        Ecollection{end+1} = nan;
        maxdelays(end+1) = nan;
        Pcollection{end+1} = nan;
        statuses(end+1) = nan;
        foldernames{end+1} = folders(id).name;
        continue
    end

    data = (allchoices + 1) / 2 + 1;
    mask = data ~= 1 & data ~= 2;
    data(mask) = (rand(sum(mask), 1) > 0.5) + 1;
%     data(data ~= 1 & data ~= 2) = [];
    % Fit HMM


    status = 1;
    maxiter = 100;
    while (status && (maxiter < 20000))
        [Test, Eest, status] = hmmtrainRobust(data, Tinit2, Einit2, maxiter);
        if status
            maxiter = maxiter * 2;
            fprintf('Not converged, increasing maxiter = %d..\n', maxiter); 
        end
        
    end
    
    if status
        warning(s);
        [Test, Eest] = hmmtrain(data, Tinit2, Einit2, 'Maxiterations', maxiter);
        s = warning('error', 'stats:hmmtrain:NoConvergence');
    end
    
    [PSTATES, logllh] = hmmdecode(data,Test,Eest);

    logllh2states(end+1) = logllh;
    AIClst(end+1) = -2 * logllh + 2 * k;
    BIClst(end+1) = -2 * logllh + k * log(numel(PSTATES)); 
    Tcollection{end+1} = Test;
    Ecollection{end+1} = Eest;
    
    files = dir(fullfile(root, ...
        folders(id).name, '*/*Block.mat'));
    load(fullfile(files(1).folder, files(1).name));
    
    if isfield(block.paramsValues, 'rewardDelay')
        maxdelays(end+1) = max([block.paramsValues.rewardDelay]);
    else
        maxdelays(end+1) = 0;
    end
    
    foldernames{end+1} = folders(id).name;
    Pcollection{end+1} = PSTATES;
    statuses(end+1) = status;
end


%% Parse the T collection
T11 = cellfun(@(x) extractNoNan(x,1,1), Tcollection);
T22 = cellfun(@(x) extractNoNan(x,2,2), Tcollection);
E11 = cellfun(@(x) extractNoNan(x,1,1), Ecollection);
E22 = cellfun(@(x) extractNoNan(x,2,2), Ecollection);

range = 7:32;

if isnan(range)
    plotdelay = 1;
    range = 1:numel(T11);
else
    plotdelay = 0;
end

figure;
subplot(211)
l1 = plot(1./(1-T11(range)), 'b', 'LineWidth', 2);
hold on
l2 = plot(1./(1-T22(range)), 'cyan', 'LineWidth', 2);
xlabel('Session #')
ylabel('Switch period')
legend([l1, l2], {'P_{LR}', 'P_{RL}'});
set(gca, 'FontSize', 16);
title(animal)


subplot(212)
l3 = plot(E11(range), 'r', 'LineWidth', 2);
hold on
l4 = plot(E22(range), 'Color', [254,178,76]/255, 'LineWidth', 2);
if plotdelay
    plot(maxdelays)
end
xlabel('Session #')
ylabel('Action probability')
legend([l3, l4], {'P_{left}', 'P_{right}'});


% xticks(1:numel(E11))
% xticklabels(foldernames);
% xtickangle(90);

set(gca, 'FontSize', 16);

%%
% filename = sprintf('HMMfits/HMMfits_%s.mat', animal);
% save(filename, 'animal', 'Tcollection', 'Ecollection', 'maxdelays', ...
%     'Pcollection', 'statuses', 'foldernames');



function [Test, Eest, status] = hmmtrainRobust(data, Tinit, Einit, maxiter)
try
    [Test, Eest] = hmmtrain(data, Tinit, Einit, 'Maxiterations', maxiter);
    status = 0;
catch
    Test = nan;
    Eest = nan;
    status = 1;
end
end




function res = extractNoNan(arr, m,n)
    if isnan(arr)
        res = nan;
    else
        res = arr(m,n);
    end
end