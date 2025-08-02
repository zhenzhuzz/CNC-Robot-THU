# CNC-Robot-THU
Robotic Machining System @Tsinghua: Custom ABB IRB6700 (2.6m reach, 200kg load, avg. 0.29mm accuracy), high-speed spindle, Siemens PLC, RealSense depth camera, CHOTEST auto-probing, vision-based tool setting. Developing AI-powered CAM, C++ ROS integration, and KUKA KR-60 collaboration.


清华大学深圳国际研究生院LIMES实验室机器人加工系统 | Robotic Machining System from Tsinghua SIGS LIMES

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

**ChatGPT:**

以下是根据你的需求更新的仓库结构说明部分，已包含重要文件的链接、关键注释和预留图片位置：

* * *

🚩 仓库结构说明
---------

### 📂 [`Codes/`](Codes/)

* **[`Robotic_Milling_Necessities`](Codes/Robotic_Milling_Necessities)**：  
    机器人加工相关控制程序及铣削实验数据分析代码。  
    **最重要程序**：**`[m058_UpdateOnce_accXYZ_ABBcontrol_NI_Spindle_TCPIP_GUI_04.m](Codes/Robotic_Milling_Necessities/EXP04_机器人加工系统上位机控制程序_m058_UpdateOnce是最终版_20250407/m058_UpdateOnce_accXYZ_ABBcontrol_NI_Spindle_TCPIP_GUI_04.m)`**
    
    > 📌 本程序是首个**基于MATLAB调用ABB PC SDK的机器人二次开发控制界面**（传统方案通常使用C#）。  
    > 当前版本成功实现机器人（ABB IRB6700 200/2.6）上下电、指针复位、运行例行程序及启停控制，经真机测试运行稳定可靠。  
    > 经测试发现ABB PC SDK扩展其他功能（如读写变量、编程等）后界面存在明显卡顿，推测为ABB SDK本身性能瓶颈所致，故建议其余复杂任务在RobotStudio内完成。
    
    <!-- 图片占位，软件运行颤振时截图 -->
    
    其他文件夹（如`EXP01`~`EXP09`及`EXPpre`系列）为机器人铣削实验及数据分析代码，非机器人加工方向研究者可忽略。
    
* **`ROS_Vision`**：  
    ROS与视觉系统相关程序（由其他贡献者管理）。
    

* * *

### 📂 [`Docs/`](Docs/)

* **机器人加工系统颤振监测与抑制技术研究（毕业论文）**  
    工业机器人刚度不足导致铣削易发生颤振，影响加工质量与稳定性。本文建立机器人铣削的动力学模型，通过稳定性叶瓣图指导颤振监测与抑制策略设计；  
    研发了基于FFT频谱分析和频域陷波滤波的颤振实时监测方法，并提出自适应变主轴转速主动抑制策略，实验表明颤振检测延迟低于100 ms，主动抑制策略150 ms内生效，有效降低振幅超过80%，提升加工稳定性和零件质量。  
    实验结果表明，该方法将加工效率提升超过30%，工件表面质量提高约60%，刀具寿命显著延长。
    

* * *

### 📂 [`Media/`](Media/)

* 项目相关图片、视频和展示GIF文件，用于项目说明与演示。
    



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
