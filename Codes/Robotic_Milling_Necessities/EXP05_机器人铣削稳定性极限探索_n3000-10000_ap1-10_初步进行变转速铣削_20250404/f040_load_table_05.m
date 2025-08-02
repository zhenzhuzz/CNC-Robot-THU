function dataSheet = f040_load_table_05(tableName)
    % Function to load the specified .mat file and the corresponding table data
    % 函数用于加载指定的 .mat 文件及相应的表格数据

    % Check if tableName is provided, otherwise throw an error
    % 检查是否提供了 tableName 参数，如果没有则抛出错误
    if nargin < 1
        error('tableName must be provided'); % Error message if tableName is missing / 如果没有提供 tableName，则抛出错误
    end
    
    % Define the current directory and construct the file path
    % 定义当前目录并构建文件路径
    basePath = pwd; % Current directory / 当前目录
    filePath = fullfile(basePath, [tableName '.mat']); % Construct the file path / 构建文件路径

    % Check if the .mat file exists
    % 检查 .mat 文件是否存在
    if exist(filePath, 'file') ~= 2
        error('The specified .mat file does not exist'); % Error message if file doesn't exist / 如果文件不存在，则抛出错误
    end
    
    % Load the data
    % 加载数据
    load(filePath, tableName); % Load the .mat file containing the table / 加载包含表格的 .mat 文件
    dataSheet = eval(tableName); % Extract the table data using eval / 使用 eval 提取表格数据
    
    % Save the table to the global workspace
    % 将表格保存到全局工作区
    assignin('base', tableName, dataSheet); % Assign the table to the base workspace / 将表格赋值到基础工作区
    
    % Optionally, display the loaded data if needed
    % 可选地，如果需要显示加载的数据
    disp('Table loaded successfully:');
end
