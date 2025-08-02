function f033_colorbar_05(cbar, title_str, font_size, font_name, line_width)
    % 设置 colorbar 的属性
    % cbar         : colorbar 句柄
    % title_str    : colorbar 标题字符串
    % font_size    : 字体大小
    % font_name    : 字体名称
    % line_width   : 线条宽度

    % 设置 colorbar 标题
    cbar.Title.String = title_str;     % 设置 colorbar 标题
    cbar.Title.FontSize = font_size;   % 设置标题字体大小
    cbar.Title.FontName = font_name;   % 设置标题字体

    % 设置 colorbar 本身的字体和线条宽度
    cbar.FontSize = font_size;         % 设置字体大小
    cbar.FontName = font_name;         % 设置字体
    cbar.LineWidth = line_width;       % 设置线条宽度
end
