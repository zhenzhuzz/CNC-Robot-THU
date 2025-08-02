function f030_optimizeFig_Paper_01(ax, xLabelText, yLabelText, titleText, legendTexts, legendLocation, tickLength)
    % f030_optimizeFig_Paper_01 优化论文绘图 (无自动轴范围设置)
    %
    % 参数说明：
    %   ax             : 坐标轴句柄 (必选)
    %   xLabelText     : x轴标签文本 (必选)
    %   yLabelText     : y轴标签文本 (必选)
    %   titleText      : 标题文本 (可选，不用传 '')
    %   legendTexts    : 图例文本 (cell 数组，可选，不用传 {})
    %   legendLocation : 图例位置 (可选，默认 'northeast')
    %   tickLength     : 刻度线长度向量（例如 [0.01, 0.01]） (可选)
    %
    % 示例调用：
    %   f030_optimizeFig_Paper_01(gca, '时间(s)', '加速度(g)', '标题', {'A','B'}, 'northwest', [0.01, 0.01]);

    arguments
        ax
        xLabelText (1,:) char
        yLabelText (1,:) char
        titleText (1,:) char = ''
        legendTexts cell = {}
        legendLocation (1,:) char = 'northeast'
        tickLength (1,2) double = [0.01, 0.01]
    end

    %【1】美化坐标轴字体、线宽和网格
    set(ax, 'FontSize', 10.5, 'FontName', 'Times New Roman', 'LineWidth', 1, ...
        'Box', 'off', 'TickDir', 'in', 'TickLength', tickLength);
    grid(ax, 'on');

    %【2】设置坐标轴标签
    xlabel(ax, xLabelText, 'FontSize', 10.5, 'FontName', 'Times New Roman');
    ylabel(ax, yLabelText, 'FontSize', 10.5, 'FontName', 'Times New Roman');

    %【3】设置标题（若存在）
    if ~isempty(titleText)
        title(ax, titleText, 'FontSize', 11, 'FontName', 'Times New Roman');
    end

    %【4】设置图例（若存在）
    if ~isempty(legendTexts)
        lgd = legend(ax, legendTexts, 'Location', legendLocation, ...
            'FontSize', 9.5, 'FontName', 'Times New Roman');
        lgd.ItemTokenSize = [12, 12];
    end

    %【5】背景颜色设置为白色
    set(ax.Parent, 'Color', 'w');

    %【6】绘制外框线（不加入图例）
    xl = xlim(ax);
    yl = ylim(ax);
    hold(ax, 'on');
    plot(ax, [xl(1), xl(2), xl(2), xl(1), xl(1)], [yl(1), yl(1), yl(2), yl(2), yl(1)], ...
        'k-', 'LineWidth', 1, 'HandleVisibility', 'off');
    hold(ax, 'off');
end
