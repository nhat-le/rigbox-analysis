%% Read the data
directory = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/E45/2020-12-07/1';
files = dir(fullfile(directory, '*.mat'));

load(fullfile(files(1).folder, files(1).name));

contrastLeft = block.events.contrastLeftValues;
contrastRight = block.events.contrastRightValues;

dcontrast = contrastLeft - contrastRight;
contrasts = unique(dcontrast);

response = block.events.responseValues;


% Get the idx of the block transitions
blockStarts = 1 + find(diff(contrastLeft));
blockStarts = [1 blockStarts];
targets = contrastRight(blockStarts) * 2 - 1;


% Split the blocks and the indices
blocks = {};
for i = 1:numel(blockStarts) - 1
    blocks{i} = response(blockStarts(i) : blockStarts(i+1) - 1); 
end


%% For each block, plot the cumulative performance
cumPerfs = {};
figure;
for i = 1:numel(blocks)
    subplot(5,6,i)
    cumPerfs{i} = get_cumulative_performance(blocks{i}, targets(i));
    if targets(i) == 1
        plot(cumPerfs{i}, 'r')
    else
        plot(cumPerfs{i}, 'b')
    end
    ylim([0,1])
    hold on
end

%%
figure;
ax = axes;
plot(block.events.responseValues, 'o')
hold on
plot(block.events.feedbackValues)

%% Manually demarcate middle time points
blockmids = floor((blockStarts(1:end-1) + blockStarts(2:end)) / 2);
endpts = blockmids(2:end);
midpts = blockmids(1:end-1);
nextStarts = blockStarts(2:end-1);

%%
% midpts = [19, 39, 51,73, 129, 174, 182, 205, 235, 251, 295, 310, 345, 357, 398];
startpts = blockStarts(2:end-1);
endpts = blockStarts(3:end) - 1;
endpts(14) = 384;
endpts(15) = 420;

%% Block transition switching fit
muopts = [];
sigmaopts = [];
figure(1);
invalids = []; %idx of invalid blocks where optimization does not converge
for nblock = 1:numel(endpts)
    choices = response(midpts(nblock):endpts(nblock));
    
    if mod(nblock, 2) == 0
        y = 1- (choices + 1)/ 2;
    else
        y = (choices + 1)/ 2;
    end

    % y = [zeros(1, 10), ones(1,20)];

    mu = 10; % Center of transition
    sigma = 0.5; % slope of transition
    xvals = 1:numel(y);
    p = 1 ./ (1 + exp(-((xvals - mu) / sigma)));

    % Avoid taking log of zero
    p = min(p, 0.999);
    p = max(p, 0.001);


    L = sum((1-y) .* log(1-p) + y .* log(p));
    params = [mu, sigma];
    L2 = findLLH(params, y);
%     options = optimset('PlotFcns',@optimplotfval);
    options = optimset('Display', 'off');
    [params_opt,~,flag] = fminsearch(@(p) findLLH(p, y), params, options);

    if flag ~= 1
        fprintf('Warning: block %d: optimization has not converged\n', nblock);
        invalids = [invalids nblock];
    end
    muopt = params_opt(1);
    sigmaopt = params_opt(2);
    popt = 1 ./ (1 + exp(-((xvals - muopt) / sigmaopt)));

    muopts = [muopts muopt];
    sigmaopts = [sigmaopts sigmaopt];
    figure(1);
    subplot(5,6,nblock)
    plot(popt)
    hold on
    plot(y, 'o')
    
    % Vertical line at the block transition
    transition = nextStarts(nblock) - midpts(nblock);
    plot([transition transition], [0 1], 'k--');
end

%%
muopts(invalids) = nan;
muopts(end) = nan;

deltas  = muopts + midpts - nextStarts;

%% Odd and even transitions
figure;
plot(deltas(2:2:numel(endpts)), sigmaopts(2:2:numel(endpts)), 'bo')
hold on
plot(deltas(3:2:numel(endpts)), sigmaopts(3:2:numel(endpts)), 'ro')





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


function cumPerf = get_cumulative_performance(blockResp, target)
% Target is the correct response (1 for moving right and -1 for moving
% left)

cumPerf = [];
for i = 1:numel(blockResp)
    cumPerf(i) = sum(blockResp(1:i) == target) / i;
end

end