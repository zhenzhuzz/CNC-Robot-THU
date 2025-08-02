function f034_exist_legend_05(lgd, legendLocation, legendOrientation, FontName)
    % 修改现有图例
    % 输入参数：
    % lgd: 图例句柄
    % legendLocation: 图例的位置，字符串形式，如 'northeast' (默认值为 'northeast')
    % legendOrientation: 图例的方向，字符串形式，如 'horizontal' 或 'vertical' (默认值为 'vertical')
    % FontName: 图例的字体名称，如 'Times New Roman' (默认值为 'Times New Roman')

    % 参数定义和默认值
    arguments
        lgd % 图例句柄，必须传入
        legendLocation (1,:) char = 'northeast'  % 默认位置为 'northeast'
        legendOrientation (1,:) char = 'vertical'  % 默认方向为 'vertical'
        FontName (1,:) char = 'Times New Roman'  % 默认字体为 'Times New Roman'
    end

    % 检查传入的图例句柄是否有效
    if ishandle(lgd)
        % 修改图例的属性
        set(lgd, 'Location', legendLocation, 'Orientation', legendOrientation, ...
            'FontSize', 10.5, 'FontName', FontName);
        lgd.ItemTokenSize = [12, 12];  % 修改现有图例的 ItemTokenSize
    else
        % 如果句柄无效，给出提示
        warning('提供的图例句柄无效。');
    end
end
