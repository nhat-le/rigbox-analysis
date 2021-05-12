%% Perform a batch logistic regression fitting
root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e50';
files = {'2020-12-17/1', ...
    '2020-12-18/4', '2020-12-23/1', '2020-12-24/1', '2020-12-25/1', ...
    '2020-12-26/1', '2020-12-27/1', '2020-12-28/1', '2020-12-29/1', ...
    '2020-12-30/1', '2020-12-31/1', '2021-01-01/1', '2021-01-02/1', ...
    '2021-01-03/1', '2021-01-04/1', '2021-01-05/4', '2021-01-07/1', ...
    '2021-01-08/1', '2021-01-09/1', '2021-01-10/2', '2021-01-11/1', ...
    '2021-01-12/1', '2021-01-13/2', '2021-01-14/2', '2021-01-23/1', ...
    '2021-01-24/1', '2021-01-25/1', '2021-01-26/1', '2021-01-27/1', ...
    '2021-01-28/1', '2021-01-29/1', '2021-02-01/1', '2021-02-02/1', '2021-02-03/1', };

% root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e54';
% files = {'2020-12-18/1', '2020-12-25/1', '2020-12-26/1', '2020-12-26/3',...
%     '2020-12-27/1', '2020-12-28/1', '2020-12-29/1', '2020-12-31/1', ...
%     '2021-01-01/1', '2021-01-02/1', '2021-01-03/1', '2021-01-04/1', ...
%     '2021-01-05/1', '2021-01-06/1', '2021-01-08/1', '2021-01-09/1', ...
%     '2021-01-10/1', '2021-01-11/2', '2021-01-12/1', '2021-01-13/2', ...
%     '2021-01-14/1', '2021-01-15/2', '2021-01-18/1', '2021-01-19/2', ...
%     '2021-01-21/2', '2021-01-22/1', '2021-01-25/1', '2021-01-26/1', ...
%     '2021-01-27/3', '2021-01-28/1', '2021-01-29/1', ...
%     '2021-02-01/3', '2021-02-02/1', '2021-02-03/1'};

% root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e56';
% files = {'2021-02-03/1', '2021-02-02/1', '2021-02-01/1',...
%     '2021-01-29/1', '2021-01-28/1', '2021-01-27/1'};
    


%%


% for i = 1:numel(files)
%     fprintf("'%s', " , files{i});
%     if mod(i,4) == 0
%         fprintf('...\n')
%     end
% end

% root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/e54';
% files = {'2021-01-19/2', '2021-01-21/2', '2021-01-22/1',...
%     '2021-02-01/3', '2021-02-02/1', '2021-02-03/1'};

bAll = [];
devAll = [];
predAll = [];
devAll2 = [];
devAll3 = [];
devAll4 = [];
devAll5 = [];

tback = 4;
for i = 15
    disp(files{i});
    fnames = dir(fullfile(root, files{i}, '*Block.mat'));
    load(fullfile(fnames(1).folder, fnames(1).name), 'block')
    [b, dev, out] = fitLogisticRegression(block, 2);
    [b2, dev2, out2] = fitLogisticRegression(block, 3);
    [b3, dev3, out3] = fitLogisticRegression(block, 4);
    [b4, dev4, out4] = fitLogisticRegression(block, 5);
    [b5, dev5, out5] = fitLogisticRegressionModel2(block, 4);
    bAll(i,:) = b3;
    devAll(i) = dev;
    devAll2(i) = dev2;
    devAll3(i) = dev3;
    devAll4(i) = dev4;
    devAll5(i) = dev5;
end
%%
% For model 1
clcoefs = bAll(:,1) + bAll(:,2) + bAll(:,4);
crcoefs = bAll(:,1) - bAll(:,2) + bAll(:,4);
ilcoefs = bAll(:,1) + bAll(:,3);
ircoefs = bAll(:,1) - bAll(:,3);


clcoefs2back = bAll(:,8) + bAll(:,10);
crcoefs2back = - bAll(:,8) + bAll(:,10);
ilcoefs2back = bAll(:,9);
ircoefs2back = - bAll(:,9);

% % For model 2
% clcoefs = bAll(:,1) + bAll(:,2);
% crcoefs = bAll(:,1) + bAll(:,3);
% ilcoefs = bAll(:,1);
% ircoefs = bAll(:,1);


figure;
plot([clcoefs crcoefs ilcoefs ircoefs], 'LineWidth', 2)
legend({'CL', 'CR', 'IL', 'IR'})

xticks(1:numel(clcoefs))
xticklabels(files);
set(gca, 'XTickLabelRotation', 50, 'FontSize', 16);

xlabel('Day')
ylabel('Contribution to prob (right)')
title('E54 trial history model')

%% Evaluate the goodness of fit
figure;
% plot(devAll);
hold on
plot(devAll2 - devAll + 3, 'LineWidth', 2);
plot(devAll3 - devAll + 6, 'LineWidth', 2);
plot(devAll4 - devAll + 12, 'LineWidth', 2);
plot(devAll5 - devAll + 6, 'LineWidth', 2);

xticks(1:numel(clcoefs))
xticklabels(files);
set(gca, 'XTickLabelRotation', 50, 'FontSize', 16);

xlabel('Day')
ylabel('AIC diff')
title('E54 model fit quantification')
legend({'2-back', '3-back', '4-back', '2-back mod'})


%% Plot the predictions and fit
probpred = 1./(1+exp(-out3.pred));
probfilt = meanfilter(probpred, 1);
plot(out3.trialidx, probfilt)
hold on
plot(out3.trialidx, probfilt, 'x')

% plot(currResp, 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
plot(out3.trialidx(out3.currFb == 1), out3.currResp(out3.currFb == 1) , 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
plot(out3.trialidx(out3.currFb == 0), out3.currResp(out3.currFb == 0) , 'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r')

ylim([-1 2])
hline(0.5, '--')





function [b,dev,output] = fitLogisticRegression(block, tback)
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

output.pred = dMat * b(2:end) + b(1);
output.trialidx = trialidx;
output.currFb = currFb;
output.currResp = currResp;


end



function [b,dev,output] = fitLogisticRegressionModel2(block, tback)
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
    
    dMat = [dMat lastiCorrectL' lastiCorrectR'];
end


% dMat = [respLast1' respLast2' respLast3' fbLast1' fbLast2' fbLast3'];

[b,dev] = glmfit(dMat,currResp','binomial','link','logit', 'constant', 'on');

output.pred = dMat * b(2:end) + b(1);
output.trialidx = trialidx;
output.currFb = currFb;
output.currResp = currResp;


end


