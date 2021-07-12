
animal = 'e50';
id_lst = [14, 24, 55];
all_states = [2, 3];

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

root =fullfile(rigbox, animal);
folders = dir(fullfile(root, '202*'));


sessions_lst = 1:numel(folders);
loadpath = fullfile(savefolder, ['animalData_' animal '.mat']);
load(loadpath);
states_lst = animalData.states;
logllh_lst = animalData.logllh;
aic_lst = animalData.aic;
bic_lst = animalData.bic;
maxdelays = animalData.delays*10;
maxiter = animalData.maxiter;
PSTATES_lst = animalData.PSTATES;
sessionInfo_lst = animalData.sessionInfo;

figure;
plot_id = 1;
axeslst = [];
for i = 1:numel(id_lst)
    id = id_lst(i);
    disp(id)
    % Concatenate sessions from the same day into one session
    files = dir(fullfile(root, ...
        folders(id).name, '*/*Block.mat'));
    disp(folders(id).name);
    allchoices = [];
    alltargets = [];
    skipping = 0;
    for file = 1:numel(files)
        try
            load(fullfile(files(file).folder, files(file).name));
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

    
    for state_id = 1:length(all_states)
        curr_state = all_states(state_id);
        PSTATES = PSTATES_lst(id).(['states' num2str(curr_state)]);

        %% Visualize states of one session
        l = subplot(numel(id_lst),2,plot_id);
        axeslst = [axeslst l];
        
        EMIS_EST = sessionInfo_lst(id).(['EMIS_EST' num2str(curr_state)]);
        
        
        new_PSTATES = [EMIS_EST(:,1) PSTATES];
        order = sortrows(new_PSTATES, 1);
        new_PSTATES = order(:,2:end);
        [M, I] = max(new_PSTATES); % get all the states in the session
        new_I = [0 I 0];
        state_changes = find(diff(new_I)~=0);
        state_changes = [state_changes+1 state_changes];
        
        plot(allchoices, 'ko', 'MarkerSize', 4)
        hold on
        plot((new_PSTATES' + 1))
        hold on
        
        colors = {'blue', 'cyan', 'yellow'};
        
        for s=1:all_states(state_id)
            state_s = find(new_I==s);
            coords = state_changes(ismember(state_changes, state_s));
            coords = coords - 1;
            x = reshape(coords, fix(numel(coords)/2), 2);
            new_x = [x'; x'];
            x = [new_x(1:2,:); new_x(4,:); new_x(3,:)];
            y = zeros(size(x));
            y(1:2,:) = 1;
            y(3:4,:) = 2;
            fill(x,y,colors{s},'FaceAlpha',.5);
        end
        vline(switches, 'k--')
        %vline(subjSwitches, 'r--');
        ylim([-1 3])
        %title([animal '(' folders(id).name ') session #' num2str(id)]);
        date = strrep(folders(id).name, '-','');
        ylabel(['#' num2str(id) '(' date(3:end) ')'])

        plot_id = plot_id+1;
    end

    
end
linkaxes(axeslst,'xy')

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
