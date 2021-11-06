% For visualizing the block structures from an animal through training
animals = {'f01', 'f02', 'f11', 'f12', 'f16', 'f17', 'f20', 'f21',...
    'fh01', 'fh02', 'fh03', 'e35', 'e40', 'e50', 'e53', 'e54', 'e46', 'e56'};

agg_all = struct;

for i = 1:numel(animals)
    name = animals{i};
    filedir = sprintf('/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/HMM/animalData_%s_crossval_091521.mat',...
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
    firstsess = find(~isnan(agg_all(i).statefrac), 1);
    if numel(agg_all(i).firstdelay) > 0
        lastsess = agg_all(i).firstdelay;
    else
        lastsess = size(sfrac, 1);
    end
    sfrac_all{i} = sfrac(firstsess : lastsess, :);
end
    

%%
maxlen = max(cellfun(@(x) size(x, 1), sfrac_all));
sfrac_arr = nan(numel(sfrac_all), maxlen);
for i = 1:numel(sfrac_all)
    sfrac_arr(i,1:size(sfrac_all{i},1)) = sfrac_all{i}(:,2);
    
    
end


%% Parse state durations






%% TODO: visualize state transitions
E3_all = cell2mat(E_all(:,2));



%% TODO: analyze kinematics during each block type..

% [a,b] = parse_blocksizes([1 1 1 1 2 2 2 3 3 3 3 3 4 4 2 2 2 2 2 2]);


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
    if i == 55
        disp('here')
    end
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