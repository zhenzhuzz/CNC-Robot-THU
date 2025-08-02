function dataMatrix = func_readAcc(filepath, direction)
    % Read the entire file as text
    fileID = fopen(filepath, 'r');
    fileContent = textscan(fileID, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fileID);
    
    % Extract lines
    lines = fileContent{1};
    
    % Identify the header line (where numeric data starts)
    headerEndIndex = 0;
    for i = 1:length(lines)
        % Try to read the line as numeric data
        numericData = str2num(lines{i}); %#ok<ST2NM>
        if ~isempty(numericData)
            headerEndIndex = i - 1;
            break;
        end
    end

    % Read the data matrix by skipping the identified header lines
    dataMatrix = readmatrix(filepath, 'FileType', 'text', 'NumHeaderLines', headerEndIndex);
    
    % Define new headers based on the number of columns
    numColumns = size(dataMatrix, 2);
    if numColumns >= 6
        % Depending on the specified direction, retain the corresponding columns
        if nargin < 2
            direction = 'XYZ'; % Default to reading all three directions
        end
        
        switch direction
            case 'X'
                dataMatrix = dataMatrix(:, [1, 2]);
            case 'Y'
                dataMatrix = dataMatrix(:, [1, 4]);
            case 'Z'
                dataMatrix = dataMatrix(:, [1, 6]);
            otherwise
                dataMatrix = dataMatrix(:, [1, 2, 4, 6]); % Retain time and XYZ columns
        end
    end
    
    % Create a valid variable name
    [~, fileName, ~] = fileparts(filepath);
    switch direction
        case 'X'
            varName = matlab.lang.makeValidName(['surf' fileName '_X']);
        case 'Y'
            varName = matlab.lang.makeValidName(['surf' fileName '_Y']);
        case 'Z'
            varName = matlab.lang.makeValidName(['surf' fileName '_Z']);
        otherwise
            varName = matlab.lang.makeValidName(['surf' fileName]);
    end
    
    % Assign the matrix to a variable named according to the Acc file name
    % assignin('base', varName, dataMatrix);
end
