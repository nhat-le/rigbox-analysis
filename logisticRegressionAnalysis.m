folder = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e50/2021-01-29/1';
files = dir(fullfile(folder, '*Block.mat'));
load(fullfile(files(1).folder, files(1).name));


% targets = block.events.targetSideValues;
responses = block.events.responseValues;
responses(responses == -1) = 0;
feedback = block.events.feedbackValues;
N = min([numel(responses), numel(feedback)]);


% Make a design matrix
tback = 4;

currResp = responses(tback:N);
currFb = feedback(tback:N);
trialidx = tback:N;
% currResp(currResp==-1) = 0;

respLast1 = responses(tback-1:N-1);
respLast2 = responses(tback-2:N-2);
respLast3 = responses(tback-3:N-3);

fbLast1 = feedback(tback-1:N-1);
fbLast2 = feedback(tback-2:N-2);
fbLast3 = feedback(tback-3:N-3);

last1CorrectL = (1-respLast1) .* fbLast1;
last1CorrectR = respLast1 .* fbLast1;
last1IncorrL = (1-respLast1) .* (1-fbLast1);
last1IncorrR = respLast1 .* (1-fbLast1) ;

last2CorrectL = (1-respLast2) .* fbLast2;
last2CorrectR = respLast2 .* fbLast2;
last2IncorrL = (1-respLast2) .* (1-fbLast2);
last2IncorrR = respLast2 .* (1-fbLast2) ;

last3CorrectL = (1-respLast3) .* fbLast3;
last3CorrectR = respLast3 .* fbLast3;
last3IncorrL = (1-respLast3) .* (1-fbLast3);
last3IncorrR = respLast3 .* (1-fbLast3) ;

% dMat = [respLast1' respLast2' respLast3' fbLast1' fbLast2' fbLast3'];
dMat = [(last1CorrectL' - last1CorrectR') (last1IncorrL' - last1IncorrR')...
    fbLast1' (last2CorrectL' - last2CorrectR') (last2IncorrL' - last2IncorrR')...
    fbLast2' (last3CorrectL' - last3CorrectR') (last3IncorrL' - last3IncorrR')...
    fbLast3'];

dMatB = [(last1CorrectL' - last1CorrectR') (last1IncorrL' - last1IncorrR') ...
    (last2CorrectL' - last2CorrectR') (last2IncorrL' - last2IncorrR')...
    (last3CorrectL' - last3CorrectR') (last3IncorrL' - last3IncorrR')];

dMat2 = [(last1CorrectL' - last1CorrectR') last1IncorrL' last1IncorrR'];
dMat3 = [(last1CorrectL' - last1CorrectR') last1IncorrL' last1IncorrR' ...
    (last2CorrectL' - last2CorrectR') last2IncorrL' last2IncorrR'...
    (last3CorrectL' - last3CorrectR') last3IncorrL' last3IncorrR'];

dMat4 = [(last1CorrectL' - last1CorrectR') last1IncorrL' last1IncorrR' ...
    (last2CorrectL' - last2CorrectR') last2IncorrL' last2IncorrR'];

% dMat3 = [last1CorrectL'];

[b,dev] = glmfit(dMat,currResp','binomial','link','logit', 'constant', 'on');

[b2,dev2] = glmfit(dMat2,currResp','binomial','link','logit', 'constant', 'on');

[b3,dev3] = glmfit(dMat3,currResp','binomial','link','logit', 'constant', 'on');


pred = dMat * b(2:end) + b(1);

% [b3,dev3] = glmfit(dMat3,currResp','binomial','link','logit', 'constant', 'on');


%% Perform a batch logistic regression fitting
% root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e50';
% files = {'2021-01-29/1', '2021-01-28/1', '2021-01-27/1',...
%     '2021-01-26/1', '2021-01-25/1', '2021-01-24/1', '2021-01-23/1', ...
%     '2021-01-22/1', '2021-02-01/1', '2021-02-02/1', '2021-02-03/1'};

root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e54';
files = {'2021-01-19/2', '2021-01-21/2', '2021-01-22/1',...
    '2021-02-01/3', '2021-02-02/1', '2021-02-03/1'};

bAll = [];
devAll = [];
predAll = [];
for i = 1:numel(files)
    fnames = dir(fullfile(root, files{i}, '*Block.mat'));
    load(fullfile(fnames(1).folder, fnames(1).name), 'block')
    [b, dev, pred] = fitLogisticRegression(block, 6);
    bAll(i,:) = b;
    devAll(i) = dev;
end

clcoefs = bAll(:,1) + bAll(:,2) + bAll(:,4);
crcoefs = bAll(:,1) - bAll(:,2) + bAll(:,4);
ilcoefs = bAll(:,1) + bAll(:,3);
ircoefs = bAll(:,1) - bAll(:,3);

plot([clcoefs crcoefs ilcoefs ircoefs])
legend({'CL', 'CR', 'IL', 'IR'})
% (lastiCorrectL' - lastiCorrectR') (lastiIncorrL' - lastiIncorrR')...
%     fbLasti'

% [balt, devalt, predalt] = fitLogisticRegression(block, 4);

%% Plot the predictions
pred3 = dMat * b(2:end) + b(1);
plot(trialidx, 1./(1+exp(-pred3)))
hold on
plot(trialidx, 1./(1+exp(-pred3)), 'x')

% plot(currResp, 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
plot(trialidx(currFb == 1), currResp(currFb == 1) , 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
plot(trialidx(currFb == 0), currResp(currFb == 0) , 'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r')

ylim([-2 2])




function [b,dev,pred] = fitLogisticRegression(block, tback)
responses = block.events.responseValues;
responses(responses == -1) = 0;
feedback = block.events.feedbackValues;
N = min([numel(responses), numel(feedback)]);


% Make a design matrix
% tback = 4;

currResp = responses(tback:N);
currFb = feedback(tback:N);
trialidx = tback:N;
% currResp(currResp==-1) = 0;

dMat = [];
for i = 1:tback - 1
    respLasti = responses(tback - i : N-i);
    fbLasti = feedback(tback - i: N-i);
    lastiCorrectL = (1-respLasti) .* fbLasti;
    lastiCorrectR = respLasti .* fbLasti;
    lastiIncorrL = (1-respLasti) .* (1-fbLasti);
    lastiIncorrR = respLasti .* (1-fbLasti) ;
    
    dMat = [dMat (lastiCorrectL' - lastiCorrectR') (lastiIncorrL' - lastiIncorrR')...
    fbLasti'];
end


% dMat = [respLast1' respLast2' respLast3' fbLast1' fbLast2' fbLast3'];

[b,dev] = glmfit(dMat,currResp','binomial','link','logit', 'constant', 'on');

pred = dMat * b(2:end) + b(1);

end


