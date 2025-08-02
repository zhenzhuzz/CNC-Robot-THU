clc;
clear all;
close all;

% Define parameters for each range of 'i'
params = {
    % n, fz, vc, start_i, end_i
    {'n8000', 'fz0.01875', 'vc201', 1, 10};   % 1-10
    {'n7000', 'fz0.02143', 'vc176', 11, 20};  % 11-20
    {'n6000', 'fz0.025', 'vc151', 21, 30};    % 21-30
    {'n5000', 'fz0.03', 'vc126', 31, 40};     % 31-40
    {'n4000', 'fz0.0375', 'vc101', 41, 50};   % 41-50
    {'n3000', 'fz0.05', 'vc75', 51, 60};      % 51-60
    {'n9000', 'fz0.01667', 'vc226', 61, 70};  % 61-70
    {'n10000', 'fz0.015', 'vc251', 71, 80}    % 71-80
};

% Loop through files 1 to 80
for i = 1:80
    % Generate old filename
    oldName = sprintf('%d.txt', i);
    
    % Check if file exists
    if exist(oldName, 'file') == 2
        % Determine parameters based on the value of 'i'
        for j = 1:length(params)
            if i >= params{j}{4} && i <= params{j}{5}
                n = params{j}{1};
                fz = params{j}{2};
                vc = params{j}{3};
                ap = i - params{j}{4} + 1;
                break;
            end
        end
        
        % Create new filename with parameters
        newName = sprintf('%s_f450_ap%d_ae8_%s_%s_D8_z3_Slot_ENAW7075_150x150x15_20250327.txt', ...
                          n, ap, vc, fz);
        
        % Rename file
        movefile(oldName, newName);
        fprintf('Renamed: %s -> %s\n', oldName, newName);
    else
        fprintf('File %s does not exist.\n', oldName);
    end
end
