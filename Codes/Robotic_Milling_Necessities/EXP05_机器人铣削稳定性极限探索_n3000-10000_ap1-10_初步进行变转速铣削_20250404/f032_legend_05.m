function f032_legend_05(ax, varargin)
    % f031_legend_05 设置图例
    % f031_legend_05 Set legend for the axis
    %
    % 参数说明：
    %   ax             : 坐标轴句柄 (必选) 
    %                   Axis handle (required)
    %   其余参数使用name-value对 (可选)，例如：
    %                   'legendTexts'    : 图例文本 (cell 数组)
    %                   'legendLocation' : 图例位置 (默认 'northeast')
    %                   'legendOrientation' : 图例方向 (默认 'vertical')
    %                   'FontName'       : 字体名称 (默认 'Times New Roman')
    % 调用示例 Example usage：
    %   f031_legend_05(gca, 'legendTexts', {'A', 'B'}, 'legendLocation', 'northwest', 'legendOrientation', 'horizontal', 'FontName', 'Arial');
    %   f031_legend_05(gca, {'A', 'B'}, 'northwest', 'horizontal', 'Arial');
    
    % 创建输入解析器
    p = inputParser;
    
    % 设置默认值
    p.addParameter('legendTexts', {}, @(x) iscell(x));  % Default to empty cell array
    p.addParameter('legendLocation', 'northeast', @(x) ischar(x));  % Default to 'northeast'
    p.addParameter('legendOrientation', 'vertical', @(x) ischar(x));  % Default to 'vertical'
    p.addParameter('FontName', 'Times New Roman', @(x) ischar(x));  % Default to 'Times New Roman'
    
    % 判断输入参数的数量
    if nargin > 1 && iscell(varargin{1})  % 顺序输入
        % 用户传入的是图例文本（顺序输入）
        legendTexts = varargin{1};
        % 将剩余的参数传给 inputParser 解析
        p.parse(varargin{2:end});
    else  % 使用name-value pair方式
        p.parse(varargin{:});
        legendTexts = p.Results.legendTexts;  % 从解析器获取 legendTexts
    end
    
    % 获取解析后的参数值
    legendLocation = p.Results.legendLocation;
    legendOrientation = p.Results.legendOrientation;
    FontName = p.Results.FontName;
    
    % 如果 legendTexts 不为空，则创建图例
    if ~isempty(legendTexts)
        lgd = legend(ax, legendTexts, 'Location', legendLocation, ...
            'Orientation', legendOrientation, 'FontSize', 10.5, 'FontName', FontName);
        lgd.ItemTokenSize = [12, 12];
    end
end
