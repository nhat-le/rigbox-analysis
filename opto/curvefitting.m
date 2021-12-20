% Load data
% load('data/allanimals_visual_10minus.mat');
% 
% % concat all optos and all non-optos for now
% allOptos = [arrOptoL; arrOptoR];
% allNoOptos = [arrNoOptoL; arrNoOptoR];
% 
% allOptos(allOptos < 0) = nan;
% allNoOptos(allNoOptos < 0) = nan;
% 
% %%
% % Make a sigmoid for all trials
% options = optimset('PlotFcns',@optimplotfval);
% p = fminsearch(@(p) find_LLH(p, allOptos(:,1:20)), [2, 1, 0.1], options);

%% For visualizing the fit
% pmean = nanmean(allOptos(:,1:20), 1);
% xvals = 1:numel(pmean);
% % p = [4, 0.7, 0.21];
% % yvals = mathfuncs.sigmoid(xvals, p(1), p(2), p(3));
% yvals = mathfuncs.sigmoid(xvals, p(1), p(2), p(3));
% 
% figure(1);
% hold off
% plot(pmean)
% hold on
% plot(yvals)

%%
% find_LLH(p, allOptos(:,1:20))

%% For data aggregation
areas = {'frontal', 'motor', 'rsc', 'visual'};
pvals = [];
for i = 1:numel(areas)
    area = areas{i};
    
    load(sprintf('data/allanimals_%s_10minus.mat', area));

    % concat all optos and all non-optos for now
    allOptos = [arrOptoL; arrOptoR];
    allNoOptos = [arrNoOptoL; arrNoOptoR];

    allOptos(allOptos < 0) = nan;
    allNoOptos(allNoOptos < 0) = nan;
    
    % Perform the fitting for opto and non-opto blocks
    p0 = [2, 1, 0.1];
    pOpto = fminsearch(@(p) find_LLH(p, allOptos(:,1:20)), p0);
    pNonOpto = fminsearch(@(p) find_LLH(p, allNoOptos(:,1:20)), p0);

    pvals(i,:,:) = [pNonOpto; pOpto];
    
end


%% Resample for error bar calculation
kreps = 10;
pvals_bootstrap = [];
for i = 1:numel(areas)
    area = areas{i};
    
    load(sprintf('data/allanimals_%s_10minus.mat', area));
    % concat all optos and all non-optos for now
    allOptos = [arrOptoL; arrOptoR];
    allNoOptos = [arrNoOptoL; arrNoOptoR];

    allOptos(allOptos < 0) = nan;
    allNoOptos(allNoOptos < 0) = nan;
    
    nOptos = size(allOptos, 1);
    nNoOptos = size(allNoOptos, 1);
    
    % Perform the fitting for opto and non-opto blocks
    p0 = [2, 1, 0.1];
    
    for k = 1:kreps
        % shuffle the data
        idxO = randsample(1:nOptos, nOptos, true); %sample with replacement
        idxN = randsample(1:nNoOptos, nNoOptos, true);
        
        pOpto = fminsearch(@(p) find_LLH(p, allOptos(idxO,1:20)), p0);
        pNonOpto = fminsearch(@(p) find_LLH(p, allNoOptos(idxN,1:20)), p0);
        pvals_bootstrap(i,k,:,:) = [pNonOpto; pOpto];
    end
    
    
end





%% Plot!
figure(1);
for i = 1:3
    subplot(1,3,i)
    plot(pvals(:,:,i)', 'o-')
    xticks([1,2])
    xticklabels({'No opto', 'Opto'});
    xlim([0, 3])
    legend(areas)
end

%% Plot with error bars
figure(1);
clf;
errs = squeeze(std(pvals_bootstrap, [], 2));
means = squeeze(mean(pvals_bootstrap, 2));
titles = {'Offset', 'Slope', 'Lapse (exploration)'};
for i = [1,2,3]
    subplot(1,3,i)
    
    for j = 1:4
        errorbar((1:2) + 0.05 * j - 0.01, means(j,:,i), errs(j,:,i), 'o-')
        hold on
    end
    xticks([1,2])
    xticklabels({'No opto', 'Opto'});
    xlim([0, 3])
    if i == 3
        legend(areas)
    end
    
    title(titles{i})
    set(gca, 'FontSize', 16)
end




function L = find_LLH(params, data)
xvals = 1:size(data, 2);
mu = params(1);
alpha = params(2);
eps = params(3);
probs = mathfuncs.sigmoid(xvals, mu, alpha, eps);
probs = repmat(probs, [size(data, 1), 1]);

% logLLH
LLH = data .* log(probs) + (1-data) .* log(1 - probs);
L = -nansum(LLH(:));
end
