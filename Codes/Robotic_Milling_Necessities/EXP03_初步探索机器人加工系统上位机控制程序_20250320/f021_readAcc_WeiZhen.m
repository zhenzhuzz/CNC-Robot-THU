function dataMatrix = f021_readAcc_WeiZhen(filepath, direction)
% f021_readAcc_WeiZhen 解析特定格式的加速度数据文件
%
%   dataMatrix = f021_readAcc_WeiZhen(filepath, direction) 从指定文件中读取
%   加速度数据并返回一个 table，table 的第一列为时间（单位秒，从0开始计时），
%   后续列依次为 X, Y, Z 加速度数据。文件格式如下：
%
%       解析值1,解析值2,解析值3,解析值4,时间戳,时间戳序号
%       44,979,23,980.258,1741758176902,0
%       ...
%
%   其中：
%       解析值1,解析值2,解析值3 分别代表 X, Y, Z 加速度；
%       时间戳为1970年1月1日以来的毫秒数
%
%   输入参数：
%       filepath  - 数据文件的完整路径
%       direction - 指定返回数据的方向，可选 'X', 'Y', 'Z' 或 'XYZ'（默认 'XYZ'）
%
%   输出：
%       dataMatrix - table 格式的数据；若 direction 为 'XYZ'，table 包含 4 列：
%                    Time, X, Y, Z；若为单一方向，则 table 包含 Time 和对应方向数据.

    if nargin < 2
        direction = 'XYZ';
    end

    %% 读取文件所有行，判断头部信息行数
    fid = fopen(filepath, 'r');
    if fid == -1
        error('无法打开文件：%s', filepath);
    end
    lines = {};
    while ~feof(fid)
        line = fgetl(fid);
        lines{end+1,1} = line;
    end
    fclose(fid);

    headerLines = 0;
    for i = 1:length(lines)
        strLine = strtrim(lines{i});
        if isempty(strLine)
            headerLines = headerLines + 1;
            continue;
        end
        % 尝试将当前行转换为数值
        nums = str2num(strLine); %#ok<ST2NM>
        if ~isempty(nums)
            break;
        else
            headerLines = headerLines + 1;
        end
    end

    %% 利用 detectImportOptions 和 readmatrix 解析数据（跳过头部非数值行）
    opts = detectImportOptions(filepath, 'NumHeaderLines', headerLines, 'Delimiter', ',');
    data = readmatrix(filepath, opts);
    
    % 假设 data 的各列分别为:
    % 列1: X, 列2: Y, 列3: Z, 列4: 向量和, 列5: 时间戳（毫秒）, 列6: 时间戳序号
    
    % 将时间戳转换为相对秒数（以第一个时间戳为0秒）
    timeSec = (data(:,5) - data(1,5)) / 1000;
    
    %% 根据 direction 提取对应的数据并构造 table
    switch upper(direction)
        case 'X'
            dataMatrix = table(timeSec, data(:,1), 'VariableNames', {'Time', 'X'});
        case 'Y'
            dataMatrix = table(timeSec, data(:,2), 'VariableNames', {'Time', 'Y'});
        case 'Z'
            dataMatrix = table(timeSec, data(:,3), 'VariableNames', {'Time', 'Z'});
        case 'XYZ'
            dataMatrix = table(timeSec, data(:,1), data(:,2), data(:,3), ...
                'VariableNames', {'Time', 'X', 'Y', 'Z'});
        otherwise
            error('不支持的方向参数：%s。请使用 ''X''、''Y''、''Z'' 或 ''XYZ''。', direction);
    end

end
