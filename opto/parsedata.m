function allBlocks = parsedata(Tfilt, rigbox, varargin)
%varargin could be used for no-opto flag

allBlocks = struct;
allBlocks.events = struct;
allBlocks.events.trialSideValues = [];
allBlocks.events.optoblockValues = [];
allBlocks.events.feedbackValues = [];
allBlocks.events.blockInit = [];

% Going through each day of training for the animal specified
for id = 1:size(Tfilt, 1)
    animal = Tfilt.Animal{id};
    sessdate = Tfilt.Date(id);
    sessdate = datestr(sessdate, 'yyyy-mm-dd');
    
    
    root = fullfile(rigbox, animal);
    folders = dir(fullfile(root, '202*'));
    
    imatch = strcmp(sessdate, {folders.name});
        
    
    % Concatenate sessions from the same day into one session
    files = dir(fullfile(root, folders(imatch).name, '*/*Block.mat'));
    allchoices = [];
    alltargets = [];
    skipping = 0;
    for i = 1:numel(files)
        fprintf('Processing session %s\n', files(i).name);
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

            if 0 %no_opto_flag(strcmp(folders(id).name, filtered_sessions))
                opto = zeros(N);
            else
                opto = block.events.optoblockValues;
                opto = opto(2:end); %IMPT: opto is offset by 1
            end

%             disp(N)
%             disp(numel(blocks));
            allBlocks.events.trialSideValues = [allBlocks.events.trialSideValues trialSide(1:N)];
            allBlocks.events.optoblockValues = [allBlocks.events.optoblockValues opto(1:N)];
            allBlocks.events.feedbackValues = [allBlocks.events.feedbackValues feedback(1:N)];
            allBlocks.events.blockInit = [allBlocks.events.blockInit blocks];
        end
    end
end