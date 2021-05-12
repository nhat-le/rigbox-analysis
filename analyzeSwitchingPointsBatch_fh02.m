%% Gather the relevant files
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/fh02';
files = dir(fullfile(directory, '*/*/*Block.mat'));

% Eliminate bad files
record.name = 'fh02';
record.badfiles = {'2021-03-30_1_fh02_Block.mat',...
            '2021-03-31_1_fh02_Block.mat',...
            '2021-03-31_2_fh02_Block.mat',...
            '2021-04-05_4_fh02_Block.mat',...
            '2021-04-08_1_fh02_Block.mat'
};
record.directory = directory;
save('fh02rigboxRecord.mat', 'record');


names = {files.name};
badidx = ismember(names, record.badfiles);
assert(sum(badidx) == numel(record.badfiles));
files = files(~badidx);
 

%% Read the data
options.mu = 10;
options.sigma = 0.5;
options.plotting = 1;
allsigmas = {};
alldeltas = {};

%% Group files taken on the same date
currname = files(1).name;
parts = strsplit(currname, '_');
currdate = parts{1};
fileids = [1];
filegroups = {};

for i = 2:numel(files)
    currname = files(i).name;
    parts = strsplit(currname, '_');
    filedate = parts{1};
    if strcmp(filedate, currdate)
        fileids = [fileids i];
    else
        filegroups{end+1} = fileids;
        currdate = filedate;
        fileids = [i];
    end     
end

filegroups{end+1} = fileids;

%%

allBlockStarts = {};
for i = 1:numel(filegroups)
    % Process all files in the group
    contrastLeftAll = [];
    contrastRightAll = [];
    responseAll = [];
    for j = 1:numel(filegroups{i})
        fprintf('Processing group %d of %d, file %d of %d\n', i, numel(filegroups), j, numel(files));
        load(fullfile(files(filegroups{i}(j)).folder, files(filegroups{i}(j)).name), 'block');
        
        contrastLeft = block.events.contrastLeftValues;
        contrastRight = block.events.contrastRightValues;
        response = block.events.responseValues;
        
        newlen = min([numel(contrastLeft) numel(contrastRight) numel(response)]);
        contrastLeft = contrastLeft(1:newlen);
        contrastRight = contrastRight(1:newlen);
        response = response(1:newlen);
        
%         assert(numel(contrastLeft) == numel(contrastRight))
%         assert(numel(contrastLeft) == numel(response))
        
        
        contrastLeftAll = [contrastLeftAll contrastLeft];
        contrastRightAll = [contrastRightAll contrastRight];
        responseAll = [responseAll response];
        
    end

    % Get the idx of the block transitions
    blockStarts = 1 + find(diff(contrastLeftAll));
    blockStarts = [1 blockStarts];
    
    
    % Flag blocks that are too short
    idxShortBlocks = find(diff(blockStarts) < 10);
    if numel(idxShortBlocks) >= 1
        warning('Short block exists!')
    end
    targets = contrastRightAll(blockStarts) * 2 - 1;


    [muopts, sigmaopts, invalids, deltas] = fitSigmoid(responseAll, blockStarts,...
        targets, options);
    
    targets = contrastRightAll * 2 - 1;

    filestem = files(filegroups{i}(1)).name(1:end-4);
    save([filestem 'data.mat'], 'responseAll', 'targets');
    
    allsigmas{i} = sigmaopts;% (sigmaopts < 100);
    alldeltas{i} = deltas; %(abs(deltas) < 100);
    allBlockStarts{i} = blockStarts;
    
end


%% Save the results
save('fh02rigboxSwitchingFitsC.mat', 'allsigmas', 'alldeltas', 'files', ...
    'options', 'allBlockStarts');






