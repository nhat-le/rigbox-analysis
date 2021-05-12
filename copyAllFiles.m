% rootFrom = 'C:\LocalExpData';
% rootLogFrom = 'C:\LocalExpData\subjects';
% rootTo = 'D:\Dropbox (MIT)\Nhat\Rigbox\';
% animals = {'e54', 'e53', 'e50', 'f03', 'f04'};

rootFrom = '\\2P2-BEHAVIOR-PC\LocalExpData';
rootLogFrom = '\\2P2-BEHAVIOR-PC\LocalExpData\subjects';
rootTo = 'C:\Users\3P1_Behavior\Dropbox (MIT)\Nhat\Rigbox\';
animals = {'e53', 'fh02', 'f05'};
%% Copy the data files
for i = 1:numel(animals)
    animal = animals{i};
    dirFrom = fullfile(rootFrom, animal);
    dirTo = fullfile(rootTo, animal);
    copyfile(dirFrom, dirTo);
    fprintf('Copied: animal %s\n', animal);
end


%% Copy the log files
for i = 1:numel(animals)
    animal = animals{i};
    fprintf('Copying log file for animal %s\n', animal);
    
    % Rename the existing log folder just in case..
    dirFrom = fullfile(rootFrom, animal);
    dirTo = fullfile(rootTo, animal);
    dirLogFrom = fullfile(rootLogFrom, animal);
    
    % Find the log file
    logfile = dir(fullfile(dirLogFrom, '*log.mat'));
    
    if numel(logfile) ~= 1
        error('No log file found!');
    end
    
    % Find any old log file
    oldlogfile = dir(fullfile(dirTo, '*log.mat'));
    
    if numel(oldlogfile) > 0 && strcmp(logfile(1).name, oldlogfile(1).name)
        % Rename old log file
        oldlogpath = fullfile(oldlogfile(1).folder, oldlogfile(1).name);
        oldname = oldlogfile(1).name;
        newname = [oldname(1:end-7) strrep(datestr(datetime), ':', '_'), '.mat'];
        copiedlogpath = fullfile(oldlogfile(1).folder, newname);
        
        movefile(oldlogpath, copiedlogpath);
    end
    
    % Now copy the new log file
    fromlogpath = fullfile(logfile(1).folder, logfile(1).name);
    tologpath = fullfile(dirTo, logfile(1).name);
    copyfile(fromlogpath, tologpath);
    fprintf('Copied log: animal %s\n', animal);
end







