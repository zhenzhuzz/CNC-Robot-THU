clc;
clear all;
close all;

% List of the specific spindle speeds (3000, 4000, ..., 10000)
speeds = [3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000];

% Loop through the speeds array
for i = 1:length(speeds)
    % Generate the old filename
    oldName = sprintf('%d.txt', speeds(i));
    
    % Check if the file exists
    if exist(oldName, 'file') == 2
        % Create the new filename with the desired format
        newName = sprintf('n%d_idle_20250327.txt', speeds(i));
        
        % Rename the file
        movefile(oldName, newName);
        fprintf('Renamed: %s -> %s\n', oldName, newName);
    else
        fprintf('File %s does not exist.\n', oldName);
    end
end
