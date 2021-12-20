load('/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox/f16/2021-08-23/1/2021-08-23_1_f16_Timeline.mat')
%%
% rawDAQData contains the synchronization signals
% Timeline.rawDAQData(:,1) is the fixed synchronizer
% Timeline.rawDAQData(:,2) is the brain imaging frames
% Timeline.rawDAQData(:,3) is the pupil
% Timeline.rawDAQData(:,4) is lick data
% Timeline.rawDAQData(:,5) is the trial start/response times


r1 = Timeline.rawDAQData(:,3);
r2 = Timeline.rawDAQData(:,1) > 2;

% plot(r1)
% hold on
% plot(r2)
resultZero = r1;
resultZero(r2 > 0) = 0;


resultPos= r1;
resultPos(r2 == 0) = 5;
resultPos = 5-resultPos;


[pksZero, locsZero] = findpeaks(resultZero, 'MinPeakHeight', 3);
[pksPos, locsPos] = findpeaks(resultPos, 'MinPeakHeight', 0.2);
locsPos = locsPos(pksPos < 0.3);
pksPos = pksPos(pksPos < 0.3);

locsAll = sort([locsPos; locsZero]);





%% Remove outliers
dt = diff(locsAll);
plot(dt(dt > 60 & dt < 80))

% For too soon spikes: remove
tooSoon = find(dt < 60);
locsAll(tooSoon + 1) = [];

% For too late spikes: insert one in the middle
dt = diff(locsAll);
tooLate = find(dt > 80);
shift = 0; % to account for additional spikes
for i = 1:numel(tooLate)
    idx = tooLate(i);
    newspike = (locsAll(idx + shift) + locsAll(idx + shift + 1)) / 2;
    locsAll = [locsAll(1:idx + shift);  newspike; locsAll(idx + shift + 1:end)];
    shift = shift + 1;
end


%% Visualize
plot(r1)
hold on
plot(locsAll(1:100), 4.8, 'rx');
% plot(locsPos(1:100), 5, 'rx');


%% Try to get rid of the transient...
% idxStart = find(r2(2:end) == 1 & r2(1:end-1) == 0);
% allblocks = [];
% for i = 1:numel(idxStart)-1
%     allblocks(:,i) = r1(idxStart(i) : idxStart(i)+2000);
% end




%%
resultPos = (5 - resultPos) * 20;
resultPos(r2 == 0) = 0;
plot(resultPos + resultZero)