clc
% 获取当前目录下所有txt文件的信息
txtFiles = dir('*.txt');

% 提取文件名并将其存储在一个cell数组中
fileNames = {txtFiles.name}';

% 输出文件名
disp(fileNames);
