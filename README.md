# CNC-Robot-THU
Robotic Machining System @Tsinghua: Custom ABB IRB6700 (2.6m reach, 200kg load, avg. 0.29mm accuracy), high-speed spindle, Siemens PLC, RealSense depth camera, CHOTEST auto-probing, vision-based tool setting. Developing AI-powered CAM, C++ ROS integration, and KUKA KR-60 collaboration.

✨ 项目简介
------
清华大学深圳国际研究生院 LIMES 实验室机器人加工系统 | Robotic Machining System from Tsinghua SIGS LIMES  

本项目围绕**机器人加工系统**的搭建与控制展开，基于ABB IRB6700机器人（2.6m臂展，200kg负载，平均绝对精度0.29 mm），集成西门子PLC、高速电主轴、RealSense视觉系统、CHOTEST自动测量探头，并融合了ROS生态、视觉识别、加工颤振在线监测与自适应变主轴转速抑制技术。


* * *


> 📌 **机器人加工系统功能演示**：

<!-- 直接在README页面内展示的GIF动图 -->
![Robotic Milling System Demo](Media/gif11_机器人加工系统功能展示_20250516.gif)

<!-- 外部链接，用户点击可跳转观看完整分辨率视频 -->
🎬 [Full Resolution Video](https://drive.google.com/file/d/1IW6d7zLTxaNsqKViqW-QUM10UKJw6B21/view)



* * *



🚩 仓库结构说明
---------

### 📂 [`Codes/`](Codes/)

* **[`Robotic_Milling_Necessities`](Codes/Robotic_Milling_Necessities)**：  
机器人加工相关控制程序及铣削实验数据分析代码。

1、基于MATLAB R2023a的机器人上位机控制软件，最重要程序为：[**`m058_UpdateOnce_accXYZ_ABBcontrol_NI_Spindle_TCPIP_GUI_04.m`**](Codes/Robotic_Milling_Necessities/EXP04_机器人加工系统上位机控制程序_m058_UpdateOnce是最终版_20250407/m058_UpdateOnce_accXYZ_ABBcontrol_NI_Spindle_TCPIP_GUI_04.m)，位于[`EXP04`文件夹](Codes/Robotic_Milling_Necessities/EXP04_机器人加工系统上位机控制程序_m058_UpdateOnce是最终版_20250407)中，另需以下三个函数置于同一目录：
- [`f020_read_timeStamps_accX_spinSpeed_from_txt_04.m`](Codes/Robotic_Milling_Necessities/EXP04_机器人加工系统上位机控制程序_m058_UpdateOnce是最终版_20250407/f020_read_timeStamps_accX_spinSpeed_from_txt_04.m)
- [`f060_Decision_fft_filter_report.m`](Codes/Robotic_Milling_Necessities/EXP04_机器人加工系统上位机控制程序_m058_UpdateOnce是最终版_20250407/f060_Decision_fft_filter_report.m)
- [`f070_NewSpinSpeed_04.m`](Codes/Robotic_Milling_Necessities/EXP04_机器人加工系统上位机控制程序_m058_UpdateOnce是最终版_20250407/f070_NewSpinSpeed_04.m)

> 📌 本程序是首个**基于MATLAB调用ABB PC SDK的机器人二次开发控制界面**（传统方案通常使用C#）。  
> 当前版本成功实现机器人（ABB IRB6700 200/2.6）上下电、指针复位、运行例行程序及启停控制，经真机测试运行稳定可靠。  
> 经测试发现加入ABB PC SDK其他功能（如读写变量、编程等）后界面存在明显卡顿，推测为ABB SDK本身性能瓶颈所致，建议编程、变量修改等复杂任务在RobotStudio内完成。

<!-- 软件运行颤振时截图（软件界面） -->
<!-- <img src="Media/基于MATLAB的机器人上位机控制界面.png" width="700" alt="机器人上位机控制界面"> -->

![基于MATLAB的机器人上位机控制界面](Media/基于MATLAB的机器人上位机控制界面.png)

其他文件夹（如`EXP01`~`EXP09`及`EXPpre`系列）为机器人铣削实验及数据分析代码，非机器人加工方向研究者可忽略。

2、基于C#的机器人上位机控制软件位于[`ABB_CSharp上位机_优化卡顿_取消监听_20250318`](Codes/Robotic_Milling_Necessities/PLC_CSharp上位机_20250113/ABB_CSharp上位机_优化卡顿_取消监听_20250318)文件夹，下载整个文件夹，用Visual Studio打开[`ABB_1230.sln`](Codes/Robotic_Milling_Necessities/PLC_CSharp上位机_20250113/ABB_CSharp上位机_优化卡顿_取消监听_20250318/20250114/ABB_12301/ABB_1230.sln)即可运行（实际运行容易卡顿或出现bug）。

3、整套机器人加工系统的核心PLC程序位于[`4_20250114_还差机器人转速设置`](Codes/Robotic_Milling_Necessities/PLC_CSharp上位机_20250113/4_20250114_还差机器人转速设置)文件夹内：[**`THU_LIMES_RoboticMillingSystem_Finish_20250113_V18.ap18`**](Codes/Robotic_Milling_Necessities/PLC_CSharp上位机_20250113/4_20250114_还差机器人转速设置/THU_LIMES_RoboticMillingSystem_Finish_20250114_V18/THU_LIMES_RoboticMillingSystem_Finish_20250113_V18.ap18)。使用西门子TIA博途V18版本，功能包括：主轴转速监测、主轴启停与转速控制信号发送、气动系统控制（拉刀、换刀、气密、中心吹尘）及加工状态三色灯控制等。

* **[`ROS_Vision`](Codes/ROS_Vision)**：  
ROS与视觉系统相关程序（由吴珩管理）。

---

### 📂 [`Docs/`](Docs/)

* **[机器人加工系统颤振监测与抑制技术研究（朱镇硕士学位论文）](Docs/11_毕业论文pdf_2022214656-朱镇-机器人加工系统颤振监测与抑制技术研究_20250517.pdf)**  
工业机器人刚度不足导致铣削易发生颤振，影响加工质量与稳定性。本文建立机器人铣削的动力学模型，通过稳定性叶瓣图指导颤振监测与抑制策略设计；研发了基于FFT频谱分析和频域陷波滤波的颤振实时监测方法，并提出自适应变主轴转速主动抑制策略。实验表明颤振检测延迟低于100 ms，主动抑制策略150 ms内生效，有效降低振幅超过80%，显著提升加工稳定性和零件质量。  
实验结果表明，该方法将加工效率提升超过30%，工件表面质量提高约60%，刀具寿命显著延长。

---

### 📂 [`Media/`](Media/)

* 项目相关图片、视频和展示GIF文件，用于项目说明与演示。

---

### 📊 机器人加工系统模块组件介绍

#### 加工模块

| 模块         | 组件              | 品牌型号                    | 规格参数                                |
|--------------|-------------------|-----------------------------|-----------------------------------------|
| 加工模块     | 高速电主轴        | 广州昊志 DGZYX-12030/11A3-KFPWVS | 最高转速 30,000 rpm，自重 31.5 kg       |
|              | 主轴安装座        | 定制                         | 自重 20.5 kg                            |
|              | 刀柄              | 台湾广捷热缩刀柄             | HSK-40E                                 |
|              | 刀具              | 狮王铝用铣刀                 | Φ8-L60-C20-T3                           |
|              | 气路系统          | 亚德客电磁阀、减压阀、压力表、气管、转接头 | -                                       |
|              | 主轴冷却系统      | 江西瑞科主轴水冷箱           | 稳定主轴22℃运行                        |
|              | 工业机器人        | ABB IRB6700 200/2.6          | 绝对精度 0.3 mm，负载 200 kg，自重 1.2 吨，臂展 2.6 m |
|              | 工作台            | 定制铸铁工作台               | 尺寸 1500×1000×840 mm，自重 1 吨        |

#### 控制模块

| 模块         | 组件              | 品牌型号                    | 规格参数                                |
|--------------|-------------------|-----------------------------|-----------------------------------------|
| 控制模块     | 变频器            | 上海启变电气永磁同步系列     | 15 kW，0-500 Hz 调频                    |
|              | PLC               | 西门子 S7-1200              | CPU 1214C DC/DC/DC                      |
|              | 交换机            | 火也                         | 千兆 10 口                              |
|              | 机器人控制柜      | ABB IRC5 标准柜             | -                                       |
|              | 示教器            | ABB IRC5 示教器             | -                                       |
|              | 工控机            | 联想办公主机                | CPU i5-10400                            |

#### 软件模块

| 模块         | 组件               | 品牌型号             | 规格参数                                     |
|--------------|--------------------|----------------------|----------------------------------------------|
| 软件模块     | 自动化机加软件     | 基于C#，ABB PC SDK    | 机器人运动控制、主轴启停及转速控制           |
|              | 颤振监测与自适应主轴调速软件 | 基于MATLAB          | 主轴启停及转速控制，加速度计同步采集         |

#### 测量模块

| 模块         | 组件              | 品牌型号               | 规格参数                                  |
|--------------|-------------------|------------------------|-------------------------------------------|
| 测量模块     | 数据采集卡        | NI 9234                | 4通道，51.2 kS/s/ch，±5 V输出，C系列声音与振动输入模块 |
|              | 采集卡机箱        | NI cDAQ 9171           | 单槽，USB 2.0连接                         |
|              | 加速度传感器      | PCB 356A24             | 三轴，灵敏度10 mV/g，响应频率1-9k Hz，测量范围±500 g pk (±4905 m/s² pk) |
|              | 红外触发测头      | 中图仪器PO40与COMI接收器 | 单向重复精度<1 μm                         |

---

### 📷 机器人加工系统软硬件组成

<!-- 图片占位，软硬件组成 -->
![机器人加工系统软硬件组成](Media/机器人加工系统软硬件组成.png)

---


* * *


🛠️ 核心技术亮点
----------

- **机器人视觉辅助**：RealSense视觉系统自动识别工件位置；
- **自动标定系统**：CHOTEST探头自动建系与视觉对刀；
- **颤振在线监测与主动抑制**：基于FFT频谱分析的实时监测及变主轴转速自适应控制；
- **ROS生态融合**：基于C++开发ROS接口；
- **前沿探索**：AI驱动的CAM路径规划与加工特征识别（开发中）。
  

* * *

🚀 项目维护者
--------

[朱镇 (Zhen Zhu)](https://zhenzhuzz.github.io), 吴珩 (Heng Wu)  <br>
from [清华大学 深圳国际研究生院 LIMES 实验室](http://www.thume.impmlab.com/)

