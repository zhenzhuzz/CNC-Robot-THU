%% 解析 dataLog 前十行的加速度数据
% 确保 dataLog 已存在于工作区中
if ~exist('dataLog','var')
    error('dataLog 变量不存在，请先运行数据采集代码。');
end

% 设置需要解析的行数（最多 10 行）
numRows = min(10, size(dataLog,1));

% 调用解析函数，返回 x, y, z 三个加速度数组
[accX, accY, accZ] = parseDataLog(dataLog, numRows);

% 将解析结果显示为表格
T = table(accX, accY, accZ, 'VariableNames', {'X', 'Y', 'Z'});
disp('dataLog 前十行解析出的加速度数据：');
disp(T);

%% 本地函数：解析 dataLog 数据
function [accX, accY, accZ] = parseDataLog(dataLog, numRows)
    % 预分配存储解析后的加速度数据
    accX = zeros(numRows, 1);
    accY = zeros(numRows, 1);
    accZ = zeros(numRows, 1);
    
    % 循环处理每一行数据
    for i = 1:numRows
        % 提取原始 UDP 数据包（cell 数组第二列）
        packet = dataLog{i,2};
        if length(packet) >= 10
            % 依次解析出 x, y, z，加速度数据用 int16 表示
            accX(i) = typecast(uint8(packet(5:6)), 'int16');
            accY(i) = typecast(uint8(packet(7:8)), 'int16');
            accZ(i) = typecast(uint8(packet(9:10)), 'int16');
        else
            % 如果数据包长度不足，则置为 NaN
            accX(i) = NaN;
            accY(i) = NaN;
            accZ(i) = NaN;
        end
    end
end