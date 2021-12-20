% For visualizing the block structures from an animal through training
animals = {'f01', 'f02', 'f11', 'f12', 'f16', 'f17', 'f20', 'f21',...
    'fh01', 'fh02', 'fh03', 'e35', 'e40', 'e50', 'e53', 'e54', 'e46', 'e56'};
% missing e57..

agg_all = struct;


dateranges = {[7, 29],... %f01
            [7, 29],... %f02
            [6, 28],... %f11
            [6, 29],... %f12
            [7, 20],... %f16
            [7, 20],... %f17
            [7, 22],... %f20
            [7, 22], ... %f21
            [7, 16], ... %fh01
            [3, 16], ... %fh02
            [4, 27], ... %fh03
            [15, 48],... %e35
            [5, 29],... %e40
            [13, 30], ...%e50
            [5, 58], ...%e53
            [4, 26], ... %e54
            [7, 11], ...%e46
            [8, 23]};  %e56




for i = 1:numel(animals)
    name = animals{i};
    filedir = sprintf('/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM/animalData_%s_crossval_091621.mat',...
        name);
    disp(filedir)
    load(filedir)
    
    [aggStates, firstdelay,~, permutedprobsAll] = get_states(pstates_all, E_all, animal, maxdelays);
    
    
    % Parse the state durations
    % Need to discard the last block...

    states1 = sum(aggStates == 1, 2);
    states2 = sum(aggStates == 2, 2);
    states3 = sum(aggStates == 3, 2);
    
    agg_all(i).animal = name;
    agg_all(i).aggStates = aggStates;
    agg_all(i).firstdelay = firstdelay;
    agg_all(i).statecounts = [states1 states2 states3];
    agg_all(i).statefrac = agg_all(i).statecounts ./ sum(agg_all(i).statecounts, 2);
    agg_all(i).permutedprobs = permutedprobsAll;
    agg_all(i).daterange = dateranges{i};
    
    % Parse blocksizes
    blockvals_all = {};
    blocksizes_all = {};
    block1lengths = {};
    block2lengths = {};
    block3lengths = {};
    for j = 1:size(aggStates, 1)
        arr = aggStates(j,:);
        [blockvals, blocksizes] = parse_blocksizes(arr); 
        blockvals_all{j} = blockvals;
        blocksizes_all{j} = blocksizes;
        block1lengths{j} = blocksizes(blockvals == 1);
        block2lengths{j} = blocksizes(blockvals == 2);
        block3lengths{j} = blocksizes(blockvals == 3);
    end
    
    agg_all(i).block1lengths = block1lengths;
    agg_all(i).block2lengths = block2lengths;
    agg_all(i).block3lengths = block3lengths;
    
end

%% Parse state fractions for all animals
sfrac_all = {};
for i = 1:numel(agg_all)
    sfrac = agg_all(i).statefrac;
%     firstsess = find(~isnan(agg_all(i).statefrac), 1);
%     if numel(agg_all(i).firstdelay) > 0
%         lastsess = agg_all(i).firstdelay;
%     else
%         lastsess = size(sfrac, 1);
%     end
    firstsess = agg_all(i).daterange(1);
    lastsess = agg_all(i).daterange(2);
    sfrac_all{i} = sfrac(firstsess : lastsess, :);
end
    

%%
sarr1 = pad_to_same_length(sfrac_all, 1);
sarr2 = pad_to_same_length(sfrac_all, 2);
sarr3 = pad_to_same_length(sfrac_all, 3);
[Nanimals, Nsess] = size(sarr1);
% 
figure;
errorbar(1:Nsess, nanmean(sarr1, 1), nanstd(sarr1, [], 1) / sqrt(Nanimals));
hold on
errorbar(1:Nsess, nanmean(sarr2, 1), nanstd(sarr2, [], 1) / sqrt(Nanimals));
errorbar(1:Nsess, nanmean(sarr3, 1), nanstd(sarr3, [], 1) / sqrt(Nanimals));
xlim([1,20])
mymakeaxis('x_label', 'Sessions', 'y_label', 'Fraction');

%%
for i = 1:10
    subplot(5,2,i)
    plot(sarr2(i,:))
    xlim([0, 25])
end


%% Parse state durations
% visualize single-animal state durations
idx = 2;
block1lengths = agg_all(idx).block1lengths;
block2lengths = agg_all(idx).block2lengths;
block3lengths = agg_all(idx).block3lengths;

block1medians = cellfun(@(x) median(x), block1lengths); 
block2medians = cellfun(@(x) median(x), block2lengths); 
block3medians = cellfun(@(x) median(x), block3lengths); 

figure;
plot(block1medians)
hold on
plot(block2medians, '--')
plot(block3medians)


%%
figure;
hold on
for i = 1:numel(block1lengths)
    if numel(block1lengths{i}) == 0
        continue
    end
    plot(block1lengths{i},i, 'r.')
    plot(block2lengths{i},i, 'bx')
    plot(block3lengths{i},i, 'go')
    
    
    
end



%% TODO: visualize state transitions
probsallcell1 = {};
probsallcell2 = {};
probsallcell3 = {};

