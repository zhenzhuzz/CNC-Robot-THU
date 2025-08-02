% Step 1: Read the content of the text file
fileID = fopen('message_log_2025-04-07_01-06-07.txt', 'r', 'n', 'UTF-8');
data = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);

% Step 2: Initialize the variables for storing time and n_new values
n_new_values = []; % Variable to store n_new values
time_values = [];  % Variable to store time values

% Step 3: Parse the data and extract n_new values between t = 7.3s and t = 32.8s
for i = 1:length(data{1})
    line = data{1}{i};
    
    % Look for lines containing 't = ' (time values)
    time_pattern = 't = ';
    if contains(line, time_pattern)
        % Extract the time value
        time_str = extractBetween(line, time_pattern, 's');
        time_val = str2double(time_str{1});
        
        % Check if the time is within the desired range
        if time_val >= 7.3 && time_val <= 32.8
            % Extract n_new value
            n_new_pattern = 'n_new = ';
            if contains(line, n_new_pattern)
                n_new_str = extractBetween(line, n_new_pattern, 'rpm');
                n_new_val = str2double(n_new_str{1});
                
                % Store the time and n_new values
                time_values = [time_values; repmat(time_val, 1280, 1)];
                n_new_values = [n_new_values; repmat(n_new_val, 1280, 1)];
            end
        end
    end
end

% Step 4: Display the n_new values
disp('Time (s) and n_new values between t = 7.3s and t = 32.8s:');
disp(table(time_values, n_new_values));
