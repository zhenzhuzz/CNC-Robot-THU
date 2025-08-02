function [timestamps, accX, spinSpeed, isChatter, fc] = f020_read_timeStamps_accX_spinSpeed_from_txt_07(filename)
    % This function reads the data from a text file and returns the timestamps, accX, and spinSpeed.
    % 此函数从文本文件中读取数据并返回时间戳、accX和spinSpeed。
    %
    % Inputs:
    %   filename: A string representing the path to the data file.
    %   filename: 一个字符串，表示数据文件的路径。
    %
    % Outputs:
    %   timestamps: The first column of the data (timestamps).
    %   timestamps: 数据的第一列（时间戳）。
    %   accX: The second column of the data (acceleration in X direction).
    %   accX: 数据的第二列（X方向加速度）。
    %   spinSpeed: The third column of the data (spin speed).
    %   spinSpeed: 数据的第三列（旋转速度）。

    % 1. 读取数据
    % 1. Read the data from the file
    data = load(filename);  % 假设数据文件存储在当前工作目录
                             % Assuming the data file is stored in the current working directory

    % 2. 提取数据列
    % 2. Extract the columns of data
    timestamps = data(:, 1);  % 第一列是时间戳
    accX = data(:, 2);        % 第二列是 accX
    spinSpeed = data(:, 5);   % 第三列是 spinSpeed
    isChatter = data(:, 6);
    fc = data(:, 7);
end
