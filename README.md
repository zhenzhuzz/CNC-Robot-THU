# CNC-Robot-THU
Robotic Machining System @Tsinghua: Custom ABB IRB6700 (2.6m reach, 200kg load, avg. 0.29mm accuracy), high-speed spindle, Siemens PLC, RealSense depth camera, CHOTEST auto-probing, vision-based tool setting. Developing AI-powered CAM, C++ ROS integration, and KUKA KR-60 collaboration.


清华大学LIMES实验室机器人加工系统 | Robotic Machining System @Tsinghua

> 📌 **机器人加工系统功能演示**：

<!-- 直接在README页面内展示的GIF动图 -->
![Robotic Milling System Demo](Media/gif11_机器人加工系统功能展示_20250516.gif)

<!-- 外部链接，用户点击可跳转观看完整分辨率视频 -->
🎬 [Full Resolution Video](https://drive.google.com/file/d/1IW6d7zLTxaNsqKViqW-QUM10UKJw6B21/view)



* * *

✨ 项目简介
------

本项目围绕**机器人加工系统**的搭建与控制展开，基于ABB IRB6700机器人（2.6m臂展，200kg负载），集成西门子PLC、Realsense视觉系统、CHOTEST自动测量探头，并融合了ROS生态、视觉识别、加工颤振监测与抑制技术。

* * *

🚩 仓库结构说明
---------

* [`PPT/`](PPT/)：  
    机器人系统**从零到一搭建过程ppt**及毕业答辩材料。
    
* `Thesis/`：  
    **毕业论文**：机器人加工系统颤振监测与抑制技术研究。
    
* `Figures/`：  
    项目相关**图片与制图源文件**，如：机器人展示图，正文用图。
    
* [`Code/`](Code/)：  
    机器人加工实验控制代码（以`EXP`开头），如：机器人运动控制，自动标定程序。
    
* [`PLC/`](PLC/)：  
    PLC上位机程序（供应商提供，请勿擅动）。
    
* `Docs/`：  
    机器人采购、招标与供应商文件。
    
* `Videos/`：  
    机器人功能演示视频，如：加工演示视频。
    

* * *

🚨 使用注意
-------

PLC控制程序为供应商工程师编写，请勿擅自修改，否则易致设备运行异常。如有需求，请与PLC开发工程师联系。

* * *

📌 推荐访问顺序
---------

依次建议：

1. 浏览`搭建经历ppt`了解项目整体脉络；
   
2. 参阅`毕业论文pdf`深入理解研究背景、理论与方法；
   
3. 查看`Figures`与`Videos`直观感受系统实操过程；
   
4. 根据需求查阅[`Code`](Code/)内的实验代码。
   

* * *

🛠️ 核心技术亮点
----------

* **机器人视觉辅助**：RealSense相机自动识别初始工件位置；
  
* **自动标定系统**：CHOTEST探头自动建系与视觉对刀；
  
* **先进加工技术**：颤振监测与主动抑制技术（论文内详述）；
  
* **生态融合**：基于C++开发ROS接口，融入ROS生态；
  
* **前沿探索**：未来AI驱动的CAM加工路径规划与特征识别（开发中）。
  

* * *

🚀 项目维护者
--------

[朱镇（Zhen Zhu）](https://zhenzhuzz.github.io), 吴珩（Heng Wu）
Tsinghua University
