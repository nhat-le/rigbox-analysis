function [allchoices, alltargets, skipping] = get_choice_sequence(id, root, folders)
% Parse the sequence of choices and targets in all sessions from the same
% day.
% id: id of the session
% root: root folder for the animal
% fodlers: folders(id) is the folder which contains the date of interest


disp([num2str(id) ': ' folders(id).name])
% For file concatenation
files = dir(fullfile(root, ...
    folders(id).name, '*/*Block.mat'));

allchoices = [];
alltargets = [];
skipping = 0;
for i = 1:numel(files)
    % Handle case of file corruption
    try
        load(fullfile(files(i).folder, files(i).name));
    
    catch ME
        if (strcmp(ME.identifier,'MATLAB:load:notBinaryFile'))
            fprintf('Error loading file %d of id %d: %s, skipping,...\n',...
                i, id, files(i).name);
        end     
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
    
   
end
