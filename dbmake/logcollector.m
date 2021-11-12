root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
logfiles = dir(fullfile(root, '*/*log.mat'));
f02log = dir(fullfile(root, '*/F02_17-May-2021 12_26_30.mat'));
logfiles(end) = f02log;

% Go through log files and aggregate
logs = {};
for i = 1:numel(logfiles)
    [log, status] = process_log(logfiles, i);
%     disp(status)
    if ~status
        logs{end+1} = log;
    else
        disp('skipping..')
    end
end

aggtable = vertcat(logs{:});
aggtable.value = {aggtable.value.ref}';


%%
l = process_log(logfiles, 1);

%% Save table
% save('logdb.mat', 'aggtable');
logtable = struct('table', struct(aggtable), 'columns', {struct(aggtable).varDim.labels});
save('logdb.mat', 'logtable');


function [log, status] = process_log(logfiles, id)
try
    load(fullfile(logfiles(id).folder, logfiles(id).name), 'log');
    parts = strsplit(logfiles(id).name, '_');
    assert(numel(log) > 0);
    log = struct2table(log);
    log.animal = repmat({lower(parts{1})}, [size(log, 1), 1]);
    status = 0;
    
catch ME
    if strcmp(ME.identifier, 'MATLAB:load:notBinaryFile') %fail to read
        fprintf('failed to read log file: %s\n', logfiles(id).name);
        status = 2;
        log = nan;
    end
end


end


function process_session(logfiles, sessid)


end