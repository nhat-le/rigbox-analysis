savefile = 1;

root = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox';
logfiles = dir(fullfile(root, '*/*log.mat'));
% f02log = dir(fullfile(root, '*/F02_17-May-2021 12_26_30.mat'));
% logfiles(end) = f02log;

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

% Check for duplicates
nunique = numel(unique(aggtable.date));
assert(nunique == size(aggtable, 1));

%% Save table
% save('logdb.mat', 'aggtable');
% Migrate old logdb file
savedir = '/Users/minhnhatle/Documents/ExternalCode/rigbox_analysis/notebooks';
savename = fullfile(savedir, ['logs/logdb' datestr(datetime, 'YYYY-mm-DD_hh-MM-ss') '.mat']);
logtable = struct('table', struct(aggtable), 'columns', {struct(aggtable).varDim.labels});

if savefile
    copyfile(fullfile(savedir, 'logs/logdb.mat'), savename);

    % Save new logdb file
    save(fullfile(savedir, 'logs/logdb.mat'), 'logtable');
    
    fprintf('File saved\n');
end


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