load('E45rigboxSwitchingFits_withinvalids.mat')

nblocks_all = {};
ndeltas_good = {};
for id = 1:15
    load(fullfile(files(id).folder, files(id).name))

    targets = block.events.contrastLeftValues;
    dblocks = diff(targets);
    trans = find(dblocks ~= 0);
    blockLengths = diff(trans);
    deltaBlock = alldeltas{id};
    nCorrBlock = blockLengths-deltaBlock;

    figure;
    plot(nCorrBlock(1:end-1) + 0.1 * rand(1,numel(nCorrBlock) - 1), deltaBlock(2:end), 'o')
    nblocks_all{id} = nCorrBlock(1:end-1);
    ndeltas_good{id} = deltaBlock(2:end);
end


%% Combine blocks now
allnblocks = cell2mat(nblocks_all);
alldeltasall = cell2mat(ndeltas_good);

allnblocksLast = cell2mat(nblocks_all(10:12));
alldeltasLast = cell2mat(ndeltas_good(10:12));


figure;
plot(allnblocks, alldeltasall, 'o')
hold on
plot(allnblocksLast, alldeltasLast, 'ro')
