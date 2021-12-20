
warning('on', 'verbose') 
s = warning('error', 'stats:hmmtrain:NoConvergence');

% animals = {'f01', 'f02', 'f03', 'f04', 'f11', 'f12', 'E35', 'E40',...
%     'fh01', 'fh02', 'f05', 'e53', 'fh03', 'f16', 'f17', 'f20', 'f21', 'f22', 'f23'};
animals = {'f16', 'f17', 'f20', 'f21', 'f11', 'f12'};
f = waitbar(0);
for i = 1:numel(animals)
    waitbar(i/numel(animals), f, sprintf('Processing animal %s', animals{i}));
    process_animal(animals{i});

end


function process_animal(animal)
fprintf('****** Processing animal %s...*******\n', animal);
root = fullfile('/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox', animal);
folders = dir(fullfile(root, '202*'));
choices_cell = {};
targets_cell = {};
feedbacks_cell = {};
maxdelays = [];
probflags = [];

%TODO: add file names to know experiment type
for id = 1:numel(folders)
%     disp(id)
    [allchoices, alltargets, ~, probflag, allfeedbacks] = get_choice_sequence(id, root, folders);
    probflags(id) = probflag;
    choices_cell{end+1} = allchoices;
    targets_cell{end+1} = alltargets;
    feedbacks_cell{end+1} = allfeedbacks;
    
    
    files = dir(fullfile(root, ...
        folders(id).name, '*/*Block.mat'));
    
    try
        load(fullfile(files(1).folder, files(1).name));
    
        if isfield(block.paramsValues, 'rewardDelay')
            maxdelays(end+1) = max([block.paramsValues.rewardDelay]);
        else
            maxdelays(end+1) = 0;
        end
    catch ME
        if (strcmp(ME.identifier,'MATLAB:load:notBinaryFile')) || ...
                (strcmp(ME.identifier,'MATLAB:load:unableToReadMatFile'))
            fprintf('Error loading file, skipping,...\n');
        end     
        maxdelays(end+1) = nan;
    continue
    end
    
       
end

%%
filename = sprintf('/Users/minhnhatle/Dropbox (MIT)/Sur/MatchingSimulations/expdata/%s_all_sessions_093021.mat', animal);
save(filename, 'choices_cell', 'targets_cell', 'maxdelays', 'probflags', 'feedbacks_cell');

end