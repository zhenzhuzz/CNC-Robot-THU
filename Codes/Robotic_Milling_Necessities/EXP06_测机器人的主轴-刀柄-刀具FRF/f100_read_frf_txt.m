function [freq, FRF_complex] = f100_read_frf_txt(filename)
% read_frf_txt - Read FRF data from LMS TestLab txt file
% 从LMS TestLab导出的txt文件中读取FRF频响函数数据
%
% Inputs:
%   filename - String, path to the FRF txt file exported from LMS TestLab
%              字符串，LMS TestLab导出FRF txt文件的路径
%
% Outputs:
%   freq - Frequency vector (Hz)
%          频率向量（Hz）
%   FRF_complex - Complex FRF data (Acceleration/Force)
%                 复数形式FRF数据（加速度/力）

    % Open the file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open the file %s.', filename);
    end
    
    % Skip headers (find the first numeric data line)
    line = '';
    while ~feof(fid)
        line = fgetl(fid);
        % Detect the start of numeric data
        if ~isempty(line) && ~isnan(str2double(strtok(line)))
            break;
        end
    end
    
    % Initialize arrays to store data
    freq = [];
    real_part = [];
    imag_part = [];

    % Read numeric data line by line
    while ischar(line)
        numeric_data = sscanf(line, '%f');
        if numel(numeric_data) >= 3
            freq(end+1, 1) = numeric_data(1);           % Frequency
            real_part(end+1, 1) = numeric_data(2);      % Real part
            imag_part(end+1, 1) = numeric_data(3);      % Imaginary part
        end
        line = fgetl(fid);
    end
    
    fclose(fid);
    
    % Form complex FRF data
    FRF_complex = real_part + 1i * imag_part;

end
