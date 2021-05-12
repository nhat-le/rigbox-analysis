behavFolder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/E45/2020-12-03/1/';
files = dir(fullfile(behavFolder, '*.mat'));

load(fullfile(files(1).folder, files(1).name));

figure;
ax=axes;
plotPerfProcessedModified(ax,block)
yticks([-1 1])
yticklabels({'Left', 'Right'})
ylim([-3 3])


set(gca, 'FontSize', 16);

ylabel('Choice')
xlabel('Trial #')