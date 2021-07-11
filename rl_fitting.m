% For fitting behavior with an RL-model
%% Load behavior data
datadir = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f01/2021-03-26/1';
files = dir(fullfile(datadir, '*Block.mat'));
load(fullfile(files(1).folder, files(1).name));

response = block.events.responseValues;
targets = block.events.contrastRightValues;
feedback = block.events.feedbackValues;
N = min([numel(response), numel(targets), numel(feedback)]);
response = response(1:N);
targets = targets(1:N);
feedback = feedback(1:N);

%% 
alpha = params(1);
beta = params(2);
offset = params(3);
[v0, v1] = create_value_arr(alpha, response, feedback);
% beta = 1;
prob = sigmoid(v1 - v0, beta, offset);
prob = prob';
responsebinary = response > 0;
ll = responsebinary .* log(prob) + (1-responsebinary) .* log(1 - prob);
ll = sum(ll);

plot(prob);
hold on
plot(responsebinary, 'o')
plot(feedback, 'x');

%% Fit the llh with maximum LLH
p0 = [0.2, 1, 0];
options = optimset('PlotFcns',@optimplotfval);
params = fminsearch(@(p) neg_choice_likelihood(response, feedback, p), p0, options);




function ll = neg_choice_likelihood(response, feedback, p)
% beta: sharpness parameter of the sigmoid
alpha = p(1);
beta = p(2);
offset = p(3);

[v0, v1] = create_value_arr(alpha, response, feedback);
prob = sigmoid(v1 - v0, beta, offset);
prob = prob';
responsebinary = response > 0;
ll = responsebinary .* log(prob) + (1-responsebinary) .* log(1 - prob);
ll = -sum(ll);


end


function y = sigmoid(x, beta, offset)
y = 1 ./ (1 + exp(-(x - offset) * beta));

end


function [values0, values1] = create_value_arr(alpha, response, feedback)
value0 = 0; % left value (value of side = 0)
value1 = 0; % right value (value of side = 1)
N = numel(response);
values0 = zeros(N, 1);
values1 = zeros(N, 1);
for i = 1:N-1
    if response(i) == 1
        value1 = value1 + alpha * (feedback(i) - value1);
        
    elseif response(i) == -1
        value0 = value0 + alpha * (feedback(i) - value0);
        
    elseif response(i) ~= 0

        error('Invalid response');
        
    end
    
    values0(i+1) = value0;
    values1(i+1) = value1;
end


end

