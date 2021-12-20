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
        subplot(3,4,nblock)
        plot(popt, 'LineWidth', 1.5)
        hold on
        plot(y, 'bo', 'MarkerFaceColor', 'b')
        plot(muopt, 0.5, 'ro', 'MarkerFaceColor', 'r'); 

        % Vertical line at the block transition
        transition = nextStarts(nblock) - midpts(nblock);
        plot([transition transition], [0 1], 'k--', 'LineWidth', 1.5);
%         xlabel('Trials')
%         ylabel('Choice or Probability')
    end
end

% Find deltas
muopts(invalids) = nan;
deltas  = muopts + midpts - nextStarts;
% set(gca, 'FontSize', 16);


end


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