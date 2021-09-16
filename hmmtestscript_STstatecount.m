animals = {'f01'}; %, 'e54', 'e57', 'f01', 'f02', 'f03', 'f04'};
states = [2,3];
num_states = numel(states);

s = warning('error', 'stats:hmmtrain:NoConvergence');

[~,computername] = system('hostname');
switch computername(1:end-1)
    case 'dhcp-10-29-99-156.dyn.MIT.EDU'
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
    case 'LAPTOP-HGDQ2Q94'
        rigbox = 'C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Rigbox';
        savefolder = 'C:\Users\Cherry Wang\Desktop\UROP-Nhat\HMM';
    case 'LMNMacbook.local'
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
end

for a = animals
    animal = a{1};
    root = fullfile(rigbox, animal);
    folders = dir(fullfile(root, '202*'));
    states_lst = [];
    logllh_lst = [];
    aic_lst = [];
    bic_lst = [];
    
    normlogllh_lst = [];
    maxdelays = [];


    %% Going through each day of training for the animal specified
    for id = 1:numel(folders)
        disp(id)

        % Concatenate sessions from the same day into one session
        files = dir(fullfile(root, ...
            folders(id).name, '*/*Block.mat'));
        allchoices = [];
        alltargets = [];
        curr_aic = zeros(num_states, 1);
        curr_bic = zeros(num_states, 1);
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

    %         if ~isfield(block.paramsValues, 'rewardDelay')
    %             skipping = 1;
    %             break;
    %         end

                choices = block.events.responseValues;
                targets = block.events.contrastLeftValues;
                N = min([numel(choices) numel(targets)]);
                allchoices = [allchoices choices(1:N)];
                alltargets = [alltargets targets(1:N)];
            end
        end
        
        N = numel(allchoices);

        if skipping
            maxdelays(end+1) = nan;
        end
        allchoices(allchoices == 0) = randsample([-1, 1],1);
        allchoices = (allchoices + 1) / 2 + 1;
        switches = find(diff(alltargets) ~= 0);

        % Fit HMM
        axeslst = [];
        currstates = zeros(num_states, 1);
        currlogllh = zeros(num_states, 1);
        currnormlogllh = zeros(num_states, 1);
        for i = 1:num_states
            if states(i) == 2
                TRANS_GUESS = [0.95 0.05; 0.05 0.95];
                EMIS_GUESS = [0.9 0.1; 0.1 0.9];
                k = 4; %nunber of parameters
            elseif states(i) == 3
                TRANS_GUESS = [0.9 0.08 0.02; 0.05 0.9 0.05; 0.02 0.08 0.9];
                EMIS_GUESS = [0.9 0.1; 0.5, 0.5; 0.1 0.9];
                k = 9;
            end

            status = 1;
            maxiter = 100;
            while (status && (maxiter < 40000))
                [TRANS_EST2, EMIS_EST2, status] = hmmtrainRobust(allchoices, TRANS_GUESS, EMIS_GUESS, maxiter);
                if status
                    maxiter = maxiter * 2;
                    fprintf('Not converged, increasing maxiter = %d..\n', maxiter); 
                end

            end

            %[TRANS_EST2, EMIS_EST2] = hmmtrain(allchoices, TRANS_GUESS, EMIS_GUESS, 'Maxiterations', 8000);
            [PSTATES, logllh] = hmmdecode(allchoices,TRANS_EST2,EMIS_EST2);
            currlogllh(i) = logllh;
            currnormlogllh(i) = logllh/numel(allchoices);
            
            % AIC/BIC measures
            curr_aic(i) = 2 * k - 2 * logllh;
            curr_bic(i) = k * log(N) - 2* logllh; 

            % Get all the single-trial states
            [M, I] = max(PSTATES); % get all the states in the session
            state_changes = find (diff(I) ~=0); % indices of pre-state-change trials 
            single_states_id = state_changes(find(diff(state_changes) == 1)+1); % indices of single-trial states
            single_states = I(single_states_id); % single-trial states
            currstates(i) = numel(single_states);
        end
        
        states_lst = [states_lst currstates];
        logllh_lst = [logllh_lst currlogllh];
        normlogllh_lst = [normlogllh_lst currnormlogllh];
        
        
        
        aic_lst = [aic_lst curr_aic];
        bic_lst = [bic_lst curr_bic];

        if skipping
            continue
        end

        if isfield(block.paramsValues, 'rewardDelay')
            maxdelays(end+1) = max([block.paramsValues.rewardDelay]);
        else
            maxdelays(end+1) = 0;
        end
    end
    

    %% Visualize with linked axes

    figure;
    sessions_lst = 1:numel(folders);

    states_fig = subplot(311);
    % plot(sessions_lst,states_lst(1,:),'red','linewidth',2 )
    % hold on;
    % plot(sessions_lst,states_lst(2,:),'blue','linewidth',2 )
    diff_states = states_lst(2,:)-states_lst(1,:);
    plot(sessions_lst, diff_states, 'blue', 'linewidth', 2 )
    hold on
    plot(sessions_lst, maxdelays)
    ylabel('ST state count');

    logllh_fig = subplot(312);
    % plot(sessions_lst,logllh_lst(1,:),'red','linewidth',2 )
    % hold on;
    % plot(sessions_lst,logllh_lst(2,:),'blue','linewidth',2 )
    diff_logllh = logllh_lst(2,:)-logllh_lst(1,:);
    plot(sessions_lst, diff_logllh,'blue','linewidth',2 )
    ylabel('Log Likelihood');

    normlogllh_fig = subplot(313);
    % plot(sessions_lst,normlogllh_lst(1,:),'red','linewidth',2 )
    % hold on;
    % plot(sessions_lst,normlogllh_lst(2,:),'blue','linewidth',2 )
    diff_normlogllh = normlogllh_lst(2,:)-normlogllh_lst(1,:);
    plot(sessions_lst,diff_normlogllh,'blue','linewidth',2 )
    xlabel('Session #');
    ylabel('Log Likelihood/n');
    sgtitle(animal);
    linkaxes([states_fig logllh_fig normlogllh_fig], 'x');
    
    animalData = struct;
    animalData.name = animal;
    animalData.states = diff_states;
    animalData.logllh = diff_logllh;
    animalData.normlogllh = diff_normlogllh;
    
    fullsaveName = sprintf('animalData_%s_091321.mat', animal);
    save(fullfile(savefolder, fullsaveName), 'animalData')
    
end

%%
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

