function [allchoices, alltargets, skipping, probflag, allfeedbacks, allopto, allsesscounts] = get_choice_sequence_opto(id, root, folders)
% Parse the sequence of choices and targets in all sessions from the same
% day.
% id: id of the session
% root: root folder for the animal
% fodlers: folders(id) is the folder which contains the date of interest
% probflag: flag indicating blockworldprob


disp([num2str(id) ': ' folders(id).name])
% For file concatenation
files = dir(fullfile(root, ...
    folders(id).name, '*/*Block.mat'));

allchoices = [];
alltargets = [];
allsesscounts = [];
allfeedbacks = [];
allopto = [];
skipping = 0;
probflag = 0;
for i = 1:numel(files)
    % Handle case of file corruption
    try
        load(fullfile(files(i).folder, files(i).name));
    
    catch ME
        if (strcmp(ME.identifier,'MATLAB:load:notBinaryFile')) || ...
                (strcmp(ME.identifier,'MATLAB:load:unableToReadMatFile'))
            fprintf('Error loading file %d of id %d: %s, skipping,...\n',...
                i, id, files(i).name);
        end     
        continue
    end
    
    if isfield(block, 'expDef')
        parts = strsplit(block.expDef, '\');
        filename = parts{end};

        disp(filename)
    else
        filename = 'invalid';
    end
    if ~startsWith(filename, 'blockWorld')
        skipping = 1;
        fprintf('Skipping id = %d: %s...\n', id, filename);
    else
        if strcmp(filename, 'blockWorldProb.m')
            probflag = block.paramsValues(1).sideProb;
        end
%         if ~isfield(block.paramsValues, 'rewardDelay')
%             skipping = 1;
%             break;
%         end

        choices = block.events.responseValues;
        targets = block.events.contrastLeftValues;
        feedback = block.events.feedbackValues;
        
        if isfield(block.events, 'optoblockValues')
            opto = block.events.optoblockValues;
        else
            opto = choices * 0;
        end
        
        if isempty(opto)
            disp('here')
        end
        
        N = min([numel(choices) numel(targets) numel(feedback) numel(opto)]);
        
        if N == 0
            skipping = 1;
            fprintf('Skipping id = %d: %s...\n', id, filename);
        end
        
        allchoices = [allchoices choices(1:N)];
        alltargets = [alltargets targets(1:N)];
        allsesscounts = [allsesscounts ones(1,N) * i];
        allfeedbacks = [allfeedbacks feedback(1:N)];
        allopto = [allopto opto(1:N)];
    end
end
    
   
end
