# ABB PC SDK安装

- **下载链接**：[https://developercenter.robotstudio.com/](https://developercenter.robotstudio.com/)
- 下载完成后默认会放置在 `C:\Program Files (x86)\ABB\SDK\PCSDK 2025\` 文件夹下，请检查。如果不是的话，后续在 Matlab 程序中需要修改动态库文件加载路径。
- 安装完成！

# Matlab程序使用

- 将 `m057_adjust_elements_postion_04.m`、`f060_Decision_fft_filter_report.m`、`f001_fourier_04.m` 这三个文件放置在 Matlab 的工作路径下。
- 将代码第 17 行，加载动态库下的动态库路径改为正确路径。
- 打开 `m057_adjust_elements_postion_04.m` 并运行，应该能看到控制界面弹出，程序运行成功！

# 附

- **ABB PC SDK官方使用说明**：[https://developercenter.robotstudio.com/api/pcsdk/](https://developercenter.robotstudio.com/api/pcsdk/)