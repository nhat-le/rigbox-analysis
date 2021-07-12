% For visualizing the block structures from an animal through training
filedir = '/Users/minhnhatle/Dropbox (MIT)/Nhat/animalHMMData/animalData_f02.mat';
load(filedir)
name = animalData.name;

% Determine the states
statesArr = {animalData.PSTATES.states3};
maxArr = cell(numel(statesArr), 1);
emisAll = {animalData.sessionInfo.EMIS_EST3};
order = find_state_order(emisAll);
probs = find_state_probs(emisAll);
permutedAll = cell(numel(statesArr), 1);
probsAll = cell(numel(statesArr), 1);


for i = 1:numel(statesArr)
	maxstates = get_currstate(statesArr{i});
    maxArr{i} = maxstates;
end

% Perform the permutation
for i = 1:numel(maxArr)
%     disp(i)
    single_arr = maxArr{i};
%     disp(single_arr)
    
    % Permute
    permuted = single_arr;
    single_prob = single_arr;
    
    curr_order = order(:,i);
    curr_prob = probs(:,i);
    permuted(single_arr == 1) = curr_order(1);
    permuted(single_arr == 2) = curr_order(2);
    permuted(single_arr == 3) = curr_order(3);
    single_prob(single_arr == 1) = curr_prob(1);
    single_prob(single_arr == 2) = curr_prob(2);
    single_prob(single_arr == 3) = curr_prob(3);
    
    
    
    permutedAll{i} = permuted;
    probsAll{i} = single_prob;
end




%% Assemble the permuted states
maxlen = max(cellfun(@(x) numel(x), permutedAll));
aggStates = nan(numel(maxArr), maxlen);
for i = 1:numel(permutedAll)
    aggStates(i, 1:numel(permutedAll{i})) = permutedAll{i};
end

aggStates(isnan(aggStates)) = 4;


%% Plot
figure;
imagesc(aggStates);
title(name);
xlabel('Trials')
ylabel('Session')
set(gca, 'FontSize', 16)
colormap jet

%%
visualize_cell(probsAll, name)


%%
figure
imagesc(peaks(250));
colormap(bluewhitered(256)), colorbar


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
caxis([-1,1])
colormap(bluewhitered(256))


end