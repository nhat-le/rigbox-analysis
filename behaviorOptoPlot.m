% filename = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/E45/2020-11-23/4/2020-11-23_4_E45_Block.mat';
filename = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f11/2021-07-12/1/2021-07-12_1_f11_Block.mat';
load(filename);
figure;
ax = axes;
plotData(ax, block);
xlim([0, 134])
xlabel('Trial #')
ylabel('Choice')
grid off
% set(gca,'visible','off')
set(gca,'color','none')
set(gca, 'box', 'off')


function plotData(ax, block)
contrast = [];
contrast(1,:) = [block.events.contrastLeftValues];
contrast(2,:) = [block.events.contrastRightValues];

response = [block.events.responseValues];
repeatNum = [block.events.repeatNumValues];


% Make contrast, response and repeat num the same length
N = numel(response);
contrast = contrast(:,1:N);
repeatNum = repeatNum(:,1:N);
incl = ~any(isnan([contrast;response;repeatNum]));
contrast = contrast(:,incl);
response = response(incl);
% repeatNum = repeatNum(incl);

trialstart = 1:numel(response);
dcontrast = diff(contrast, [], 1);


% Find choice types

% First plot the time-outs
% cla(ax)
timeouts = find(response == 0);
plot(ax, trialstart(timeouts), dcontrast(timeouts), 'ko', 'MarkerFaceColor', 'k');
hold(ax, 'on')

% Plot the leftward/rightward trials
leftCorr = find(response == -1 & sign(dcontrast) == response);
leftIncorr = find(response == -1 & sign(dcontrast) ~= response);
rightCorr = find(response == 1 & sign(dcontrast) == response);
rightIncorr = find(response == 1 & sign(dcontrast) ~= response);

plot(ax, trialstart(leftCorr), ones(1,numel(leftCorr)) * -1, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8)
plot(ax, trialstart(rightCorr), ones(1,numel(rightCorr)), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8)
plot(ax, trialstart(leftIncorr), ones(1,numel(leftIncorr)) * -1, 'bx', 'MarkerSize', 8, 'LineWidth', 1.5)
plot(ax, trialstart(rightIncorr), ones(1,numel(rightIncorr)), 'rx', 'MarkerSize', 8, 'LineWidth', 1.5)


% Plot the moving average
N = 10; % define window
convFilter = ones(1,N) / N;
movAverage = conv(response, convFilter, 'same');
% plot(ax, movAverage, 'k', 'LineWidth', 1)



% Fill areas to indicate block transitions
tTransitions = find(diff(dcontrast));
tTransitions = [0 tTransitions numel(dcontrast)];
for i = 1:numel(tTransitions)-1
    if i > 1
        plot(ax, [tTransitions(i) tTransitions(i)], [-2 1.5], 'k--', 'LineWidth', 1.5);
    end
    curr = tTransitions(i);
    next = tTransitions(i+1);
    
    if ~ismember(i, [1,2,6]) %dcontrast(tTransitions(i) + 1) == 1
        fill(ax, [curr next next curr], [1.8 1.8 2.3 2.3], 'k', 'EdgeAlpha', 0);
        text(ax, (curr + next)/2 - 3.2, 2.1, 'NL', 'Color', 'w', 'FontSize', 16);
    else
        fill(ax, [curr next next curr], [1.8 1.8 2.3 2.3], 'b', 'EdgeAlpha', 0);
        text(ax, (curr + next)/2 - 4.5, 2.1, 'Opto', 'Color', 'w', 'FontSize', 16);
    end
end


set(ax, 'YTick', [-1 1])
set(ax, 'YTickLabel', {'Left', 'Right'})
set(ax, 'FontSize', 16)
ylim(ax, [-3 3])
end