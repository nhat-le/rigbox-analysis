animal = 'e57';
id_lst = {29};
all_states = [2, 3];

[~,computername] = system('hostname');
switch computername(1:end-1)
    case 'dhcp-10-29-99-156.dyn.MIT.EDU'
        rigbox = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
        savefolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM';
    case 'LAPTOP-HGDQ2Q94'
        rigbox = 'C:\Users\Cherry Wang\Dropbox (MIT)\Nhat\Rigbox';
        savefolder = 'C:\Users\Cherry Wang\Desktop\UROP-Nhat\HMM';
end

root =fullfile(rigbox, animal);
folders = dir(fullfile(root, '202*'));

for i = id_lst
    id = i{1};
    figure;
    disp(id)

    % Concatenate sessions from the same day into one session
    files = dir(fullfile(root, ...
        folders(id).name, '*/*Block.mat'));
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

    axeslst = [];

    for i = 1:length(all_states)
        if all_states(i) == 2
            TRANS_GUESS = [0.95 0.05; 0.05 0.95];
            EMIS_GUESS = [0.9 0.1; 0.1 0.9];
        elseif all_states(i) == 3
            TRANS_GUESS = [0.9 0.08 0.02; 0.05 0.9 0.05; 0.02 0.08 0.9];
            EMIS_GUESS = [0.9 0.1; 0.5, 0.5; 0.1 0.9];
        end
        
        status = 1;
        maxiter = 100;
        while (status) % && (maxiter < 40000))
            [TRANS_EST2, EMIS_EST2, status] = hmmtrainRobust(allchoices, TRANS_GUESS, EMIS_GUESS, maxiter);
            if status
                maxiter = maxiter * 2;
                fprintf('Not converged, increasing maxiter = %d..\n', maxiter); 
            end

        end

        [PSTATES, logllh] = hmmdecode(allchoices,TRANS_EST2,EMIS_EST2);

        % Determine the subjective switch points
        stateSegments = PSTATES(2,:) > 0.5;
        subjSwitches = find(diff(stateSegments) ~= 0);

        % For each block, find the first subjective switch
        blockSwitches = [];


        %% Visualize states of one session
        l = subplot(2,1,i);
        axeslst = [axeslst l];
        plot(allchoices, 'o')
        hold on
        plot((PSTATES' + 1))
        hold
        vline(switches, 'k--')
        % vline(subjSwitches, 'r--');
        ylim([-1 3])
        title([animal '(' folders(id).name ') session #' num2str(id)])
        ylabel([num2str(all_states(i)) ' states, iter = ' num2str(maxiter)])


    end

    linkaxes(axeslst,'xy')
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