for idx = 1:numel(agg_all)
    probsall = cell2mat(agg_all(idx).permutedprobs');
    daterange = dateranges{idx};
    probsall = probsall(:, daterange(1):daterange(2));
%     figure;
%     plot(probsall')
%     title(agg_all(idx).animal);
    probsallcell1{idx} = probsall(1,:)';
    probsallcell2{idx} = probsall(2,:)';
    probsallcell3{idx} = probsall(3,:)';
end

%%
probsallarr1 = pad_to_same_length(probsallcell1', 1);
probsallarr2 = pad_to_same_length(probsallcell2', 1);
probsallarr3 = pad_to_same_length(probsallcell3', 1);

figure;
plot(nanmean(probsallarr1, 1))
hold on
plot(nanmean(probsallarr2, 1))
plot(nanmean(probsallarr3, 1))

xlim([1, 20])
mymakeaxis('x_label', 'Session', 'y_label', 'Probability');



%% TODO: analyze kinematics during each block type..



function [blockvals, blocksizes] = parse_blocksizes(arr)
% Returns the lengths of consecutive blocks
arr(end+1) = -1;
currsize = 0;
prevval = nan;
blockvals = [];
blocksizes = [];

for i = 1:numel(arr)
    currval = arr(i);
    if currval ~= prevval
        blockvals(end+1) = prevval;
        blocksizes(end+1) = currsize;
%         disp(blocksizes)
        currsize = 1;
    else
        currsize = currsize + 1;
%         disp(currsize);
    end
    
    prevval = currval;
end

blockvals = blockvals(2:end);
blocksizes = blocksizes(2:end);


end





function [aggStates, firstdelay, probs, permutedprobsAll] = get_states(pstates_all, E_all, animal, maxdelays)
% Determine the states
statesArr = pstates_all(:,2); %{animalData.PSTATES.states3};
maxArr = cell(numel(statesArr), 1);

if strcmp(animal, 'f11')
    E_all(49,:) = [];
end

emisAll = E_all(:,2)';%{animalData.sessionInfo.EMIS_EST3};
order = find_state_order(emisAll);
probs = find_state_probs(emisAll);
permutedAll = cell(numel(statesArr), 1);
probsAll = cell(numel(statesArr), 1);
permutedprobsAll = cell(numel(statesArr), 1);

if strcmp(animal, 'f11')
    maxArr(49) = [];
    statesArr(49) = [];
end

% from state probs in statesArr, find the state that
% has the max probability among the three
for i = 1:numel(statesArr)
	maxstates = get_currstate(statesArr{i});
    maxArr{i} = maxstates;
end

% Perform the permutation
for i = 1:numel(maxArr)
%     if i == 55
%         disp('here')
%     end
%     disp(i)
    single_arr = maxArr{i};
%     disp(single_arr)
    
    % Permute
    permuted_state = single_arr;
    single_prob = single_arr;
%     disp(i)
%     disp(size(emisAll{i}));
    prev_prob = emisAll{i}(:,1);
    permuted_prob = emisAll{i}(:,1);
    
    curr_order = order(:,i);
    curr_prob = probs(:,i);
    
    % Make the remap: state 1 -> curr_order(1)
    % state 2 -> curr_order(2)
    % state 3 -> curr_order(3)
    permuted_state(single_arr == 1) = curr_order(1);
    permuted_state(single_arr == 2) = curr_order(2);
    permuted_state(single_arr == 3) = curr_order(3);
    single_prob(single_arr == 1) = curr_prob(1);
    single_prob(single_arr == 2) = curr_prob(2);
    single_prob(single_arr == 3) = curr_prob(3);
    
    permuted_prob(curr_order(1)) = prev_prob(1);
    permuted_prob(curr_order(2)) = prev_prob(2);
    permuted_prob(curr_order(3)) = prev_prob(3);
    
    
    
    permutedAll{i} = permuted_state;
    probsAll{i} = single_prob;
    permutedprobsAll{i} = permuted_prob;
end




% Assemble the permuted states
maxlen = max(cellfun(@(x) numel(x), permutedAll));
aggStates = nan(numel(maxArr), maxlen);
for i = 1:numel(permutedAll)
    aggStates(i, 1:numel(permutedAll{i})) = permutedAll{i};
end

aggStates(isnan(aggStates)) = 4;

% start of delay sessions
firstdelay = find(maxdelays > 0, 1);


end


function maxstates = get_currstate(arr)
% get the current state
maxstates = argmax(arr);
end


function order = find_state_order(emisAll)
emisArr = cell2mat(emisAll);
emisArr = emisArr(:,1:2:end);

% Find the permutations of the states
[~,orderpre] = sort(emisArr);
[~,order] = sort(orderpre);
end


function probs = find_state_probs(emisAll)
emisArr = cell2mat(emisAll);
probs = emisArr(:,1:2:end);

end

function visualize_cell(arr, name)
maxlen = max(cellfun(@(x) numel(x), arr));
aggStates = nan(numel(arr), maxlen);
for i = 1:numel(arr)
    aggStates(i, 1:numel(arr{i})) = arr{i};
end

aggStates(isnan(aggStates)) = 4;


%% Plot
figure;
imagesc(aggStates * 2 - 1);
title(name);
xlabel('Trials')
ylabel('Session')
set(gca, 'FontSize', 16)
% colormap(bluewhitered(256))
cmap = brewermap(256, 'RdBu');
caxis([-1,1])
colormap(cmap);
% colormap(bluewhitered(256))

% colormap jet
end