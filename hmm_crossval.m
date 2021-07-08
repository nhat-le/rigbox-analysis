animals = {'e50', 'e54', 'e57', 'f01', 'f02', 'f03', 'f04'};
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
    otherwise
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
end

for a = animals(2:end)
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
        
        [allchoices, alltargets, skipping] = get_choice_sequence(id, root, folders);
        load(fullfile(files(1).folder, files(1).name));
       
        
        N = numel(allchoices);

        if skipping
            maxdelays(end+1) = nan;
        end
        allchoices(allchoices == 0) = randsample([-1, 1],1);
        allchoices = (allchoices + 1) / 2 + 1;
        switches = find(diff(alltargets) ~= 0);
        
        
        % Split into train and test sets
        if rand > 0.5
            idx = 1;
        else
            idx = 2;
        end
        
        trainset = allchoices(idx:2:end);
        testset = allchoices(3-idx:2:end);
        
        
        
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
                [TRANS_EST2, EMIS_EST2, status] = hmmtrainRobust(trainset, TRANS_GUESS, EMIS_GUESS, maxiter);
                if status
                    maxiter = maxiter * 2;
                    fprintf('Not converged, increasing maxiter = %d..\n', maxiter); 
                end

            end
            
            if status
                fprintf('Not converged, trying with maximum value\n');
                s = warning('warning', 'stats:hmmtrain:NoConvergence');
                
                [TRANS_EST2, EMIS_EST2] = hmmtrain(trainset, TRANS_GUESS, EMIS_GUESS, 'Maxiterations', maxiter);
                s = warning('error', 'stats:hmmtrain:NoConvergence');
            end



            %[TRANS_EST2, EMIS_EST2] = hmmtrain(allchoices, TRANS_GUESS, EMIS_GUESS, 'Maxiterations', 8000);
            [PSTATES, logllh] = hmmdecode(testset,TRANS_EST2,EMIS_EST2);
            currlogllh(i) = logllh;
            currnormlogllh(i) = logllh/numel(allchoices);
            

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
    animalData.maxdelays = maxdelays;
    
    fullsaveName = sprintf('animalData_%s_crossval.mat', animal);
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

