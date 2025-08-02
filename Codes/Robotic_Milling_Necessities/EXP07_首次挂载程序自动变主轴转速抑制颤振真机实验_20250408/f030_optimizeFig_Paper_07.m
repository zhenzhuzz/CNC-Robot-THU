function f030_optimizeFig_Paper_07(ax, xLabelText, yLabelText, titleText, xLim, yLim, tickLength)
    % f030_optimizeFig_Paper_05 Optimizes figure appearance for papers (without automatic axis range adjustment)
    % f030_optimizeFig_Paper_05 优化论文绘图 (无自动轴范围设置)
    %
    % 参数说明：
    %   ax             : 坐标轴句柄 (必选) 
    %                   Axis handle (required)
    %   xLabelText     : x轴标签文本 (必选) 
    %                   x-axis label text (required)
    %   yLabelText     : y轴标签文本 (必选) 
    %                   y-axis label text (required)
    %   titleText      : 标题文本 (可选，不用传 '') 
    %                   Title text (optional, leave empty for no title)
    %                   传空：'' (空字符串表示不传标题)
    %   xLim           : x轴范围 (可选, 默认为 'tight') 
    %                   x-axis limits (optional, default is 'tight')
    %                   传空：[] (默认值，表示自动设置范围)
    %   yLim           : y轴范围 (可选, 默认为 'tight') 
    %                   y-axis limits (optional, default is 'tight')
    %                   传空：[] (默认值，表示自动设置范围)
    %   tickLength     : 刻度线长度向量（例如 [0.01, 0.01]） (可选)
    %                   Tick length vector (e.g., [0.01, 0.01]) (optional, default is [0.01, 0.01])
    %                   传空：[] (默认值)
    % 调用示例 Example usage：
    %   f030_optimizeFig_Paper_05(gca, 'Time (s)', 'Acceleration (g)', 'My Title', [0.01, 0.01], [0, 10], [-5, 5]);

    arguments
        ax
        xLabelText (1,:) char
        yLabelText (1,:) char
        titleText (1,:) char = ''
        xLim = []
        yLim = []
        tickLength (1,2) double = [0.01, 0.01]
    end

    %【1】美化坐标轴字体、线宽和网格
    %【1】Enhance axis font, line width, and grid
    set(ax, 'FontSize', 10.5, 'FontName', 'Times New Roman', 'LineWidth', 1, ...
        'Box', 'off', 'TickDir', 'in', 'TickLength', tickLength);
    grid(ax, 'on');

    %【2】设置坐标轴标签
    %【2】Set axis labels
    xlabel(ax, xLabelText, 'FontSize', 10.5, 'FontName', 'Times New Roman');
    ylabel(ax, yLabelText, 'FontSize', 10.5, 'FontName', 'Times New Roman');

    %【3】设置标题（若存在）
    %【3】Set title (if provided)
    if ~isempty(titleText)
        title(ax, titleText, 'FontSize', 11, 'FontName', 'Times New Roman');
    end

    %【4】背景颜色设置为白色
    %【4】Set background color to white
    set(ax.Parent, 'Color', 'w');

    %【5】自动调整坐标轴范围
    %【5】Automatically adjust axis limits
    if ~isempty(xLim)
        xlim(ax, xLim);  % User-specified x-axis limits
    else
        xlim(ax, 'auto');  % Default to tight limits
    end

    if ~isempty(yLim)
        ylim(ax, yLim);  % User-specified y-axis limits
    else
        ylim(ax, 'auto');  % Default to tight limits
    end

    %【6】绘制外框线（不加入图例）
    %【6】Draw outer frame (not included in the legend)
    xl = xlim(ax);
    yl = ylim(ax);
    hold(ax, 'on');
    plot(ax, [xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], ...
        'k-', 'LineWidth', 1, 'HandleVisibility', 'off');
    hold(ax, 'off');
end
