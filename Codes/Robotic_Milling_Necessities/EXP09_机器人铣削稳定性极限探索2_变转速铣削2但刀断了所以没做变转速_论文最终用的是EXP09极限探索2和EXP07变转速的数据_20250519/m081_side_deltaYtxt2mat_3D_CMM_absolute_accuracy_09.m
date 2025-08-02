%% 清理环境 / Clear workspace and figures
clear; clc; close all;

%% 参数设置 / Parameters
spindleSpeeds     = 3000:1000:10000;             % 转速列表 / list of spindle speeds (RPM)
dataFolder        = 'cmm_09';                    % 数据文件夹 / folder containing data files
subplotGap        = [0, 0.14];                   % tight_subplot 的子图间距 / [vertical, horizontal] gap
marginVertical    = [0, 0];                      % 上下边距 / [bottom, top] margins
marginHorizontal  = [0.09, 0.04];                % 左右边距 / [left, right] margins

%% 读取并重塑 Y 方向切深误差到结构体 YerrorBySpeed 
% / Read & reshape Y-direction delta ap (切深误差) into struct
YerrorBySpeed = struct();                      % 初始化结构体 / initialize struct

for idx = 1:numel(spindleSpeeds)
    speed          = spindleSpeeds(idx);               % 当前转速 / current spindle speed
    fileName       = sprintf('%d_side.txt', speed);    % 文件名 / data file name
    filePath       = fullfile(dataFolder, fileName);   % 完整路径 / full file path

    fileID         = fopen(filePath, 'r');             % 打开文件 / open file for reading
    if fileID < 0
        error('Cannot open file: %s', filePath);       % 打开失败报错 / error if fail
    end

    yDeltaApErrors = [];                                % 存放本文件的 Y 方向切深误差 / vector for Y-direction delta ap errors
    while ~feof(fileID)
        currentLine = fgetl(fileID);                    % 读取一行 / read one line
        if ischar(currentLine) && startsWith(strtrim(currentLine), 'PT')
            % 在接下来的若干行中寻找以 'Y' 开头的行 / search next lines for 'Y'
            for k = 1:15                                % 假设每个 PT 块内不超过 15 行 / assume ≤15 lines per PT block
                subLine = fgetl(fileID);
                if ischar(subLine) && startsWith(strtrim(subLine), 'Y')
                    tokens = strsplit(strtrim(subLine));  
                    yDeltaApErrors(end+1) = str2double(tokens{4});  
                    break;                               % 找到后退出内层循环 / break inner loop
                end
            end
        end
    end

    fclose(fileID);                                     % 关闭文件 / close file

    % 重塑为 10×30 矩阵 / reshape into 10×30 matrix
    % （先 30×10，再转置）/ reshape 1×300 → 30×10 then transpose
    yDeltaMatrix = reshape(yDeltaApErrors, 30, 8)';        

    % 存入结构体字段，字段名如 speed3000, speed4000, … 
    YerrorBySpeed.(sprintf('n%d', speed)) = yDeltaMatrix;
end
