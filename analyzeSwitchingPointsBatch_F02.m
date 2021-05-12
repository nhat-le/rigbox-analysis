%% Gather the relevant files
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f02';
files = dir(fullfile(directory, '*/*/*Block.mat'));

% Eliminate bad files
record.name = 'F02';
record.badfiles = {'2021-01-23_1_F02_Block.mat',...
    '2021-01-25_1_F02_Block.mat',...
    '2021-01-26_1_F02_Block.mat',...
    '2021-01-27_1_F02_Block.mat',...
    '2021-01-28_1_F02_Block.mat',...
    '2021-01-29_1_F02_Block.mat',...
    '2021-02-01_1_F02_Block.mat',...
    '2021-02-03_1_F02_Block.mat',...
    '2021-02-04_1_F02_Block.mat',...
    '2021-02-10_1_F02_Block.mat',...
    '2021-02-10_2_F02_Block.mat',...
    '2021-02-10_3_F02_Block.mat'
};
record.directory = directory;
% save('E50rigboxRecord.mat', 'record');


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

for i = 1:numel(files)
    fprintf('Processing file %d of %d\n', i, numel(files));
    load(fullfile(files(i).folder, files(i).name), 'block');

    contrastLeft = block.events.contrastLeftValues;
    contrastRight = block.events.contrastRightValues;
    response = block.events.responseValues;

    % Get the idx of the block transitions
    blockStarts = 1 + find(diff(contrastLeft));
    blockStarts = [1 blockStarts];
    targets = contrastRight(blockStarts) * 2 - 1;


    [muopts, sigmaopts, invalids, deltas] = fitSigmoid(response, blockStarts,...
        targets, options);
    
    allsigmas{i} = sigmaopts(sigmaopts < 100);
    alldeltas{i} = deltas(abs(deltas) < 100);
end


%% Save the results
save('F02rigboxSwitchingFits.mat', 'allsigmas', 'alldeltas', 'files', 'options');




function L = findLLH(params, y)
    mu = params(1); % Center of transition
    sigma = params(2); % slope of transition
    xvals = 1:numel(y);
    p = 1 ./ (1 + exp(-((xvals - mu) / sigma)));
    p = min(p, 0.9999);
    p = max(p, 0.0001);
    
    % Discard locations where y==0.5 (miss)
    p = p(y ~= 0.5);
    y = y(y ~= 0.5);

    L = - sum((1-y) .* log(1-p) + y .* log(p));

end

function [muopts, sigmaopts, invalids, deltas] = fitSigmoid(response, blockStarts,...
    targets, options)
blockmids = floor((blockStarts(1:end-1) + blockStarts(2:end)) / 2);
midpts = blockmids(1:end-1);
nextStarts = blockStarts(2:end-1);
nextEnds = blockStarts(3:end) - 1;

muopts = [];
sigmaopts = [];
invalids = []; %idx of invalid blocks where optimization does not converge

if options.plotting
    figure;
end

for nblock = 1:numel(midpts)
    choices = response(midpts(nblock):nextEnds(nblock));
    
    if targets(nblock) == 1
        y = 1- (choices + 1)/ 2;
    else
        y = (choices + 1)/ 2;
    end

    mu = options.mu; % Center of transition
    sigma = options.sigma; % slope of transition
    xvals = 1:numel(y);
    params = [mu, sigma];
    
    fminsearchOptions = optimset('Display', 'off');
    [params_opt,~,flag] = fminsearch(@(p) findLLH(p, y), params, fminsearchOptions);

    if flag ~= 1
        fprintf('Warning: block %d: optimization has not converged\n', nblock);
        invalids = [invalids nblock];
    end
    muopt = params_opt(1);
    sigmaopt = params_opt(2);
    popt = 1 ./ (1 + exp(-((xvals - muopt) / sigmaopt)));

    muopts = [muopts muopt];
    sigmaopts = [sigmaopts sigmaopt];
    
    if options.plotting
        subplot(5,6,nblock)
        plot(popt)
        hold on
        plot(y, 'o')

        % Vertical line at the block transition
        transition = nextStarts(nblock) - midpts(nblock);
        plot([transition transition], [0 1], 'k--');
    end
end

% Find deltas
muopts(invalids) = nan;
deltas  = muopts + midpts - nextStarts;


end

