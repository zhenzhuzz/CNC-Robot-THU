using ABB.Robotics.Controllers;
using ABB.Robotics.Controllers.ConfigurationDomain;
using ABB.Robotics.Controllers.Discovery;
using ABB.Robotics.Controllers.EventLogDomain;
using ABB.Robotics.Controllers.IOSystemDomain;
using ABB.Robotics.Controllers.Messaging;
using ABB.Robotics.Controllers.MotionDomain;
using ABB.Robotics.Controllers.RapidDomain;
using ABB_二次开发1230;
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.IO.Ports;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Test_Controll;
using 串口助手;
using ClosedXML.Excel;
using System.Data.OleDb;
using System.Data;
using Modbus.Device;
using Modbus.Data;
using HslCommunication.Controls;
using System.Drawing.Printing;
using CyRobotics;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Drawing.Charts;
using ABB.Robotics.Controllers.FileSystemDomain;

namespace ABB_1230
{
    public partial class Form1 : Form
    {
        private NetworkScanner scanner = null;
        public Controller controller = null;
        public RobotToolManager toolManager = null;
        System.Windows.Forms.Timer speedRecvTimer = null;
        //        timer.Tick += new EventHandler(timer1_Tick);
        //        timer.Interval = 1000; // 设置时间间隔为1000毫秒
        //timer.Enabled = true; // 启用定时器
        //timer.Start(); // 开始定时器
        private ABB.Robotics.Controllers.RapidDomain.Task[] tasks = null;
        private NetworkWatcher networkWatcher = null;
        private ControllerOperatingMode Change_Mode = ControllerOperatingMode.Auto;
        private ExecutionMode execution = ABB.Robotics.Controllers.RapidDomain.ExecutionMode.Continuous;
        private ExecutionCycle cycle = ExecutionCycle.Once;
        public bool register;  //登录成功TRUE  登录失败flag
        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "WindowFromPoint")]
        static extern IntPtr WindowFromPoint(Point pt);

        private float x;//定义当前窗体的宽度
        private float y;//定义当前窗体的高度
        public Form1()
        {
            InitializeComponent();
            x = this.Width;
            y = this.Height;
            setTag(this);
            //  Control.CheckForIllegalCrossThreadCalls = false;
            this.numericUpDown1.KeyDown += new KeyEventHandler(numericUpDown1_KeyDown);
        }
        private void setTag(Control cons)
        {
            foreach (Control con in cons.Controls)
            {
                con.Tag = con.Width + ";" + con.Height + ";" + con.Left + ";" + con.Top + ";" + con.Font.Size;
                if (con.Controls.Count > 0)
                {
                    setTag(con);
                }
            }
        }
        private void setControls(float newx, float newy, Control cons)
        {
            try
            {
                //遍历窗体中的控件，重新设置控件的值
                foreach (Control con in cons.Controls)
                {
                    //获取控件的Tag属性值，并分割后存储字符串数组
                    if (con.Tag != null)
                    {
                        string[] mytag = con.Tag.ToString().Split(new char[] { ';' });
                        //根据窗体缩放的比例确定控件的值
                        con.Width = Convert.ToInt32(System.Convert.ToSingle(mytag[0]) * newx);//宽度
                        con.Height = Convert.ToInt32(System.Convert.ToSingle(mytag[1]) * newy);//高度
                        con.Left = Convert.ToInt32(System.Convert.ToSingle(mytag[2]) * newx);//左边距
                        con.Top = Convert.ToInt32(System.Convert.ToSingle(mytag[3]) * newy);//顶边距
                        Single currentSize = System.Convert.ToSingle(mytag[4]) * newy;//字体大小
                        con.Font = new Font(con.Font.Name, currentSize, con.Font.Style, con.Font.Unit);
                        if (con.Controls.Count > 0)
                        {
                            setControls(newx, newy, con);
                        }
                    }
                }
            }
            catch
            {
                MessageBox.Show("电脑分辨率不正确");
            }
        }
        public float FromHeight;
        public float FormWidth;

        private void Form1_Resize(object sender, EventArgs e)
        {

            float newx = (this.Width) / x;
            float newy = (this.Height) / y;
            setControls(newx, newy, this);
        }

        private int controllerCount = 0;
        private string getSystemId = "";
        bool isVirtual;
        string getfilepath = "";
        //protected override CreateParams CreateParams
        //{
        //    get
        //    {
        //        CreateParams cp = base.CreateParams;
        //        cp.ExStyle |= 0x02000000;
        //        return cp;
        //    }
        //}
        RapidSymbol[] rapids = null;
        private void listView1_DoubleClick(object sender, EventArgs e)
        {
            try
            {
                if (this.listView1.Items.Count > 0)
                {
                    ListViewItem item = this.listView1.Items[listView1.SelectedIndices[0]];
                    for (int i = 0; i < controllerCount; i++)
                    {
                        listView1.Items[i].BackColor = Color.Transparent;   //系统颜色
                    }
                    listView1.Items[listView1.SelectedIndices[0]].BackColor = Color.GreenYellow;        //浅蓝

                    if (item.Tag != null)
                    {
                        ControllerInfo info = (ControllerInfo)item.Tag;
                        getSystemId = info.SystemId.ToString();
                        isVirtual = info.IsVirtual;
                        if (info.Availability == Availability.Available)
                        {
                            if (controller != null)
                            {
                                controller.Logoff();
                                controller.Dispose();
                                controller = null;
                                // 如果controller不为null，登出并Dispose;
                            }

                            controller = ControllerFactory.CreateFrom(info); //null那就是报错
                            controller.Logon(UserInfo.DefaultUser);
                            this.controller.ConnectionChanged += new EventHandler<ConnectionChangedEventArgs>(ConnectionChanged);
                            GetRouiine();  //设置指针
                            SuBscribe(); //控制器当前状态
                            subscribe();  //TPWrite写屏
                                          //TPsubscribe(); //TpNum写屏
                            sbBscribelog();  //日志事件          
                            ABBmessage();
                            // timer3.Start();
                            GetPos_timer.Start();  //实时获取大地坐标工件坐标
                            //使用默认用户名登录
                            register = true;

                            getspeedandtorque = 2; //获取扭矩
                            getCount = 6;   //所有轴
                            GetspeedTorque();  //获取实时扭矩和速度
                            ao_speed(); //获取实时TCP
                            getfilepath = System.Environment.CurrentDirectory;  //获取安装路径
                            //MessageBox.Show("已控制控制器" + info.SystemName);  //弹框提示登录成功
                            W.ABBmessage(message_lbo, "已控制控制器" + info.SystemName); //弹框提示登录成功
                            rapids = W.rapidSymbol(controller, string.Empty);
                            ShowRapid_Click(null, null);
                            button4_Click(null, null);
                            // timer2.Start();

                            userCurve1.SetLeftCurve(str[0], new float[] { }, Color.Tomato);
                            userCurve1.SetLeftCurve(str[1], new float[] { }, Color.DarkOrchid);
                            userCurve1.SetLeftCurve(str[2], new float[] { }, Color.DodgerBlue);
                            userCurve1.SetLeftCurve(str[3], new float[] { }, Color.Black);
                            userCurve1.SetLeftCurve(str[4], new float[] { }, Color.Green);
                            userCurve1.SetLeftCurve(str[5], new float[] { }, Color.GreenYellow);
                            num = new Num[6];
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }
        string[] str = new string[] { "A", "B", "C", "D", "E", "F", "G" };
        Num[] num;
        private void ConnectionChanged(object sender, ConnectionChangedEventArgs e)
        {

            timer.Stop();
            GetPos_timer.Stop();
            controller = null;
            if (scanner == null)
            {
                scanner = new NetworkScanner();
            }
            scanner.Scan(); //对网络进行扫描
            this.listView1.Items.Clear();   //清空listView1中的内容
            ControllerInfoCollection controls = scanner.Controllers;
            foreach (ControllerInfo info in controls)
            {
                ListViewItem item = new ListViewItem(info.SystemName);
                item.SubItems.Add(info.IPAddress.ToString());
                item.SubItems.Add(info.Version.ToString());
                item.SubItems.Add(info.IsVirtual.ToString());
                item.SubItems.Add(info.ControllerName.ToString());
                //对逐个添加信息，信息均转化为字符创
                item.Tag = info;
                controllerCount++;
                this.listView1.Items.Add(item);
            }
            W.ABBmessage(message_lbo, "控制器已断开");
            MessageBox.Show("控制器已断开");
        }

        public void RobotList()
        {
            RobotData();
            RobTargetThree();
            DataTypearrayThread();
        }
        public string[] SpeedAndtorque = { "速度", "扭矩" };
        public string[] AXisCount = { "1轴", "2轴", "3轴", "4轴", "5轴", "6轴", "末端主轴", "所有轴" };
        private void Form1_Load(object sender, EventArgs e)
        {
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            ForemstartNew form2 = new ForemstartNew();
            form2.ShowDialog();
            //  Control.CheckForIllegalCrossThreadCalls = false;
            trackBar1.Maximum = 100; //速度的最大值，默认是91
            register = false;
            button3.Visible = true;
            panel1.Visible = false;
            menubar();
            txt_tcpvalue.Text = "50";
            txt_jointValue.Text = "3";
            FormWidth = this.Width;
            FromHeight = this.Height;
            //setTag(this);

            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;  //初始化窗体

            seriaLoad(); //串口通信
            ModbusForLoad(); //modbus通信
            Dgv_robtargetData();

            IODevNet_cmo.Items.Add("d652");
            IODevNet_cmo.Items.Add("d1030");
            IODevNet_cmo.SelectedIndex = 0;

            TCP_cbo.Items.AddRange(new string[] { "服务器", "客户端" });  //socket通信
            cboUsers1.Items.Add("All Connections");
            cboUsers1.SelectedItem = "All Connections";

            Getpos();//获取坐标系2
            GetRobotPos();//获取坐标系
            ABBmovea();

            ToolTip tooltip = new ToolTip();
            tooltip.SetToolTip(AUTO_btn, "实机不能使用,只能用于虚拟示教器！");
            tooltip.SetToolTip(manual_btn, "实机不能使用,只能用于虚拟示教器！");
            Dgv_RapidData();

        }


        private void btn_MotorOn_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode == ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    controller.State = ControllerState.MotorsOn;  //对机器人上电
                    W.ABBmessage(message_lbo, "机器人上电成功");
                }
                else
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                }
            }
            catch (System.Exception ex)
            {
                MessageBox.Show("Unexpected error occurred:" + ex.Message);
            }
        }

        private void button8_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode == ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    controller.State = ControllerState.MotorsOff;  //对机器人下电
                    W.ABBmessage(message_lbo, "机器人下电成功");
                }
                else
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                }
            }
            catch (System.Exception ex)
            {
                W.ABBmessage(message_lbo, "Unexpected error occurred:" + ex.Message);
            }
        }


        private void PPmain_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                    return;
                }
                if (controller.OperatingMode == ControllerOperatingMode.Auto)
                {
                    tasks = controller.Rapid.GetTasks();
                    using (Mastership m = Mastership.Request(controller.Rapid))
                    {
                        tasks[0].ResetProgramPointer();
                        W.ABBmessage(message_lbo, "程序指针已复位");

                    }
                }
                else
                {
                    W.ABBmessage(message_lbo, "请切换到自动模式");
                }
            }
            catch (System.InvalidOperationException ex)
            {
                MessageBox.Show("权限被其他客户端占有" + ex.Message);
                //如果请求权限失败，请出提示
            }
            catch (System.Exception ex)
            {
                MessageBox.Show("Unexpected error occurred:" + ex.Message);
            }
        }

        private void btn_Start_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                    return;
                }
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    StartResult result = controller.Rapid.Start();
                    W.ABBmessage(message_lbo, "启动成功");
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.ToString());
            }
        }
        private void Back_btn_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                    return;
                }
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    StartResult result = controller.Rapid.Start(RegainMode.Regain, ExecutionMode.StepBack);
                    W.ABBmessage(message_lbo, "启动成功");
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.ToString());
            }
        }
        private void Next_btn_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                    return;
                }
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    StartResult result = controller.Rapid.Start(RegainMode.Regain, ExecutionMode.StepIn);
                    W.ABBmessage(message_lbo, "启动成功");
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.ToString());
            }
        }
        private void btn_Stop_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                    return;
                }
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    controller.Rapid.Stop(StopMode.Immediate);
                    W.ABBmessage(message_lbo, "已停止");
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, "请设置自动模式");
            }
        }

        private void PPtomodul1_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    tasks[GetTrob_CBO.SelectedIndex].SetProgramPointer(GetModul_CBO.SelectedItem.ToString(), GetRoutine_CBO.SelectedItem.ToString());
                    W.ABBmessage(message_lbo, "程序指针已经被设置到" + GetRoutine_CBO.SelectedItem.ToString());

                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.ToString());
            }
        }

        private void GetRouiine()
        {
            try
            {
                GetTrob_CBO.Items.Clear();
                tasks = controller.Rapid.GetTasks();       //获取所有任务
                GetTrob_CBO.Items.AddRange(tasks);
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        #region //状态显示
        void SuBscribe()  //当前模式事件
        {
            controller.StateChanged += new EventHandler<StateChangedEventArgs>(controller_StateChanged);
            controller.Rapid.ExecutionStatusChanged += new EventHandler<ExecutionStatusChangedEventArgs>(exe_StateChanged);
            controller.OperatingModeChanged += new EventHandler<OperatingModeChangeEventArgs>(op_StateChanged);
            tasks[0].MotionPointerChanged += new EventHandler<ProgramPositionEventArgs>(tasks_Motion);   //索引当前运行的行数
            //添加对StateChanged事件的订阅;
        }


        private void controller_StateChanged(object sender, StateChangedEventArgs e)
        {
            this.Invoke(new EventHandler(UpdateGUIstate), sender, e);
        }

        private void UpdateGUIstate(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                if (controller.State.ToString() == "MotorsOn")
                {
                    this.label_Controller.Text = "电机上电";
                    this.label_Controller.BackColor = Color.GreenYellow;
                    btn_MotorOn.BackColor = Color.GreenYellow;
                    button8.BackColor = Color.Transparent;
                }
                else if (controller.State.ToString() == "MotorsOff")
                {
                    this.label_Controller.Text = "电机下电";
                    this.label_Controller.BackColor = Color.Red;
                    button8.BackColor = Color.Red;
                    btn_MotorOn.BackColor = Color.Transparent;
                }
                else if (controller.State.ToString() == "GuardStop")
                {
                    this.label_Controller.Text = "停止状态";
                    this.label_Controller.BackColor = Color.Red;
                    button8.BackColor = Color.Red;
                    btn_MotorOn.BackColor = Color.Transparent;
                }
                else
                {
                    this.label_Controller.Text = controller.State.ToString();
                    this.label_Controller.BackColor = Color.Red;
                    button8.BackColor = Color.Red;
                    btn_MotorOn.BackColor = Color.Transparent;
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }

        }

        private void exe_StateChanged(object sender, ExecutionStatusChangedEventArgs e)
        {
            this.Invoke(new EventHandler(UpdateGUIexe_state), sender, e);
        }

        private void UpdateGUIexe_state(object sender, EventArgs e)
        {
            try
            {

                if (controller.Rapid.ExecutionStatus.ToString() == "Running")
                {
                    this.label_exe.Text = "正在运行";
                    this.label_exe.BackColor = Color.GreenYellow;
                    this.btn_Start.BackColor = Color.GreenYellow;
                    this.btn_Stop.BackColor = Color.Transparent;
                }
                else if (controller.Rapid.ExecutionStatus.ToString() == "Stopped")
                {
                    this.label_exe.Text = "停止运行";
                    this.label_exe.BackColor = Color.Red;
                    this.btn_Start.BackColor = Color.Transparent;
                    this.btn_Stop.BackColor = Color.Red;
                }
                else
                {
                    this.label_exe.Text = controller.Rapid.ExecutionStatus.ToString();
                    this.label_exe.BackColor = Color.Red;
                    this.btn_Start.BackColor = Color.Transparent;
                    this.btn_Stop.BackColor = Color.Red;
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }
        private void op_StateChanged(object sender, OperatingModeChangeEventArgs e)
        {
            this.Invoke(new EventHandler(UpdateGUIOp_state), sender, e);
        }

        private void UpdateGUIOp_state(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                if (controller.OperatingMode.ToString() == "Auto")
                {
                    this.label_op.Text = "自动模式";
                    this.label_op.BackColor = Color.GreenYellow;
                    manual_btn.BackColor = Color.Transparent;
                    AUTO_btn.BackColor = Color.GreenYellow;
                    trackBar1.Value = 50;
                    controller.MotionSystem.SpeedRatio = Convert.ToInt32(trackBar1.Value);
                    label_speedratio.Text = $"机器人速度:{controller.MotionSystem.SpeedRatio}%";
                }
                else if (controller.OperatingMode.ToString() == "ManualReducedSpeed")
                {
                    this.label_op.Text = "手动减速";
                    this.label_op.BackColor = Color.Red;
                    manual_btn.BackColor = Color.Red;
                    AUTO_btn.BackColor = Color.Transparent;
                }
                else if (controller.OperatingMode.ToString() == "ManualFullSpeed")
                {
                    this.label_op.BackColor = Color.Red;
                    manual_btn.BackColor = Color.Red;
                    AUTO_btn.BackColor = Color.Transparent;
                }
                else if (controller.OperatingMode.ToString() == "AutoChange")
                {
                    this.label_op.Text = "自动模式";
                    this.label_op.BackColor = Color.GreenYellow;
                    manual_btn.BackColor = Color.Transparent;
                    AUTO_btn.BackColor = Color.GreenYellow;
                }
                else
                {
                    this.label_op.Text = controller.OperatingMode.ToString();
                    this.label_op.BackColor = Color.Red;
                    manual_btn.BackColor = Color.Red;
                    AUTO_btn.BackColor = Color.Transparent;
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }
        private void timer3_Tick(object sender, EventArgs e)
        {

        }
        #endregion
        #region //TpWrite写屏
        void subscribe()    //TPwire写屏
        {
            controller.Rapid.UIInstruction.UIInstructionEvent += new UIInstructionEventHandler(OnUInstructionEvent);
            //添加对UIInstruction事件的订阅
        }
        private void OnUInstructionEvent(object sender, UIInstructionEventArgs e)
        {
            this.Invoke(new EventHandler(TPMessage), sender, e);
        }

        private void TPMessage(object sender, EventArgs e)
        {
            UITPReadNumEventArgs ex1;  //声明UITPReadNumEventArgs类型的数据ex1;
            UIInstructionEventArgs ex = (UIInstructionEventArgs)e;
            TpWrite_lbx.Items.Add(DateTime.Now.ToLongTimeString().ToString() + "  " + "T_Rob1" + "->" + ex.EventMessage.ToString());
            TpWrite_lbx.SelectedIndex = TpWrite_lbx.Items.Count - 1;  //显示最后一行
            TpWrite_lbx.TopIndex = TpWrite_lbx.Items.Count - 1;   //进行全选
        }
        private void TpWrite_clear_Click(object sender, EventArgs e)
        {
            TpWrite_lbx.Items.Clear();
        }
        #endregion
        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            GetPos_timer.Stop();
            register = false;
            Thread th = new Thread(FormClosingThread);
            th.IsBackground = true;
            th.Start();
        }
        public void FormClosingThread()
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                W.ABBDatanote(controller, NumBoolData_Dgb, getSystemId + "-datanote.txt", 5);  //非数组
                W.ABBDatanote(controller, NumBoolDataArray_Dgb, getSystemId + "-arraydatanote.txt", 5);  //数组
                W.ABBDatanote(controller, DO_Dgv, getSystemId + "-dodatanote.txt", 7);  //Do信号
                W.ABBDatanote(controller, DI_Dgv, getSystemId + "-didatanote.txt", 7);
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        #region //日志
        private void btn_Alarm_Click(object sender, EventArgs e)
        {
            EventLogCategory cat;
            EventLog log = controller.EventLog;
            cat = log.GetCategory(0);   //0表示获取所有事件日志，其他类别参见CaltegoryType
            txt_Alarm.Text = "";
            foreach (EventLogMessage emsg in cat.Messages)
            {
                //遍历所有事件日志；
                int AlarmNO;
                AlarmNO = emsg.CategoryId * 10000 + emsg.Number;
                //将事件日志的类别和错误号合并，生成完整的报警代码
                this.txt_Alarm.Items.Add(this.txt_Alarm.Text + emsg.Timestamp + "      " + AlarmNO.ToString() + "  " + emsg.Title + "   " + "\r\n");
                //将获取的每一条事件日志写入textBox
                //此处举例写入时间截，报警代码和日志标题                
            }
            txt_Alarm.SelectedIndex = txt_Alarm.Items.Count - 1;  //显示最后一行
            txt_Alarm.TopIndex = txt_Alarm.Items.Count - 1;   //进行全选
        }
        private void Even_cler_Click(object sender, EventArgs e)
        {
            EventLog log = controller.EventLog;
            log.ClearAll();  //示教器日志清屏
            txt_Alarm.Items.Clear();  //上位机日志清屏
        }
        void sbBscribelog()   //日志事件
        {
            EventLog log;
            log = controller.EventLog;
            log.MessageWritten += new EventHandler<MessageWrittenEventArgs>(msg_WritenChanged);
            //添加对事件日志的订阅
        }

        private void msg_WritenChanged(object sender, MessageWrittenEventArgs e)
        {
            switch (e.Message.Type)
            {
                case EventLogEntryType.Error:
                    break;
                case EventLogEntryType.Warning:
                    break;
                case EventLogEntryType.Information:
                    break;
            }
            txt_Alarm.Items.Add(e.Message.Timestamp + "   " + e.Message.Title);
            txt_Alarm.SelectedIndex = txt_Alarm.Items.Count - 1;
            txt_Alarm.TopIndex = txt_Alarm.Items.Count - 1;
        }

        #endregion

        List<string> errLog = new List<string>();
        public string Glable_Task_Name;
        All_Controll_Method Robot_Control;

        private void button2_Click_1(object sender, EventArgs e)
        {
            try
            {
                //File.Delete(LoadProgramFromFile_txt.Text);   //删除一个文件
                //using (FileStream fswrite = new FileStream(LoadProgramFromFile_txt.Text, FileMode.OpenOrCreate, FileAccess.Write))
                //{
                //        byte[] buffer = Encoding.Default.GetBytes(GetText);                 
                //        fswrite.Write(buffer, 0, buffer.Length);
                //}
                tasks[0] = this.controller.Rapid.GetTask("T_ROB1");
                using (Mastership.Request(this.controller.Rapid))
                {
                    bool bLoadSuccess = tasks[0].LoadModuleFromFile(LoadProgramFromFile_txt.Text, RapidLoadMode.Replace);
                    if (bLoadSuccess)
                    {
                        MessageBox.Show("保存加载成功");
                    }

                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
                return;
            }
        }

        private void button9_Click(object sender, EventArgs e)
        {
            try
            {
                tasks[0] = this.controller.Rapid.GetTask("T_ROB1");
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    if (LoadPathtext_Box.Text != " ")
                    {
                        bool flag1 = tasks[0].LoadProgramFromFile(LoadPathtext_Box.Text, RapidLoadMode.Replace);
                        if (flag1)
                        {
                            MessageBox.Show("加载T_ROB2021108.pgf成功");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }



        private void button3_Click_2(object sender, EventArgs e)
        {
            try
            {
                Module m1 = tasks[0].GetModule("Module2");
                string remoteDir = controller.FileSystem.RemoteDirectory;
                using (Mastership m = Mastership.Request(controller.Rapid))
                {
                    m1.SaveToFile(remoteDir);
                    MessageBox.Show("保存Modul100成功");
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        private void button11_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
                {
                    W.ABBmessage(message_lbo, "请切换自动模式");
                    return;
                }
                if (controller != null)
                {
                    using (Mastership m = Mastership.Request(controller))
                    {
                        //获取权限
                        controller.Restart();
                    }
                }
            }
            catch (Exception)
            {
                throw;
            }
        }


        private void GetTrob_CBO_SelectedIndexChanged(object sender, EventArgs e)
        {
            GetModul_CBO.Items.Clear();
            GetRoutine_CBO.Items.Clear();
            if (register)
            {
                Module[] moduel1 = tasks[GetTrob_CBO.SelectedIndex].GetModules();  //获取任务已下的所有modul
                GetModul_CBO.Items.AddRange(moduel1);
            }
            else
                return;
        }

        private void GetModul_CBO_SelectedIndexChanged(object sender, EventArgs e)
        {
            GetRoutine_CBO.Items.Clear();
            if (register)
            {
                Module[] moduel1 = tasks[GetTrob_CBO.SelectedIndex].GetModules();
                Routine[] r = moduel1[GetModul_CBO.SelectedIndex].GetRoutines();   //获取moduel下的所有Routine          
                GetRoutine_CBO.Items.AddRange(r);
            }
            else
                return;
        }
        WinMove W = new WinMove();


        private void AUTO_btn_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            if (!isVirtual)
            {
                MessageBox.Show("实机无法使用");
                return;
            }
            VirtualPanel vp = VirtualPanel.Attach(controller);
            try
            {
                ControllerOperatingMode Change_Mode = ControllerOperatingMode.Auto;
                vp.BeginChangeOperatingMode(Change_Mode, new AsyncCallback(ChangeMode), vp);
                W.ABBmessage(message_lbo, "请去示教器去确认自动模式");
            }
            catch (ABB.Robotics.TimeoutException ex)
            {
                MessageBox.Show("[error]    切换模式错误" + "\r\n" + ex);
                W.ABBmessage(message_lbo, "[error]    切换模式错误" + "\r\n" + ex);
            }
            vp.Dispose();
        }


        private void ChangeMode(IAsyncResult iar)
        {
            VirtualPanel vp = (VirtualPanel)iar.AsyncState;
            vp.EndChangeOperatingMode(iar);
            //vp.Dispose();
        }

        private void manual_btn_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            if (!isVirtual)
            {
                MessageBox.Show("实机无法使用");
                return;
            }
            VirtualPanel vp = VirtualPanel.Attach(controller);  //ManualReducedSpeed;
            try
            {
                ControllerOperatingMode Change_Mode = ControllerOperatingMode.ManualReducedSpeed;
                vp.BeginChangeOperatingMode(Change_Mode, new AsyncCallback(ChangeMode), vp);
                // MessageBox.Show("[msg]\t切换成手动模式成功");
                W.ABBmessage(message_lbo, "切换手动模式成功");
            }
            catch (ABB.Robotics.TimeoutException ex)
            {
                //MessageBox.Show("[error]    切换模式错误" + "\r\n" + ex);
                W.ABBmessage(message_lbo, "[error]    切换模式错误" + "\r\n" + ex);
            }
            vp.Dispose();
        }

        private void tasks_Motion(object sender, ProgramPositionEventArgs e)
        {
            this.Invoke(new EventHandler(tasks_MotionEven), sender, e);
        }

        private void tasks_MotionEven(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                if (ShowRapidbool)
                {
                    tasks[0] = controller.Rapid.GetTask("T_ROB1");  //ProgramPointer
                    ProgramPosition p = tasks[0].ProgramPointer;
                    string s = p.Module;
                    string z = "当前指针：" + p.Routine;
                    TextRange T = p.Range;
                    Location L = T.Begin;
                    Location L1 = T.End;
                    ShowRapid_dgv.CurrentCell = ShowRapid_dgv.Rows[L.Row].Cells[1];
                }
            }
            catch (Exception)
            {
            }
        }


        private void rd1_ValueChanged(object sender, DataValueChangedEventArgs e)
        {
            this.Invoke(new EventHandler(rd1EventArgs), sender, e);
        }

        private void rd1EventArgs(object sender, EventArgs e)
        {
            Thread th = new Thread(rd1EventArgsThree);
            th.IsBackground = true;
            th.Start(sender);
        }


        public void rd1EventArgsThree(object sender)
        {

            try
            {
                RapidData rd1 = (RapidData)sender;
                int a = listNumName.IndexOf(rd1.Name);     //索引名字
                if (open == true)
                {
                    if (TCP_cbo.SelectedItem.ToString() == "客户端")
                    {
                        if (SendDataName_cbo.SelectedItem.ToString() == rd1.Name)
                        {
                            string str = rd1.Value.ToString();
                            if (str != "\"\"")
                            {
                                string str1 = str.Trim(new char[2] { '\"', '\"' });   //删除[];
                                byte[] buffer = System.Text.Encoding.UTF8.GetBytes(str1);
                                socketSend.Send(buffer);
                                ShowMsg(str, "ABB上位机");
                            }
                        }
                    }
                    else if (TCP_cbo.SelectedItem.ToString() == "服务器")
                    {
                        if (SendDataName_cbo.SelectedItem.ToString() == rd1.Name)
                        {
                            string str = rd1.Value.ToString();
                            if (str != "\"\"")
                            {
                                string str1 = str.Trim(new char[2] { '\"', '\"' });   //删除[];
                                byte[] buffer = System.Text.Encoding.UTF8.GetBytes(str1);
                                string ip = cboUsers1.SelectedItem.ToString();
                                if (ip == "All Connections")
                                {
                                    for (int i = 1; i < cboUsers1.Items.Count; i++)
                                    {
                                        string stritem = cboUsers1.Items[i].ToString();
                                        dicSocket[stritem].Send(buffer);
                                    }
                                }
                                else
                                {
                                    dicSocket[ip].Send(buffer);
                                }

                            }
                        }
                    }
                }
                if (Seropen == true)
                {
                    if (SendSerName_cbb.SelectedItem.ToString() == rd1.Name)
                    {
                        string str = rd1.Value.ToString();
                        if (str != "\"\"")
                        {
                            string str1 = str.Trim(new char[2] { '\"', '\"' });   //删除"";
                            serialPort1.Write(str);
                            SerShowMsg(str, "ABB上位机");
                        }
                    }
                }
                if (a != -1)
                {
                    NumBoolData_Dgb[3, a].Style.BackColor = Color.Green;    //单元格绿色
                    NumBoolData_Dgb[3, a].Value = rd1.Value;
                    Thread.Sleep(300);   //停留0.3秒后启动 
                    NumBoolData_Dgb[3, a].Style.BackColor = Color.White;  //单元格白色
                }

            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }

        private void SignalEvent(object sender, SignalChangedEventArgs e)
        {
            try
            {
                this.Invoke(new EventHandler(SignalEventtwo), sender, e);
            }
            catch
            {

            }
        }

        private void SignalEventtwo(object sender, EventArgs e)
        {
            try
            {
                Signal sig = (Signal)sender;
                if (sig.Name == "ao_speed")
                {
                    userGaugeChart1.Value = Math.Round(sig.Value * 1000);
                }
                else
                {
                    int a = ListDiName.IndexOf(sig.Name);
                    int b = listDoName.IndexOf(sig.Name);
                    if (a != -1)
                    {
                        this.DI_Dgv.Rows[a].Cells[3].Value = sig.Value;
                        if (sig.Value == 1)
                        {
                            DI_Dgv[3, a].Style.BackColor = Color.Green;
                            DI_Dgv[4, a].Style.BackColor = Color.Green;
                            DI_Dgv.Rows[a].Cells[4].Value = "关闭";
                        }
                        else
                        {
                            DI_Dgv[3, a].Style.BackColor = Color.White;
                            DI_Dgv[4, a].Style.BackColor = Color.White;
                            DI_Dgv.Rows[a].Cells[4].Value = "打开";
                        }
                    }

                    if (b != -1)
                    {
                        this.DO_Dgv.Rows[b].Cells[3].Value = sig.Value;
                        if (sig.Value == 1)
                        {
                            DO_Dgv[3, b].Style.BackColor = Color.Green;
                            DO_Dgv[4, b].Style.BackColor = Color.Green;
                            DO_Dgv.Rows[b].Cells[4].Value = "关闭";
                        }
                        else
                        {
                            DO_Dgv[3, b].Style.BackColor = Color.White;
                            DO_Dgv[4, b].Style.BackColor = Color.White;
                            DO_Dgv.Rows[b].Cells[4].Value = "打开";
                        }
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        System.Windows.Forms.Timer timer = new System.Windows.Forms.Timer();




        private int DgvRowIndex;
        private int DgvRowIndex1;
        RobTarget aRobTarget;
        JointTarget ajointTarget;
        public double rx, ry, rz;

        private void button15_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            Thread th = new Thread(RobotList);
            th.IsBackground = true;
            th.Start();


        }
        #region  //修改程序和加载程序
        private void LoadPathtext_btn_Click(object sender, EventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "RAPID文件(*.mod;*.sys;*.pgf)|*.mod;*.sys;*.pgf|所有文件|*.*";
            if (ofd.ShowDialog() == DialogResult.OK)
            {
                LoadPathtext_Box.Text = ofd.FileName;
            }

        }
        List<string> listbox = new List<string>();
        string[] TextboxRapid = new string[] { };
        private string GetText = "";
        private void LoadProgramFromFile_btn_Click(object sender, EventArgs e)
        {
            try
            {
                OpenFileDialog ofd = new OpenFileDialog();
                ofd.Filter = "RAPID文件(*.mod;*.sys)|*.mod;*.sys|所有文件|*.*";
                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    LoadProgramFromFile_txt.Text = ofd.FileName;
                }
                //using (System.IO.FileStream fsRead = new FileStream(LoadProgramFromFile_txt.Text, FileMode.OpenOrCreate, FileAccess.Read))
                //{
                //    byte[] buffer = new byte[1024 * 1024 * 5];
                //    int r = fsRead.Read(buffer, 0, buffer.Length);
                //    GetText = Encoding.Default.GetString(buffer, 0, r);    
                //}
                TextboxRapid = File.ReadAllLines(LoadProgramFromFile_txt.Text, Encoding.Default);//主要是以数组读文本文件
            }
            catch (Exception)
            {

            }
        }
        private bool ShowRapidbool = false;
        private void ShowRapid_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                return;
            }
            string getmoduel = "", getmoduel1 = "";

            Module[] moduel1 = tasks[0].GetModules();
            for (int i = 0; i < moduel1.Length; i++)
            {
                if (moduel1[i].ToString() != "BASE" && moduel1[i].ToString() != "user")
                {
                    getmoduel1 = moduel1[i].ToString();
                    getmoduel = moduel1[i].ToString() + ".mod";
                    getmoduel = "MainModule.mod";
                }
            }

            string[] TextboxRapid1 = new string[] { };
            // string ReadText = controller.FileSystem.LocalDirectory + "\\Module1.mod"; //获取PC默认路径     
            string ReadText = controller.FileSystem.LocalDirectory + "\\" + "MainModule.mod";
            string remoteDir = controller.FileSystem.RemoteDirectory;   //获取机器人的home路径
            try
            {

                Module m1 = tasks[0].GetModule(getmoduel1);   //创建一个Module1.mod的实例
                using (Mastership.Request(controller.Rapid))
                {
                    m1.SaveToFile(remoteDir);  //把Module1文件保存到机器人的Home文件下;
                }
                controller.FileSystem.GetFile(getmoduel, getmoduel, true);  //把Module1保存到PC的debug文件夹中
                TextboxRapid1 = File.ReadAllLines(ReadText, Encoding.Default);  //读取Module1文件

                ShowRapidbool = true;
                string[] DataName = { "序号", "Rapid" };
                string[] DataHeaderText = { "Name0", "Name1" };
                int[] sizeWith = { 60, 1000 };
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                ShowRapid_dgv.Columns.Clear();
                for (int i = 0; i < dgv.Length; i++)
                {
                    dgv[i] = new DataGridViewColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                    ShowRapid_dgv.Columns.Add(dgv[i]);
                }
                for (int i = 0; i < TextboxRapid1.Length; i++)
                {
                    ShowRapid_dgv.Rows.Add();
                    ShowRapid_dgv[0, i].Value = (i + 1).ToString();
                    ShowRapid_dgv[1, i].Value = TextboxRapid1[i];
                }
                W.dataGridViewSize(ShowRapid_dgv, false);
                W.ABBmessage(message_lbo, "程序加载成功");
                RDataTypeThree();  //存工具，工件，信号下拉框数据
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
        private void 插入行ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex, "");
        }

        private void 删除行ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            ShowRapid_dgv.Rows.RemoveAt(ShowRapid_dgv.CurrentCell.RowIndex);
        }
        private void 清除行ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = " ";
        }
        string[] revampRapid;
        private void revampRapid_btn_Click(object sender, EventArgs e)
        {
            GetPos_timer.Stop();
            Thread.Sleep(1000);
            string Getbox = "";
            string FileName = controller.FileSystem.LocalDirectory + "\\"+"MainModule.mod";
            try
            {
                revampRapid = new string[ShowRapid_dgv.Rows.Count];
                for (int i = 0; i < ShowRapid_dgv.Rows.Count; i++)
                {
                    if (ShowRapid_dgv[1, i].Value == null)
                    {
                        ShowRapid_dgv[1, i].Value = " ";
                    }
                    revampRapid[i] = ShowRapid_dgv[1, i].Value.ToString();
                }

                File.Delete(FileName);   //删除一个文件
                using (FileStream fswrite = new FileStream(FileName, FileMode.OpenOrCreate, FileAccess.Write))  //生成一个新的Rapid
                {
                    for (int i = 0; i < revampRapid.Length; i++)
                    {
                        Getbox += revampRapid[i] + "\r\n";
                    }
                    byte[] buffer = Encoding.Default.GetBytes(Getbox);
                    fswrite.Write(buffer, 0, buffer.Length);
                }
                tasks[0] = this.controller.Rapid.GetTask("T_ROB1");
                string strFileFullName = string.Empty;
                string strFileNmae = string.Empty;
                OpenFileDialog ofd = new OpenFileDialog();
                ofd.FileName = FileName;
                strFileFullName = ofd.FileName;
                strFileNmae = ofd.SafeFileName;
                    string remoteDir = controller.FileSystem.RemoteDirectory;
                    if (controller.FileSystem.FileExists(strFileNmae))
                    {
                        controller.FileSystem.PutFile(strFileFullName, strFileNmae, true);
                    }
                    else
                    {
                        controller.FileSystem.PutFile(strFileFullName, strFileNmae);
                    }
                using (Mastership.Request(this.controller.Rapid))
                {
                    bool bLoadSuccess = tasks[0].LoadModuleFromFile("MainModule.mod", RapidLoadMode.Replace);
                    if (bLoadSuccess)
                    {
                        W.ABBmessage(message_lbo, "修改成功");
                    }

                }
                W.RapidError(controller, tasks[0]);
            }
            catch (Exception ex)
            {
               // MessageBox.Show(ex.ToString());
                return;
            }
            rapids = W.rapidSymbol(controller, string.Empty);
               GetPos_timer.Start();
        }
        #endregion
        private void button2_Click(object sender, EventArgs e)
        {
            panel1.Visible = false;
            button3.Visible = true;
            ShowRapid_dgv.Size = new System.Drawing.Size(1008, 756);
        }


        private void button3_Click(object sender, EventArgs e)
        {
            panel1.Visible = true;
            button3.Visible = false;
            ShowRapid_dgv.Size = new System.Drawing.Size(758, 756);
        }

        private void Configuration_open_Click(object sender, EventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "configuration files   (*.cfg)|*.cfg";
            if (ofd.ShowDialog() == DialogResult.OK)
            {
                Configuration_cbo.Text = ofd.FileName;
            }
        }

        private void Configuration_btn_Click(object sender, EventArgs e)
        {
            try
            {
                using (Mastership.Request(controller))
                {
                    controller.Configuration.Load(Configuration_cbo.Text, LoadMode.ResetAndAdd);
                    //可以使用全部删除再加载
                    //也可以使用Replace替换重复项
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message.ToString());
            }
            MessageBox.Show("加载EIO成功，需要重启控制器生效！");
        }

        private void Domain_save_Click(object sender, EventArgs e)
        {
            SaveFileDialog saveFileDialog1 = new SaveFileDialog();
            saveFileDialog1.Filter = "configuration files   (*.cfg)|*.cfg";
            saveFileDialog1.FilterIndex = 2;
            saveFileDialog1.RestoreDirectory = true;
            saveFileDialog1.FileName = "EIO.cfg";
            //打开另存对话框
            if (saveFileDialog1.ShowDialog() == DialogResult.OK)
            {
                Domain_cbo.Text = saveFileDialog1.FileName;
                if (File.Exists(Domain_cbo.Text))
                {
                    File.Delete(Domain_cbo.Text);
                }
                controller.Logon(UserInfo.DefaultUser);
            }
        }

        private void Domain_btn_Click(object sender, EventArgs e)
        {
            Domain domain1 = controller.Configuration.ExternalIO;
            try
            {
                using (Mastership.Request(controller))
                {
                    domain1.Save(Domain_cbo.Text);
                    MessageBox.Show("保存EIO成功");
                    //保存EIO
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message.ToString());
            }

        }


        private void backups_btn_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller != null)
                {
                    UserAuthorizationSystem uas = controller.AuthenticationSystem;
                    if (uas.CheckDemandGrant(Grant.BackupController))
                    { //检查该登录用户是否有备份权限
                        string s = controller.SystemName + "_backup_" + DateTime.Now.ToString("yyyy-MM-dd");
                        //备份名字为 控制器名字+backup+日期
                        // 临时备份路径为home
                        if (controller.FileSystem.DirectoryExists(s))
                        {
                            //如果home下存在临时备份，删除HOME下的临时备份
                            controller.FileSystem.RemoveDirectory(s, true);
                        }
                        string path = string.Empty;
                        System.Windows.Forms.FolderBrowserDialog fbd = new System.Windows.Forms.FolderBrowserDialog();
                        if (fbd.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                        {
                            path = fbd.SelectedPath;
                            // 选择PC本地路径
                        }
                        string path_backup = path + "/" + s;
                        string path_backup1 = path + "/" + s;
                        int count = 1;
                        while (Directory.Exists(path_backup1))
                        {
                            path_backup1 = path_backup + "(" + count + ")";
                            count = count + 1;
                        }
                        //如果PC本地有同名文件夹，备份文件夹名字后自动+1
                        controller.Backup(@s);
                        //备份到控制器的Home下                      
                        while (controller.BackupInProgress)
                        {
                            //等待备份完成
                        }
                        controller.FileSystem.GetDirectory(s, path_backup1, true);
                        // 传输到本地
                        controller.FileSystem.RemoveDirectory(s, true);
                        //删除controller上的临时备份                     
                    }
                    else
                    {
                        MessageBox.Show("没有权限 ");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("异常：" + ex.ToString());
            }
        }

        private void restart_btn_Click(object sender, EventArgs e)
        {
            try
            {
                if (controller != null)
                {
                    using (Mastership m = Mastership.Request(controller))
                    {
                        //获取权限
                        controller.Restart();
                    }
                }
            }
            catch (Exception)
            {
                throw;
            }
        }

        private void button4_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            IoDOthree();
            IOSingnal();
            // ao_speed();
            //  DO_Dgv.MouseClick += null;
        }


        #region //Do信号
        public void IoDOthree()
        {
            Thread th = new Thread(IOsignalDo);
            th.IsBackground = true;
            th.Start();
        }
        List<string> listDoName = new List<string>();
        List<string> listDoVlaue = new List<string>();

        public void IOsignalDo()
        {
            int Datawidth = 0;
            try
            {
                if (controller == null)
                {
                    return;
                }
                string[] IOName = { "信号名称", "信号类型", "所属设备", "值", "修改值", "按下按键", "脉冲长度", "注释" };
                string[] IOHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Nane5", "Name6", "Name7" };
                int[] sizeWith = { 140, 140, 100, 100, 100, 120, 100, 200 };
                string[] comboxText = { "切换", "按下/松开", "脉冲" };
                DataGridViewColumn[] dgv = new DataGridViewColumn[IOName.Length];
                DO_Dgv.Columns.Clear();
                for (int i = 0; i < dgv.Length; i++)
                {
                    if (i == 4)
                    {
                        dgv[i] = new DataGridViewButtonColumn() { Name = IOName[i], HeaderText = IOName[i], Width = sizeWith[i], CellTemplate = new DataGridViewButtonCell() };
                    }
                    else if (i == 5)
                    {
                        dgv[i] = new DataGridViewComboBoxColumn() { Name = IOName[i], HeaderText = IOName[i], Width = sizeWith[i], CellTemplate = new DataGridViewComboBoxCell() };
                    }
                    else
                    {
                        dgv[i] = new DataGridViewColumn() { Name = IOName[i], HeaderText = IOName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                    }
                    DO_Dgv.Columns.Add(dgv[i]);
                }

                DataGridViewComboBoxColumn cmbox = DO_Dgv.Columns[5] as DataGridViewComboBoxColumn;   //第5行强转成DataGridViewComboBoxColumn
                cmbox.Items.AddRange(comboxText);    //添加下拉框成员
                cmbox.DefaultCellStyle.NullValue = "切换";   //默认选择切换

                DO_Dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头对齐
                DO_Dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //单元格对齐

                //for (int i = 0; i < this.DO_Dgv.Columns.Count; i++)
                //{
                //    this.DO_Dgv.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
                //    Datawidth += this.DO_Dgv.Columns[i].Width;  //记录整个DataGridView的宽度
                //}
                ////判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
                ////则将DataGridView的列自动调整模式设置为显示的列即可，
                ////如果是小于原来设定的宽度，将模式改为填充。
                //if (Datawidth > this.DO_Dgv.Size.Width)
                //{
                //    this.DO_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
                //}
                //else
                //{
                //    this.DO_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
                //}
                //DO_Dgv.Columns[0].Frozen = true;   //冻结某列 从左开始 0，1，2
                // DO_Dgv.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.AllCellsExceptHeaders;   //行宽自动调整

                SignalCollection signals = controller.IOSystem.GetSignals(IOFilterTypes.Output);
                foreach (Signal signal in signals)
                {

                    if (signal.Unit != "DRV_1" && signal.Unit != "PANEL")
                    {
                        int index = DO_Dgv.Rows.Add();
                        DO_Dgv.Rows[index].Cells[0].Value = signal.Name;
                        listDoName.Add(signal.Name);
                        DO_Dgv.Rows[index].Cells[1].Value = signal.Type.ToString();
                        DO_Dgv.Rows[index].Cells[2].Value = signal.Unit.ToString();
                        DO_Dgv.Rows[index].Cells[3].Value = signal.Value.ToString();
                        listDoVlaue.Add(signal.Value.ToString());
                        signal.Changed += new EventHandler<SignalChangedEventArgs>(SignalEvent);
                    }
                }

                W.ReadDatanote(controller, getSystemId + "-dodatanote.txt", listDoName, DO_Dgv, 7);  //读注释

                DO_Dgv.AllowUserToAddRows = false;  //关闭自动添加行
                for (int i = 0; i < this.DO_Dgv.Columns.Count; i++)
                {
                    this.DO_Dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                }
                for (int i = 0; i < 4; i++)
                {
                    this.DO_Dgv.Columns[i].ReadOnly = true;     //禁止i列单元格编辑
                }

                for (int i = 0; i < sizeWith.Length; i++)
                {
                    DO_Dgv.Columns[i].Width = sizeWith[i];  //设置列宽
                }
                this.DO_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect; //选中整行
                for (int i = 0; i < listDoVlaue.Count; i++)
                {
                    if (listDoVlaue[i] == "1")
                    {
                        this.DO_Dgv.Rows[i].Cells[4].Value = "关闭";
                        this.DO_Dgv[3, i].Style.BackColor = Color.Green;    //单元格绿色
                        this.DO_Dgv[4, i].Style.BackColor = Color.Green;    //单元格绿色

                    }
                    else
                    {
                        this.DO_Dgv.Rows[i].Cells[4].Value = "打开";
                        this.DO_Dgv[3, i].Style.BackColor = Color.White;    //单元格绿色
                        this.DO_Dgv[4, i].Style.BackColor = Color.White;    //单元格白色

                    }
                }
            }
            catch (Exception)
            {

            }
        }
        private void DO_Dgv_MouseEnter(object sender, EventArgs e)
        {
            this.MouseWheel += Dodgv_MouseWheel;
        }

        private void Dodgv_MouseWheel(object sender, MouseEventArgs e)
        {
            Point p = PointToScreen(e.Location);
            W.dgv_MouseWheel(DO_Dgv, e, p);
        }
        #endregion
        #region //Di信号
        public void IOSingnal()
        {
            Thread th = new Thread(ThreeIO);
            th.IsBackground = true;
            th.Start();
        }

        List<string> ListDiName = new List<string>();
        List<string> ListDiVlaue = new List<string>();
        public void ThreeIO()
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                string[] IOName = { "信号名称", "信号类型", "所属设备", "值", "修改值", "按下按键", "脉冲长度", "注释" };
                string[] IOHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Name5", "Name6", "Name7" };
                string[] comboxText = { "切换", "按下/松开", "脉冲" };
                int[] sizeWith = { 140, 140, 100, 100, 100, 120, 100, 200 };
                int Datawidth = 0;
                DataGridViewColumn[] dgv = new DataGridViewColumn[IOName.Length];
                DI_Dgv.Columns.Clear();
                for (int i = 0; i < dgv.Length; i++)
                {
                    if (i == 4)
                    {
                        dgv[i] = new DataGridViewButtonColumn() { Name = IOName[i], HeaderText = IOName[i], Width = sizeWith[i], CellTemplate = new DataGridViewButtonCell() };
                    }
                    else if (i == 5)
                    {
                        dgv[i] = new DataGridViewComboBoxColumn() { Name = IOName[i], HeaderText = IOName[i], Width = sizeWith[i], CellTemplate = new DataGridViewComboBoxCell() };
                    }
                    else
                    {
                        dgv[i] = new DataGridViewColumn() { Name = IOName[i], HeaderText = IOName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                    }
                    DI_Dgv.Columns.Add(dgv[i]);
                }

                DataGridViewComboBoxColumn cmbox = DI_Dgv.Columns[5] as DataGridViewComboBoxColumn;   //第5行强转成DataGridViewComboBoxColumn
                cmbox.Items.AddRange(comboxText);    //添加下拉框成员
                cmbox.DefaultCellStyle.NullValue = "切换";   //默认选择切换

                DI_Dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
                DI_Dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;


                SignalCollection signals = controller.IOSystem.GetSignals(IOFilterTypes.Input);
                foreach (Signal signal in signals)
                {

                    if (signal.Unit != "DRV_1" && signal.Unit != "PANEL")
                    {
                        int index = DI_Dgv.Rows.Add();
                        DI_Dgv.Rows[index].Cells[0].Value = signal.Name;
                        ListDiName.Add(signal.Name);
                        DI_Dgv.Rows[index].Cells[1].Value = signal.Type.ToString();
                        DI_Dgv.Rows[index].Cells[2].Value = signal.Unit.ToString();
                        DI_Dgv.Rows[index].Cells[3].Value = signal.Value.ToString();
                        ListDiVlaue.Add(signal.Value.ToString());
                        signal.Changed += new EventHandler<SignalChangedEventArgs>(SignalEvent);
                    }
                }
                //Signal sigspeed = controller.IOSystem.GetSignal("ao_speed");
                //sigspeed.Changed += new EventHandler<SignalChangedEventArgs>(SignalEvent);


                W.ReadDatanote(controller, getSystemId + "-didatanote.txt", ListDiName, DI_Dgv, 7);

                //for (int i = 0; i < this.DI_Dgv.Columns.Count; i++)
                //{
                //    this.DI_Dgv.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
                //    Datawidth += this.DI_Dgv.Columns[i].Width;  //记录整个DataGridView的宽度
                //}
                ////判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
                ////则将DataGridView的列自动调整模式设置为显示的列即可，
                ////如果是小于原来设定的宽度，将模式改为填充。
                //if (Datawidth > this.DI_Dgv.Size.Width)
                //{
                //    this.DI_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
                //}
                //else
                //{
                //    this.DI_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
                //}
                //DI_Dgv.Columns[0].Frozen = true;   //冻结某列 从左开始 0，1，2
                DI_Dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
                DI_Dgv.AllowUserToAddRows = false;  //关闭自动添加行
                this.DI_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
                for (int i = 0; i < this.DI_Dgv.Columns.Count; i++)
                {
                    this.DI_Dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                }
                for (int i = 0; i < 4; i++)
                {
                    this.DI_Dgv.Columns[i].ReadOnly = true;     //禁止i列单元格编辑
                }
                for (int i = 0; i < sizeWith.Length; i++)
                {
                    DI_Dgv.Columns[i].Width = sizeWith[i];
                }

                for (int i = 0; i < listDoVlaue.Count; i++)
                {
                    if (ListDiVlaue[i] == "1")
                    {
                        this.DI_Dgv.Rows[i].Cells[4].Value = "关闭";
                        this.DI_Dgv[3, i].Style.BackColor = Color.Green;    //单元格绿色
                        this.DI_Dgv[4, i].Style.BackColor = Color.Green;    //单元格绿色

                    }
                    else
                    {
                        this.DI_Dgv.Rows[i].Cells[4].Value = "打开";
                        this.DI_Dgv[3, i].Style.BackColor = Color.White;    //单元格绿色
                        this.DI_Dgv[4, i].Style.BackColor = Color.White;    //单元格白色

                    }
                }
            }
            catch (Exception)
            {

            }
        }

        private void DI_Dgv_MouseClick(object sender, MouseEventArgs e)
        {
            try
            {
                DataGridView.HitTestInfo htf = this.DI_Dgv.HitTest(e.X, e.Y);   //只为第4行提供事件触发            
                if (htf.ColumnIndex == 4)
                {
                    switch (DI_Dgv.Rows[htf.RowIndex].Cells[5].FormattedValue.ToString())
                    {
                        case "切换":
                            {
                                if (DI_Dgv.Rows[DI_Dgv.CurrentCell.RowIndex].Cells[4].Value == "打开")
                                {
                                    W.ABBsingal(controller, message_lbo, ListDiName[DI_Dgv.CurrentCell.RowIndex].ToString(), 1, false);
                                }
                                else
                                {
                                    W.ABBsingal(controller, message_lbo, ListDiName[DI_Dgv.CurrentCell.RowIndex], 0, false);
                                }
                                break;
                            }

                        case "脉冲":
                            {
                                int a = Convert.ToInt32(DI_Dgv.Rows[DI_Dgv.CurrentCell.RowIndex].Cells[6].Value);
                                W.ABBsingal(controller, message_lbo, ListDiName[DI_Dgv.CurrentCell.RowIndex], a, true);
                                break;
                            }

                        case "按下/松开":
                            {
                                return;
                            }
                    }

                }
            }
            catch (Exception)
            {

            }
        }
        private void DI_Dgv_MouseEnter(object sender, EventArgs e)
        {
            this.MouseWheel += Didgv_MouseWheel;
        }

        private void Didgv_MouseWheel(object sender, MouseEventArgs e)
        {
            Point p = PointToScreen(e.Location);
            W.dgv_MouseWheel(DI_Dgv, e, p);
        }
        #endregion
        public void RobotData()
        {
            Thread th = new Thread(ThreeData);
            th.IsBackground = true;
            th.Start();
        }
        public List<string> listNumName = new List<string>();
        public List<string> listNumVlaue = new List<string>();
        public void ThreeData()
        {
            int CountData = 0;
            int Datawidth = 0;
            try
            {
                if (controller == null)
                {
                    return;
                }
                string[] DataName = { "数据名称", "存储类型", "数据类型", "值", "修改值", "注释" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Name5" };
                int[] sizeWith = { 200, 120, 80, 80, 80, 250 };
                int Numdata = 0;
                NumBoolData_Dgb.Columns.Clear();
                NumBoolData_Dgb.Rows.Clear();
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                for (int i = 0; i < dgv.Length; i++)
                {
                    dgv[i] = new DataGridViewColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                    NumBoolData_Dgb.Columns.Add(dgv[i]);
                }

                RapidSymbol[] symbolsNum = W.rapidSymbol(controller, "num");
                RapidSymbol[] symbolsBool = W.rapidSymbol(controller, "bool");
                RapidSymbol[] symbolsString = W.rapidSymbol(controller, "string");

                for (int i = 0; i < symbolsNum.Length; i++)
                {
                    if (symbolsNum[i].Type.ToString() == "Persistent")
                    {
                        RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                        if (rd.IsArray != true)
                        {
                            NumBoolData_Dgb.Rows.Add();
                            NumBoolData_Dgb.Rows[i - CountData].Cells[0].Value = symbolsNum[i].Name;
                            listNumName.Add(symbolsNum[i].Name);
                            NumBoolData_Dgb.Rows[i - CountData].Cells[1].Value = symbolsNum[i].Type.ToString();
                            NumBoolData_Dgb.Rows[i - CountData].Cells[2].Value = rd.RapidType;
                            if (rd.Value == null)
                            {
                                continue;
                            }
                            NumBoolData_Dgb.Rows[i - CountData].Cells[3].Value = rd.Value.ToString();
                            listNumVlaue.Add(rd.Value.ToString());
                            rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(rd1_ValueChanged);
                        }
                        else
                        {
                            CountData++;
                        }
                    }
                    else
                    {
                        CountData++;
                    }
                }
                for (int i = 0; i < symbolsBool.Length; i++)
                {
                    //if (symbolsBool[i].Type.ToString() == "Persistent")
                    //{
                    RapidData rd = tasks[0].GetRapidData(symbolsBool[i]);
                    if (rd.IsArray != true)
                    {
                        NumBoolData_Dgb.Rows.Add();
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[0].Value = rd.Name;
                        listNumName.Add(symbolsBool[i].Name);
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[1].Value = symbolsBool[i].Type.ToString();
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[2].Value = rd.RapidType;
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[3].Value = rd.Value.ToString();
                        listNumVlaue.Add(rd.Value.ToString());
                        rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(rd1_ValueChanged);
                    }
                    else
                    {
                        Numdata++;
                    }
                }
                //    else
                //    {
                //        Numdata++;
                //    }
                //}

                for (int i = 0; i < symbolsString.Length; i++)
                {

                    //if (symbolsString[i].Type.ToString() == "Persistent")
                    //{
                    RapidData rd = tasks[0].GetRapidData(symbolsString[i]);
                    if (rd.IsArray != true)
                    {

                        NumBoolData_Dgb.Rows.Add();
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[0].Value = rd.Name;
                        listNumName.Add(symbolsString[i].Name);
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[1].Value = symbolsString[i].Type.ToString();
                        if (rd.Value == null)
                        {
                            continue;
                        }
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[2].Value = rd.RapidType;
                        if (rd.Value == null)
                        {
                            continue;
                        }
                        NumBoolData_Dgb.Rows[i + NumBoolData_Dgb.Rows.Count - (i + 1)].Cells[3].Value = rd.Value.ToString();
                        listNumVlaue.Add(rd.Value.ToString());
                        rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(rd1_ValueChanged);
                    }

                    else
                    {
                        Numdata++;
                    }
                }

                //    else
                //    {
                //        Numdata++;
                //    }
                //}

                W.ReadDatanote(controller, getSystemId + "-datanote.txt", listNumName, NumBoolData_Dgb, 5); //读注释

                for (int i = 0; i < this.NumBoolData_Dgb.Columns.Count; i++)
                {
                    this.NumBoolData_Dgb.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
                    Datawidth += this.NumBoolData_Dgb.Columns[i].Width;  //记录整个DataGridView的宽度
                }
                //判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
                //则将DataGridView的列自动调整模式设置为显示的列即可，
                //如果是小于原来设定的宽度，将模式改为填充。
                if (Datawidth > this.NumBoolData_Dgb.Size.Width)
                {
                    this.NumBoolData_Dgb.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
                }
                else
                {
                    this.NumBoolData_Dgb.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
                }
                NumBoolData_Dgb.Columns[0].Frozen = true;   //冻结某列 从左开始 0，1，2

                NumBoolData_Dgb.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头居中
                NumBoolData_Dgb.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中
                this.NumBoolData_Dgb.SelectionMode = DataGridViewSelectionMode.FullRowSelect; //选中整行


                for (int i = 0; i < this.NumBoolData_Dgb.Columns.Count; i++)
                {
                    this.NumBoolData_Dgb.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                }
                for (int i = 0; i < 4; i++)
                {
                    this.NumBoolData_Dgb.Columns[i].ReadOnly = true;     //禁止i列单元格编辑
                }
                for (int i = 0; i < sizeWith.Length; i++)
                {
                    NumBoolData_Dgb.Columns[i].Width = sizeWith[i];
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }

        }

        private void NumBoolData_Dgb_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {

            if (e.ColumnIndex != 4) return;
            int row = e.RowIndex;
            if (NumBoolData_Dgb[0, row].Value == null) return;
            string name = NumBoolData_Dgb[0, row].Value.ToString();
            string task = NumBoolData_Dgb[1, row].Value.ToString();
            string module1 = NumBoolData_Dgb[2, row].Value.ToString();
            string newValue = NumBoolData_Dgb[4, row].Value.ToString();
            SetValue(newValue, task, module1, name);
        }
        private void NumBoolData_Dgb_MouseEnter(object sender, EventArgs e)
        {
            this.MouseWheel += NumBoolData_MouseWheel;
        }

        private void NumBoolData_MouseWheel(object sender, MouseEventArgs e)  //控件滚轮
        {
            Point p = PointToScreen(e.Location);
            W.dgv_MouseWheel(NumBoolData_Dgb, e, p);
        }

        #region      //robtarget数据类型  
        public void RobTargetThree()
        {
            Thread th = new Thread(RobTargetData);
            th.IsBackground = true;
            th.Start();
        }
        public List<string> listRobTarget = new List<string>();

        public void RobTargetData()
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                string[] DataName = { "勾选", "数据名称", "存储类型", "数据类型", "X", "Y", "Z", "RZ", "RY", "RX", "修改位置" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Name5", "Name6", "Name7", "Name8", "Name9", "Name10" };
                int[] sizeWith = { 50, 120, 100, 100, 80, 80, 80, 80, 80, 80, 80 };
                int Datawidth = 0;
                int DataCount = 0;
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                RobTarget_Dgv.Columns.Clear();
                for (int i = 0; i < dgv.Length; i++)
                {
                    switch (i)
                    {
                        case 0:
                            dgv[i] = new DataGridViewCheckBoxColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewCheckBoxCell() };
                            RobTarget_Dgv.Columns.Add(dgv[i]);
                            break;
                        case 10:
                            dgv[i] = new DataGridViewButtonColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewButtonCell() };
                            RobTarget_Dgv.Columns.Add(dgv[i]);
                            break;
                        default:
                            dgv[i] = new DataGridViewColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                            RobTarget_Dgv.Columns.Add(dgv[i]);
                            break;
                    }
                }

                for (int i = 0; i < this.RobTarget_Dgv.Columns.Count; i++)
                {
                    this.RobTarget_Dgv.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
                    Datawidth += this.RobTarget_Dgv.Columns[i].Width;  //记录整个DataGridView的宽度
                }
                //判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
                //则将DataGridView的列自动调整模式设置为显示的列即可，
                //如果是小于原来设定的宽度，将模式改为填充。
                if (Datawidth > this.RobTarget_Dgv.Size.Width)
                {
                    this.RobTarget_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
                }
                else
                {
                    this.RobTarget_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
                }
                RobTarget_Dgv.Columns[0].Frozen = true;   //冻结某列 从左开始 0，1，2


                RobTarget_Dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //列头居中
                RobTarget_Dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中            
                RobTarget_Dgv.AllowUserToAddRows = false;  //关闭自动添加行



                for (int i = 0; i < this.DI_Dgv.Columns.Count; i++)
                {
                    this.RobTarget_Dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                }
                for (int i = 1; i < 4; i++)
                {
                    this.RobTarget_Dgv.Columns[i].ReadOnly = true;     //禁止i列单元格编辑
                }
                this.RobTarget_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;

                RapidSymbol[] symbolsNum = W.rapidSymbol(controller, "robtarget");

                for (int i = 0; i < symbolsNum.Length; i++)
                {
                    if (symbolsNum[i].Type.ToString() == "Persistent")
                    {
                        RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                        if (rd.IsArray != true)
                        {
                            RobTarget_Dgv.Rows.Add();
                            RobTarget_Dgv.Rows[i - DataCount].Cells[1].Value = symbolsNum[i].Name;
                            listRobTarget.Add(symbolsNum[i].Name);
                            RobTarget_Dgv.Rows[i - DataCount].Cells[2].Value = symbolsNum[i].Type.ToString();
                            RobTarget_Dgv.Rows[i - DataCount].Cells[3].Value = rd.RapidType;
                            RobTarget rt = (RobTarget)rd.Value;
                            rt.Rot.ToEulerAngles(out rx, out ry, out rz);
                            RobTarget_Dgv.Rows[i - DataCount].Cells[4].Value = rt.Trans.X.ToString(format: "0.00");
                            RobTarget_Dgv.Rows[i - DataCount].Cells[5].Value = rt.Trans.Y.ToString(format: "0.00");
                            RobTarget_Dgv.Rows[i - DataCount].Cells[6].Value = rt.Trans.Z.ToString(format: "0.00");
                            RobTarget_Dgv.Rows[i - DataCount].Cells[7].Value = rz.ToString(format: "0.00");
                            RobTarget_Dgv.Rows[i - DataCount].Cells[8].Value = ry.ToString(format: "0.00");
                            RobTarget_Dgv.Rows[i - DataCount].Cells[9].Value = rx.ToString(format: "0.00");
                            RobTarget_Dgv.Rows[i - DataCount].Cells[10].Value = "修改位置";
                            rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(Rbt_ValueChanged);
                        }
                        else
                        {
                            DataCount++;
                        }
                    }
                    else
                    {
                        DataCount++;
                    }
                }
                for (int i = 0; i < sizeWith.Length; i++)
                {
                    RobTarget_Dgv.Columns[i].Width = sizeWith[i];
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }

        private void Rbt_ValueChanged(object sender, DataValueChangedEventArgs e)  //rbt委托
        {
            this.Invoke(new EventHandler(Rbt_EventHandler), sender, e);
        }

        private void Rbt_EventHandler(object sender, EventArgs e)   //rbt的数据刷新
        {
            RapidData rd1 = (RapidData)sender;
            int b = listRobTarget.IndexOf(rd1.Name);
            if (b != -1)
            {
                RobTarget rt = (RobTarget)rd1.Value;
                RobTarget_Dgv.Rows[b].Cells[4].Value = rt.Trans.X.ToString(format: "0.00");
                RobTarget_Dgv.Rows[b].Cells[5].Value = rt.Trans.Y.ToString(format: "0.00");
                RobTarget_Dgv.Rows[b].Cells[6].Value = rt.Trans.Z.ToString(format: "0.00");
                rt.Rot.ToEulerAngles(out rx, out ry, out rz);
                RobTarget_Dgv.Rows[b].Cells[7].Value = rz.ToString(format: "0.00");
                RobTarget_Dgv.Rows[b].Cells[8].Value = ry.ToString(format: "0.00");
                RobTarget_Dgv.Rows[b].Cells[9].Value = rx.ToString(format: "0.00");
            }
        }

        private void RobTarget_Dgv_CellMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                if (e.ColumnIndex == 10)
                {
                    if ((bool)RobTarget_Dgv.Rows[e.RowIndex].Cells[0].EditedFormattedValue == true)   //判断是否被选中
                    {
                        W.RobTargetDataTwo(controller, RobTarget_Dgv.Rows[e.RowIndex].Cells[1].Value.ToString()); //把大地坐标赋值给点位
                    }
                    else
                    {
                        double RZ = double.Parse(RobTarget_Dgv.Rows[e.RowIndex].Cells[7].Value.ToString());
                        double RY = double.Parse(RobTarget_Dgv.Rows[e.RowIndex].Cells[8].Value.ToString());
                        double RX = double.Parse(RobTarget_Dgv.Rows[e.RowIndex].Cells[9].Value.ToString());
                        W.RobTargetData(controller, RobTarget_Dgv.Rows[e.RowIndex].Cells[1].Value.ToString(), //微调点位
                           RobTarget_Dgv.Rows[e.RowIndex].Cells[4].Value.ToString(),
                           RobTarget_Dgv.Rows[e.RowIndex].Cells[5].Value.ToString(),
                           RobTarget_Dgv.Rows[e.RowIndex].Cells[6].Value.ToString(), RX, RY, RZ);
                    }
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        private void RobTarget_Dgv_CellContentClick(object sender, DataGridViewCellEventArgs e)   //Chebox的事件
        {
            //if (controller == null)
            //{
            //    W.ABBmessage(message_lbo, "请连接控制器");
            //}
            //else if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
            //{
            //    W.ABBmessage(message_lbo, "请切换自动模式");
            //    return;
            //}
            //if (e.ColumnIndex == 0 && e.RowIndex >= 0)
            //{
            //    foreach (DataGridViewRow row in RobTarget_Dgv.Rows)
            //    {
            //        row.Cells[e.ColumnIndex].Value = false;  //只能勾选一个Chebox
            //    }
            //    RobTarget_Dgv.Rows[e.RowIndex].Cells[e.ColumnIndex].Value = true;
            //}
        }
        private void RobTarget_Dgv_CellEndEdit(object sender, DataGridViewCellEventArgs e)  //rbt修改数据
        {



            int colum = e.ColumnIndex;
            if (colum == 0 || colum == 1 || colum == 2 || colum == 3) return;
            int row = e.RowIndex;
            if (RobTarget_Dgv[0, row].Value == null) return;
            string name = RobTarget_Dgv[0, row].Value.ToString();
            string task = RobTarget_Dgv[1, row].Value.ToString();
            string module = RobTarget_Dgv[2, row].Value.ToString();
            float x = Convert.ToSingle(RobTarget_Dgv[4, row].Value);
            float y = Convert.ToSingle(RobTarget_Dgv[5, row].Value);
            float z = Convert.ToSingle(RobTarget_Dgv[6, row].Value);
            float rx = Convert.ToSingle(RobTarget_Dgv[7, row].Value);
            float ry = Convert.ToSingle(RobTarget_Dgv[8, row].Value);
            float rz = Convert.ToSingle(RobTarget_Dgv[9, row].Value);
            RapidData rapidData = controller.Rapid.GetRapidData(task, module, name);
            RobTarget rbt = (RobTarget)rapidData.Value;
            rbt.Trans.X = x;
            rbt.Trans.Y = y;
            rbt.Trans.Z = z;
            rbt.Rot.FillFromEulerAngles(rx, ry, rz);
            try
            {
                using (Mastership.Request(controller.Rapid))
                {
                    rapidData.Value = rbt;
                }
            }
            catch
            {


            }

        }
        private void RobTarget_Dgv_MouseEnter(object sender, EventArgs e)
        {
            this.MouseWheel += RobTarget_MouseWheel;
        }

        private void RobTarget_MouseWheel(object sender, MouseEventArgs e)
        {
            Point p = PointToScreen(e.Location);
            W.dgv_MouseWheel(RobTarget_Dgv, e, p);
        }
        #endregion
        #region //TCP设定/显示速度
        public void ao_speed()
        {
            if (controller.IOSystem.GetSignal("ao_speed") != null)
            {
                Signal sigspeed = controller.IOSystem.GetSignal("ao_speed");
                sigspeed.Changed += new EventHandler<SignalChangedEventArgs>(SignalSpeedEvent);
            }
        }

        private void SignalSpeedEvent(object sender, SignalChangedEventArgs e)
        {
            this.Invoke(new EventHandler(CurToolTcp), sender, e);
        }

        private void CurToolTcp(object sender, EventArgs e)
        {
            Signal sig = (Signal)sender;
            if (sig.Name == "ao_speed")
            {
                userGaugeChart1.Value = Math.Round(sig.Value * 1000);
            }
        }


        #endregion




        public void menubar()
        {
            this.listView3.LargeImageList = this.Max_imageList;
            this.listView3.View = View.LargeIcon;

            string[] str = { "主界面", "变量", "IO", "日志写屏", "传输文件", "机器人选项", "通信" };
            ListViewItem[] item = new ListViewItem[str.Length];

            for (int i = 00; i < item.Length; i++)
            {
                item[i] = new ListViewItem(str[i], i);
                this.listView3.Items.Add(item[i]);
            }
        }
        private void listView3_MouseClick(object sender, MouseEventArgs e)
        {
            try
            {
                int nRow = listView3.Items[listView3.SelectedIndices[0]].Index;
                this.tabControl1.SelectedIndex = nRow;
            }
            catch (Exception)
            {

            }
        }

        private void DO_Dgv_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (DO_Dgv.Columns[e.ColumnIndex] is DataGridViewComboBoxColumn && e.RowIndex != -1)
            {
                SendKeys.Send("{F4}");
            }
        }



        private void DO_Dgv_CellMouseDown(object sender, DataGridViewCellMouseEventArgs e)
        {
            try
            {
                if (e.Button == MouseButtons.Left)
                {
                    if (e.ColumnIndex == 4 && DO_Dgv.Rows[e.RowIndex].Cells[5].FormattedValue.ToString() == "按下/松开")
                    {
                        W.ABBsingal(controller, message_lbo, listDoName[e.RowIndex].ToString(), 1, false);
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        private void DO_Dgv_CellMouseUp(object sender, DataGridViewCellMouseEventArgs e)
        {
            try
            {
                if (e.Button == MouseButtons.Left)
                {
                    if (e.ColumnIndex == 4 && DO_Dgv.Rows[e.RowIndex].Cells[5].FormattedValue.ToString() == "按下/松开")
                    {
                        W.ABBsingal(controller, message_lbo, listDoName[e.RowIndex].ToString(), 0, false);
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        private void DI_Dgv_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (DI_Dgv.Columns[e.ColumnIndex] is DataGridViewComboBoxColumn && e.RowIndex != -1)
            {
                SendKeys.Send("{F4}");
            }

        }

        private void DI_Dgv_CellMouseDown(object sender, DataGridViewCellMouseEventArgs e)
        {
            try
            {
                if (e.Button == MouseButtons.Left)
                {
                    if (e.ColumnIndex == 4 && DI_Dgv.Rows[e.RowIndex].Cells[5].FormattedValue.ToString() == "按下/松开")
                    {
                        W.ABBsingal(controller, message_lbo, ListDiName[e.RowIndex].ToString(), 1, false);
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        private void DI_Dgv_CellMouseUp(object sender, DataGridViewCellMouseEventArgs e)
        {
            try
            {
                if (e.Button == MouseButtons.Left)
                {
                    if (e.ColumnIndex == 4 && DI_Dgv.Rows[e.RowIndex].Cells[5].FormattedValue.ToString() == "按下/松开")
                    {
                        W.ABBsingal(controller, message_lbo, ListDiName[e.RowIndex].ToString(), 0, false);
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        private void DO_Dgv_CellMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            try
            {
                if (e.ColumnIndex == 4)  //第四行触发事件
                {
                    switch (DO_Dgv.Rows[e.RowIndex].Cells[5].FormattedValue.ToString())
                    {
                        case "切换":
                            {
                                if (DO_Dgv.Rows[e.RowIndex].Cells[4].Value == "打开")
                                {
                                    W.ABBsingal(controller, message_lbo, listDoName[e.RowIndex].ToString(), 1, false);
                                }
                                else
                                {
                                    W.ABBsingal(controller, message_lbo, listDoName[e.RowIndex], 0, false);
                                }
                                break;
                            }

                        case "脉冲":
                            {
                                int a = Convert.ToInt32(DO_Dgv.Rows[e.RowIndex].Cells[6].Value);
                                W.ABBsingal(controller, message_lbo, listDoName[e.RowIndex], a, true);
                                break;
                            }

                        case "按下/松开":
                            {
                                return;
                            }
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        private void DI_Dgv_CellMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            //DataGridView.HitTestInfo htf = this.DI_Dgv.HitTest(e.X, e.Y);
            try
            {
                if (e.ColumnIndex == 4)   //只为第4行提供事件触发
                {
                    switch (DI_Dgv.Rows[e.RowIndex].Cells[5].FormattedValue.ToString())
                    {
                        case "切换":
                            {
                                if (DI_Dgv.Rows[e.RowIndex].Cells[4].Value == "打开")
                                {
                                    W.ABBsingal(controller, message_lbo, ListDiName[e.RowIndex].ToString(), 1, false);
                                }
                                else
                                {
                                    W.ABBsingal(controller, message_lbo, ListDiName[e.RowIndex], 0, false);
                                }
                                break;
                            }

                        case "脉冲":
                            {
                                int a = Convert.ToInt32(DI_Dgv.Rows[e.RowIndex].Cells[6].Value);
                                W.ABBsingal(controller, message_lbo, ListDiName[e.RowIndex], a, true);
                                break;
                            }

                        case "按下/松开":
                            {
                                return;
                            }
                    }

                }
            }
            catch (Exception)
            {

            }
        }

        #region    //移动机器人 

        #endregion

        #region //连接控制器右键
        private void 设为主机ToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }


        private void 刷新控制器ToolStripMenuItem_Click(object sender, EventArgs e)
        {

            if (scanner == null)
            {
                scanner = new NetworkScanner();
            }
            scanner.Scan(); //对网络进行扫描
            this.listView1.Items.Clear();   //清空listView1中的内容
            ControllerInfoCollection controls = scanner.Controllers;

            foreach (ControllerInfo info in controls)
            {
                ListViewItem item = new ListViewItem(info.SystemName);
                item.SubItems.Add(info.IPAddress.ToString());
                item.SubItems.Add(info.Version.ToString());
                item.SubItems.Add(info.IsVirtual.ToString());
                item.SubItems.Add(info.ControllerName.ToString());
                item.SubItems.Add(info.SystemId.ToString());
                int a = info.RobApiPort;
                //对逐个添加信息，信息均转化为字符创
                item.Tag = info;
                controllerCount++;
                this.listView1.Items.Add(item);
            }
        }

        private void 断开控制器ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                return;
            }
            listView1.Items[listView1.SelectedIndices[0]].BackColor = Color.White;//选中行变为白色
            this.controller.Logoff();   //注销当前用户。
            this.controller.Dispose();
            this.controller = null;
            W.ABBmessage(message_lbo, "已断开");
        }




        #endregion

        #region //Num/bool数组
        public void DataTypearrayThread()
        {
            Thread th = new Thread(DataTypearray);
            th.IsBackground = true;
            th.Start();
        }

        List<string> listarray = new List<string>();
        public void DataTypearray()
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                string[] DataName = { "数据名称", "存储类型", "数据类型", "值", "修改值", "注释" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Name5" };
                int[] sizeWith = { 200, 120, 80, 80, 80, 250 };
                int Numdata = 0;
                int Datawidth = 0;
                int CountData = 0;
                int Count = 0;
                int arrayCount1 = 0, arrayCount2 = 0, arrayCount3 = 0, arrayCount4 = 0;
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                NumBoolDataArray_Dgb.Columns.Clear();
                for (int i = 0; i < dgv.Length; i++)
                {
                    dgv[i] = new DataGridViewColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                    NumBoolDataArray_Dgb.Columns.Add(dgv[i]);
                }

                NumBoolDataArray_Dgb.AllowUserToAddRows = false;  //关闭自动添加行
                RapidSymbol[] symbolsNum = W.rapidSymbol(controller, "num");
                RapidSymbol[] symbolsBool = W.rapidSymbol(controller, "bool");
                RapidSymbol[] symbolsString = W.rapidSymbol(controller, "string");

                for (int i = 0; i < symbolsNum.Length; i++)  //num类型
                {
                    if (symbolsNum[i].Type.ToString() == "Persistent")
                    {
                        RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                        if (rd.IsArray == true)
                        {
                            ArrayData ad = (ArrayData)rd.Value;
                            switch (ad.Rank) //从1开始获取数组的宽
                            {
                                case 1:
                                    {
                                        for (int a = 0; a < ad.GetLength(0); a++)
                                        {
                                            NumBoolDataArray_Dgb.Rows.Add();  //添加行
                                            NumBoolDataArray_Dgb.Rows[a + Count].Cells[0].Value = $"{rd.Name}[{a + 1}]";      //abb数组从1开始
                                            listarray.Add($"{rd.Name}[{a + 1}]");
                                            NumBoolDataArray_Dgb.Rows[a + Count].Cells[1].Value = symbolsNum[i].Type.ToString();
                                            NumBoolDataArray_Dgb.Rows[a + Count].Cells[2].Value = rd.RapidType;
                                            NumBoolDataArray_Dgb.Rows[a + Count].Cells[3].Value = ad[a].ToString();
                                        }
                                        break;
                                    }
                                case 2:
                                    for (int b = 0; b < ad.GetLength(0); b++)
                                    {
                                        for (int c = 0; c < ad.GetLength(1); c++)
                                        {
                                            NumBoolDataArray_Dgb.Rows.Add();  //添加行
                                            NumBoolDataArray_Dgb.Rows[c + Count + (b * ad.GetLength(1))].Cells[0].Value = $"{rd.Name}[{b + 1},{c + 1}]";
                                            listarray.Add($"{rd.Name}[{b + 1},{c + 1}]");
                                            NumBoolDataArray_Dgb.Rows[c + Count + (b * ad.GetLength(1))].Cells[1].Value = symbolsNum[i].Type.ToString();
                                            NumBoolDataArray_Dgb.Rows[c + Count + (b * ad.GetLength(1))].Cells[2].Value = rd.RapidType;
                                            NumBoolDataArray_Dgb.Rows[c + Count + (b * ad.GetLength(1))].Cells[3].Value = ad[b, c].ToString();
                                        }
                                    }
                                    break;
                                case 3:
                                    for (int b = 0; b < ad.GetLength(0); b++)
                                    {
                                        for (int c = 0; c < ad.GetLength(1); c++)
                                        {
                                            for (int d = 0; d < ad.GetLength(2); d++)
                                            {
                                                NumBoolDataArray_Dgb.Rows.Add();  //添加行
                                                NumBoolDataArray_Dgb.Rows[d + Count + (c * ad.GetLength(2)) + (b * ad.GetLength(1) * ad.GetLength(2))].Cells[0].Value = $"{rd.Name}[{b + 1},{c + 1},{d + 1}]";
                                                listarray.Add($"{rd.Name}[{b + 1},{c + 1},{d + 1}]");
                                                NumBoolDataArray_Dgb.Rows[d + Count + (c * ad.GetLength(2)) + (b * ad.GetLength(1) * ad.GetLength(2))].Cells[1].Value = symbolsNum[i].Type.ToString();
                                                NumBoolDataArray_Dgb.Rows[d + Count + (c * ad.GetLength(2)) + (b * ad.GetLength(1) * ad.GetLength(2))].Cells[2].Value = rd.RapidType;
                                                NumBoolDataArray_Dgb.Rows[d + Count + (c * ad.GetLength(2)) + (b * ad.GetLength(1) * ad.GetLength(2))].Cells[3].Value = ad[b, c, d].ToString();
                                            }
                                        }
                                    }
                                    break;
                            }
                            rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(rdarray_ValueChanged);
                            NumBoolDataArray_Dgb.Rows.Add();  //每增加1个数组空一行
                            listarray.Add(" ");
                            Count = NumBoolDataArray_Dgb.Rows.Count;
                        }
                    }
                }
                for (int i = 0; i < symbolsBool.Length; i++)  //BOOL类型
                {
                    RapidData rd = tasks[0].GetRapidData(symbolsBool[i]);
                    if (symbolsBool[i].Type.ToString() == "Persistent")
                    {
                        if (rd.IsArray == true)
                        {
                            ArrayData ad = (ArrayData)rd.Value;
                            for (int a = 0; a < ad.Length; a++)
                            {
                                NumBoolDataArray_Dgb.Rows.Add();  //添加行
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[0].Value = rd.Name + "[" + (a + 1).ToString() + "]";  //abb数组从1开始
                                listarray.Add(rd.Name + "[" + (a + 1).ToString() + "]");
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[3].Value = ad[a].ToString();
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[1].Value = symbolsBool[i].Type.ToString();
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[2].Value = rd.RapidType;
                            }
                            rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(rdarray_ValueChanged);
                            NumBoolDataArray_Dgb.Rows.Add();  //每增加1个数组空一行
                            listarray.Add(" ");
                            Count = NumBoolDataArray_Dgb.Rows.Count;
                        }

                    }
                }

                for (int i = 0; i < symbolsString.Length; i++)  //String类型
                {
                    RapidData rd = tasks[0].GetRapidData(symbolsString[i]);
                    if (symbolsString[i].Type.ToString() == "Persistent")
                    {
                        if (rd.IsArray == true)
                        {
                            ArrayData ad = (ArrayData)rd.Value;
                            for (int a = 0; a < ad.Length; a++)
                            {
                                NumBoolDataArray_Dgb.Rows.Add();  //添加行
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[0].Value = rd.Name + "[" + (a + 1).ToString() + "]";  //abb数组从1开始
                                listarray.Add(rd.Name + "[" + (a + 1).ToString() + "]");
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[3].Value = ad[a].ToString();
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[1].Value = symbolsString[i].Type.ToString();
                                NumBoolDataArray_Dgb.Rows[a + Count].Cells[2].Value = rd.RapidType;
                            }
                            rd.ValueChanged += new EventHandler<DataValueChangedEventArgs>(rdarray_ValueChanged);
                            NumBoolDataArray_Dgb.Rows.Add();  //每增加1个数组空一行
                            listarray.Add(" ");
                            Count = NumBoolDataArray_Dgb.Rows.Count;
                        }

                    }
                }

                W.ReadDatanote(controller, getSystemId + "-arraydatanote.txt", listarray, NumBoolDataArray_Dgb, 5);//写注释

                for (int i = 0; i < this.NumBoolDataArray_Dgb.Columns.Count; i++)
                {
                    this.NumBoolDataArray_Dgb.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
                    Datawidth += this.NumBoolDataArray_Dgb.Columns[i].Width;  //记录整个DataGridView的宽度
                }
                //判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
                //则将DataGridView的列自动调整模式设置为显示的列即可，
                //如果是小于原来设定的宽度，将模式改为填充。
                if (Datawidth > this.NumBoolDataArray_Dgb.Size.Width)
                {
                    this.NumBoolDataArray_Dgb.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
                }
                else
                {
                    this.NumBoolDataArray_Dgb.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
                }
                this.NumBoolDataArray_Dgb.Columns[0].Frozen = true;   //冻结某列 从左开始 0，1，2

                NumBoolDataArray_Dgb.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头居中
                NumBoolDataArray_Dgb.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中
                this.NumBoolDataArray_Dgb.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
                for (int i = 0; i < 4; i++)
                {
                    this.NumBoolDataArray_Dgb.Columns[i].ReadOnly = true;     //禁止i列单元格编辑
                }

                for (int i = 0; i < NumBoolDataArray_Dgb.Columns.Count; i++)
                {
                    NumBoolDataArray_Dgb.Columns[i].Width = sizeWith[i];
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }

        private void rdarray_ValueChanged(object sender, DataValueChangedEventArgs e)
        {
            this.Invoke(new EventHandler(rdarray_EventHandler), sender, e);
        }

        private void rdarray_EventHandler(object sender, EventArgs e)
        {
            Thread th = new Thread(rdarrayThree);
            th.IsBackground = true;
            th.Start(sender);
        }
        public void rdarrayThree(object sender)
        {
            int[] Count = new int[] { };
            string[] str = new string[] { };
            try
            {
                RapidData rd1 = (RapidData)sender;
                if (rd1.IsArray)
                {
                    ArrayData ad = (ArrayData)rd1.Value;
                    switch (ad.Rank)  //数组的宽度
                    {

                        case 1:  //一位数组的刷新处理
                            Count = new int[ad.GetLength(0)];
                            str = new string[ad.GetLength(0)];
                            for (int i = 0; i < ad.GetLength(0); i++)
                            {
                                Count[i] = listarray.IndexOf($"{rd1.Name}[{i + 1}]");  //拿到单元格的行数
                                str[i] = ad[i].ToString();  //拿到这个新数组的全部值              
                            }
                            for (int z = 0; z < Count.Length; z++)
                            {
                                string CountData = NumBoolDataArray_Dgb[3, Count[z]].Value.ToString();  //单元格的值转换成字符串类型
                                if (CountData != str[z]) //拿到单元格的值，和新的数组进行比较
                                {
                                    //不相等就刷新赋值，相等就跳过
                                    NumBoolDataArray_Dgb[3, Count[z]].Style.BackColor = Color.Green;    //单元格绿色
                                    Thread.Sleep(300);   //停留0.3秒
                                    NumBoolDataArray_Dgb[3, Count[z]].Value = str[z];
                                    NumBoolDataArray_Dgb[3, Count[z]].Style.BackColor = Color.White;  //单元格白色
                                }
                            }
                            break;

                        case 2: //二位数组的刷新处理
                            Count = new int[ad.GetLength(0) * ad.GetLength(1)];
                            str = new string[ad.GetLength(0) * ad.GetLength(1)];
                            for (int i = 0; i < ad.GetLength(0); i++)  //遍历一位数组
                            {
                                for (int c = 0; c < ad.GetLength(1); c++)  //遍历二维数组
                                {
                                    Count[c + (i * ad.GetLength(1))] = listarray.IndexOf($"{rd1.Name}[{i + 1},{c + 1}]");  //拿到单元格的行数
                                    str[c + (i * ad.GetLength(1))] = ad[i, c].ToString();  //拿到这个新数组的全部值
                                }
                            }
                            for (int d = 0; d < Count.Length; d++)
                            {
                                string CountData = NumBoolDataArray_Dgb[3, Count[d]].Value.ToString();
                                if (CountData != str[d])
                                {
                                    NumBoolDataArray_Dgb[3, Count[d]].Style.BackColor = Color.Green;    //单元格绿色                               
                                    NumBoolDataArray_Dgb[3, Count[d]].Value = str[d];
                                    Thread.Sleep(300);   //停留0.3秒
                                    NumBoolDataArray_Dgb[3, Count[d]].Style.BackColor = Color.White;  //单元格白色
                                }
                            }
                            break;

                        case 3:  //三维数组的刷新处理
                            Count = new int[ad.GetLength(0) * ad.GetLength(1) * ad.GetLength(2)];
                            str = new string[ad.GetLength(0) * ad.GetLength(1) * ad.GetLength(2)];
                            for (int i = 0; i < ad.GetLength(0); i++)  //遍历一位数组
                            {
                                for (int c = 0; c < ad.GetLength(1); c++)  //遍历二维数组
                                {
                                    for (int d = 0; d < ad.GetLength(2); d++)  //遍历三维数组
                                    {
                                        Count[d + (c * ad.GetLength(2)) + (i * ad.GetLength(1) * ad.GetLength(2))] =
                                            listarray.IndexOf($"{rd1.Name}[{i + 1},{c + 1},{d + 1}]");  //拿到单元格的行数
                                        str[d + (c * ad.GetLength(2)) + (i * ad.GetLength(1) * ad.GetLength(2))] =
                                            ad[i, c, d].ToString();  //拿到这个新数组的全部值
                                    }
                                }
                            }
                            for (int d = 0; d < Count.Length; d++)
                            {
                                string CountData = NumBoolDataArray_Dgb[3, Count[d]].Value.ToString();
                                if (CountData != str[d])
                                {
                                    NumBoolDataArray_Dgb[3, Count[d]].Style.BackColor = Color.Green;    //单元格绿色                               
                                    NumBoolDataArray_Dgb[3, Count[d]].Value = str[d];
                                    Thread.Sleep(300);   //停留0.3秒
                                    NumBoolDataArray_Dgb[3, Count[d]].Style.BackColor = Color.White;  //单元格白色
                                }
                            }
                            break;

                    }
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }
        private void NumBoolDataArray_Dgb_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
            }
            else if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
            {
                W.ABBmessage(message_lbo, "请切换自动模式");
                return;
            }
            int[] AarratNumber1 = new int[3];
            int[] AarrayNumber = new int[3];
            try
            {
                if (e.ColumnIndex == 4 && NumBoolDataArray_Dgb[4, e.RowIndex].Value != null)
                {
                    if (NumBoolDataArray_Dgb[1, e.RowIndex].Value != null)
                    {
                        string str1 = NumBoolDataArray_Dgb[0, e.RowIndex].Value.ToString();  //单元格转换成字符串
                        int index = str1.IndexOf("[", 0);         //截取"["前的字符创  
                        string ArrayName = str1.Substring(0, index);   //得到数组的名称
                        string ArrayValue = str1.Substring(index, str1.Length - index);   //得到数组的第几位字符创
                        string ArrayNumberStr = ArrayValue.Trim(new char[2] { '[', ']' });   //删除[];
                        string[] strNew = ArrayNumberStr.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries); //字符分割
                        switch (strNew.Length)
                        {
                            case 1:
                                int AaaryNumber = Convert.ToInt32(ArrayNumberStr);  //把string转换int
                                int AaaryNumber1 = AaaryNumber - 1;  //重0开始                       
                                W.ArrayDataWrite(controller, ArrayName, NumBoolDataArray_Dgb[4, e.RowIndex].Value.ToString(),
                                   NumBoolDataArray_Dgb[2, e.RowIndex].Value.ToString(), strNew.Length, AaaryNumber1, 0, 0);
                                W.ABBmessage(message_lbo, ArrayName + ArrayValue + "  已改为:" +
                                    NumBoolDataArray_Dgb[4, e.RowIndex].Value.ToString());
                                NumBoolDataArray_Dgb[4, e.RowIndex].Value = "";  //写入成功清除单元格
                                break;

                            case 2:
                                for (int i = 0; i < strNew.Length; i++)
                                {
                                    AarrayNumber[i] = Convert.ToInt32(strNew[i]);
                                    AarratNumber1[i] = AarrayNumber[i] - 1;

                                }
                                W.ArrayDataWrite(controller, ArrayName, NumBoolDataArray_Dgb[4, e.RowIndex].Value.ToString(),
                           NumBoolDataArray_Dgb[2, e.RowIndex].Value.ToString(), strNew.Length, AarratNumber1[0], AarratNumber1[1], 0);
                                W.ABBmessage(message_lbo, ArrayName + ArrayValue + "  已改为:" +
                                    NumBoolDataArray_Dgb[4, e.RowIndex].Value.ToString());
                                NumBoolDataArray_Dgb[4, e.RowIndex].Value = "";  //写入成功清除单元格
                                break;
                            case 3:
                                for (int i = 0; i < strNew.Length; i++)
                                {
                                    AarrayNumber[i] = Convert.ToInt32(strNew[i]);
                                    AarratNumber1[i] = AarrayNumber[i] - 1;
                                }
                                W.ArrayDataWrite(controller, ArrayName, NumBoolDataArray_Dgb[4, e.RowIndex].Value.ToString(),
                                    NumBoolDataArray_Dgb[2, e.RowIndex].Value.ToString(), strNew.Length,
                                    AarratNumber1[0], AarratNumber1[1], AarratNumber1[2]);
                                W.ABBmessage(message_lbo, ArrayName + ArrayValue + "  已改为:" +
                                    NumBoolDataArray_Dgb[4, e.RowIndex].Value.ToString());
                                NumBoolDataArray_Dgb[4, e.RowIndex].Value = "";  //写入成功清除单元格
                                break;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }


        private void NumBoolDataArray_Dgb_MouseEnter(object sender, EventArgs e)
        {

            this.MouseWheel += dgv_MouseWheel;
        }

        private void dgv_MouseWheel(object sender, MouseEventArgs e)
        {
            Point p = PointToScreen(e.Location);
            W.dgv_MouseWheel(NumBoolDataArray_Dgb, e, p);
        }

        #endregion

        #region //添加Rapid指令
        string ReadRapid = "";
        private void MoveLoffs_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        MoveL Offs({robtarget_cbo.SelectedItem},0,0,0),v2000,z50,{tooldata_cbo.SelectedItem}\\WObj:={wobjdata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void movejoffs_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"         MoveJ Offs({robtarget_cbo.SelectedItem},0,0,0),v2000,z50,{tooldata_cbo.SelectedItem}\\WObj:={wobjdata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void MoveLRelTool_Click(object sender, EventArgs e)
        {
            ReadRapid = $"      MoveL RelTool({robtarget_cbo.SelectedItem},0,0,0),v2000,z50,{tooldata_cbo.SelectedItem}\\WObj:={wobjdata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void MoveJRelTool_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        MoveJ RelTool({robtarget_cbo.SelectedItem},0,0,0),v2000,z50,{tooldata_cbo.SelectedItem}\\WObj:={wobjdata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void MoveAbsj_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        MoveAbsJ {jointtarget_cbo.SelectedItem}\\NoEOffs, v1000, z50, {tooldata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void Set_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        Set {Do_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void Reset_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        Reset {Do_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void PulseDO_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        PulseDO\\PLength:=1, {Do_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void WaitDI_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        WaitDI {Di_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void WaitDo_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        WaitDo {Do_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void WaitTime_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = "        WaitTime 1;";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void IF_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = "    IF <EXP> THEN";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 1, " ");
            ReadRapid = "        <EXP>";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 1].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 2, " ");
            ReadRapid = "    ENDIF";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 2].Value = ReadRapid;
        }


        private void FOR_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = "    FOR <ID> FROM <EXP> TO <EXP> DO";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 1, " ");
            ReadRapid = "        <EXP>";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 1].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 2, " ");
            ReadRapid = "    ENDFOR";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 2].Value = ReadRapid;
        }

        private void WHILE_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = "    WHILE <EXP> DO";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 1, " ");
            ReadRapid = "        <EXP>";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 1].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 2, " ");
            ReadRapid = "    ENDWHILE";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 2].Value = ReadRapid;
        }

        private void TEST_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = "    TEST <EXP>";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 1, " ");
            ReadRapid = "    CASE <EXP>:";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 1].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 2, " ");
            ReadRapid = "       <SMT>";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 2].Value = ReadRapid;
            ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex + 3, " ");
            ReadRapid = "    ENDTEST";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex + 3].Value = ReadRapid;
        }

        private void MoveL_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        MoveL {robtarget_cbo.SelectedItem}, v1000, z50, {tooldata_cbo.SelectedItem}\\WObj:={wobjdata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }
        private void MoveJ_btn_Click(object sender, EventArgs e)
        {
            ReadRapid = $"        MoveJ {robtarget_cbo.SelectedItem}, v1000, z50, {tooldata_cbo.SelectedItem}\\WObj:={wobjdata_cbo.SelectedItem};";
            ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex].Value = ReadRapid;
        }

        private void ShowRapid_dgv_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            try
            {
                if (e.ColumnIndex == 1)
                {
                    if (ShowRapid_dgv[e.ColumnIndex, e.RowIndex].Value == null)
                    {
                        return;
                    }
                    string str = ShowRapid_dgv[e.ColumnIndex, e.RowIndex].Value.ToString();
                    if (str.Length <= 6)
                    {
                        ShowRapid_dgv[e.ColumnIndex, e.RowIndex].Value = "       " + ShowRapid_dgv[e.ColumnIndex, e.RowIndex].Value;
                        return;
                    }
                    string str2 = str.Substring(0, 6);
                    if (str2 != "      ")
                    {
                        ShowRapid_dgv[e.ColumnIndex, e.RowIndex].Value = "       " + ShowRapid_dgv[e.ColumnIndex, e.RowIndex].Value;
                    }
                    else
                    {
                        return;
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        public void RDataTypeThree()
        {
            Thread th = new Thread(RDataType);
            th.IsBackground = true;
            th.Start();
        }

        private void ShowRapid_dgv_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                char KeyDel = e.KeyChar;
                char KeyChar = e.KeyChar;
                if (KeyChar == (char)Keys.Enter)
                {
                    ShowRapid_dgv.Rows.Insert(ShowRapid_dgv.CurrentCell.RowIndex, "");
                    ShowRapid_dgv.CurrentCell = ShowRapid_dgv[1, ShowRapid_dgv.CurrentCell.RowIndex - 1];
                }

                if (KeyDel == (char)Keys.End)
                {
                    ShowRapid_dgv.Rows.RemoveAt(ShowRapid_dgv.CurrentCell.RowIndex);
                }
            }
            catch (Exception)
            {
                throw;
            }
        }

        public void RDataType()
        {
            try
            {
                if (controller == null)
                {
                    return;
                }
                robtarget_cbo.Items.Clear();
                tooldata_cbo.Items.Clear();
                wobjdata_cbo.Items.Clear();
                jointtarget_cbo.Items.Clear();
                Do_cbo.Items.Clear();
                Di_cbo.Items.Clear();
                RapidSymbol[] robtargetSymbol = W.rapidSymbol(controller, "robtarget");
                RapidSymbol[] tooldataSymbol = W.rapidSymbol(controller, "tooldata");
                RapidSymbol[] wobjdataSymbol = W.rapidSymbol(controller, "wobjdata");
                RapidSymbol[] JointTargetSymbol = W.rapidSymbol(controller, "JointTarget");
                SignalCollection DoSignal = controller.IOSystem.GetSignals(IOFilterTypes.Output, IODevNet_cmo.SelectedItem.ToString());
                SignalCollection DiSignal = controller.IOSystem.GetSignals(IOFilterTypes.Input, IODevNet_cmo.SelectedItem.ToString());
                foreach (RapidSymbol item in robtargetSymbol)
                {
                    RapidData rd = tasks[0].GetRapidData(item);
                    robtarget_cbo.Items.Add(rd.Name);
                }
                foreach (RapidSymbol item in tooldataSymbol)
                {
                    RapidData rd = tasks[0].GetRapidData(item);
                    tooldata_cbo.Items.Add(rd.Name);
                }
                foreach (RapidSymbol item in wobjdataSymbol)
                {
                    RapidData rd = tasks[0].GetRapidData(item);
                    wobjdata_cbo.Items.Add(rd.Name);
                }
                foreach (RapidSymbol item in JointTargetSymbol)
                {
                    RapidData rd = tasks[0].GetRapidData(item);
                    jointtarget_cbo.Items.Add(rd.Name);
                }
                foreach (Signal item in DoSignal)
                {
                    if (item.Unit == IODevNet_cmo.SelectedItem.ToString())
                    {
                        Do_cbo.Items.Add(item.Name);
                    }
                }
                foreach (Signal item in DiSignal)
                {
                    if (item.Unit == IODevNet_cmo.SelectedItem.ToString())
                    {
                        Di_cbo.Items.Add(item.Name);
                    }
                }
                if (jointtarget_cbo.SelectedItem == null)
                {
                    jointtarget_cbo.Items.Add("<SMT>");
                }
                if (robtarget_cbo == null)
                {
                    robtarget_cbo.Items.Add("<SMT>");
                }
                if (Do_cbo == null)
                {
                    Do_cbo.Items.Add("<SMT>");
                }
                if (Di_cbo == null)
                {
                    Di_cbo.Items.Add("<SMT>");
                }
                robtarget_cbo.SelectedIndex = 0;
                tooldata_cbo.SelectedIndex = 0;
                wobjdata_cbo.SelectedIndex = 0;
                jointtarget_cbo.SelectedIndex = 0;
                Do_cbo.SelectedIndex = 0;
                Di_cbo.SelectedIndex = 0;
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.ToString());
            }
        }




        #endregion

        #region //检查Rapid程序是否有错误
        private void Rapiderror_btn_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            if (controller.OperatingMode != ControllerOperatingMode.Auto)  //判断机器人模式
            {
                W.ABBmessage(message_lbo, "请切换自动模式");
                return;
            }
            W.RapidError(controller, tasks[0]);
            W.ABBmessage(message_lbo, "程序正确");
        }


        #endregion

        #region   //速度调整
        private void trackBar1_Scroll(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            if (controller.OperatingMode == ControllerOperatingMode.Auto)  //判断机器人模式
            {
                label12.Text = trackBar1.Value.ToString() + "%";
                controller.MotionSystem.SpeedRatio = Convert.ToInt32(trackBar1.Value);
                label_speedratio.Text = "机器人速度:" + controller.MotionSystem.SpeedRatio.ToString() + "%";
            }
            else
            {
                W.ABBmessage(message_lbo, "请切换自动模式");
                return;
            }
            W.ABBmessage(message_lbo, "机器人速度:" + controller.MotionSystem.SpeedRatio.ToString() + "%");
        }

        #endregion

        #region //重启软件
        private void button1_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("设置保存成功，下次启动时生效，是否马上重启软件？", "提示", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
            {
                Application.Exit();
                System.Diagnostics.Process.Start(System.Reflection.Assembly.GetExecutingAssembly().Location);
            }
        }
        #endregion    

        #region //机器人选项
        public void ABBmessage()
        {
            try
            {
                listView2.Items.Clear();
                ConfigurationDatabase cfg = controller.Configuration;
                ListViewItem item = null;

                for (int i = 1; i < 7; i++)
                {
                    try
                    {
                        item = new ListViewItem(i.ToString());
                        string[] path = { "MOC", "ARM", "rob1_", "upper_joint_bound" };
                        //各轴名称为rob1_1等
                        path[2] = path[2] + i.ToString();
                        string data = cfg.Read(path);
                        item.SubItems.Add((Convert.ToDouble(data) / Math.PI * 180).ToString("f2"));
                        //将弧度转化为角度
                        path[3] = "lower_joint_bound";
                        //读取下限位置
                        data = cfg.Read(path);
                        item.SubItems.Add((Convert.ToDouble(data) / Math.PI * 180).ToString("f2"));
                        this.listView2.Items.Add(item);
                    }
                    catch
                    {
                        continue;
                    }
                }
                this.listView2.GridLines = true;



                RobotWareOptionCollection rwop = controller.RobotWare.Options;
                //获取当前系统的所有选项信息
                text_Info.Items.Clear();
                foreach (RobotWareOption op in rwop)
                {
                    text_Info.Items.Add("option:" + "  " + op.ToString() + "\r\n");
                    //遍历所有选项信息并将其显示
                }

                MechanicalUnitServiceInfo m = controller.MotionSystem.ActiveMechanicalUnit.ServiceInfo;
                txt_service.Items.Add("生产总时间" + m.ElapsedProductionTime.TotalHours.ToString() + "小时\r\n");
                txt_service.Items.Add("自上次服务后的生产总时间：" + m.ElapsedProductionTimeSinceLastService.TotalHours.ToString() + "小时\r\n");
                txt_service.Items.Add("上次开机：" + m.LastStart.ToString());
                if (isVirtual)
                {
                    MainComputerServiceInfo m1 = controller.MainComputerServiceInfo;
                    txt_service.Items.Add("主机CPU温度" + m1.Temperature.ToString() + "°\r\n");
                    txt_service.Items.Add("主机CPU信息" + m1.CpuInfo.ToString() + "\r\n");
                    txt_service.Items.Add("主机储存" + m1.RamSize.ToString() + "\r\n");
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
        #endregion

        #region  //ABB队列
        //declarations
        private Controller c;
        private IpcQueue tRob1Queue;
        private IpcQueue myQueue;
        private IpcMessage sendMessage;
        private IpcMessage recMessage;
        //initiation code, eg in constructor

        public void ABBRmqType()
        {

            //int a = controller.Ipc.GetQueueId("PC_SDK_BZ");
            controller.Ipc.DeleteQueue(controller.Ipc.GetQueueId("PC_SDK_BZ"));
            // IpcQueue[] ipc = controller.Ipc.Queues;
            tRob1Queue = controller.Ipc.GetQueue("RMQ_T_ROB1");
            //创建我自己的PC SDK队列来接收消息
            if (!controller.Ipc.Exists("RAB_Q"))
            {
                myQueue = controller.Ipc.CreateQueue("PC_SDK_BZ", 5, Ipc.IPC_MAXMSGSIZE);
                myQueue = controller.Ipc.GetQueue("PC_SDK_BZ");
            }
            //创建用于发送和接收的IpcMessage对象  
            sendMessage = new IpcMessage();
            recMessage = new IpcMessage();
            //在事件处理程序中，例如。 button_Click  
            SendMessage(true);
            CheckReturnMsg();
        }


        private void SendMessage(bool boolMsg)
        {
            System.Byte[] data = null;
            //创建消息数据
            if (boolMsg)
            {
                data = new UTF8Encoding().GetBytes("bool;TRUE");
            }
            else
            {
                data = new UTF8Encoding().GetBytes("bool;FALSE");
            }
            //在消息中放置数据和发送者信息
            sendMessage.SetData(data);
            sendMessage.Sender = myQueue.QueueId;
            //将消息发送到RAPID队列
            tRob1Queue.Send(sendMessage);
        }
        private void CheckReturnMsg()
        {
            IpcReturnType ret = IpcReturnType.Timeout;
            string answer = string.Empty;
            int timeout = 5000;
            //检查PC SDK队列中的msg
            ret = myQueue.Receive(timeout, recMessage);
            if (ret == IpcReturnType.OK)
            {
                //将MSG数据转换为字符串
                answer = new UTF8Encoding().GetString(recMessage.Data);
                MessageBox.Show(answer);
                //MessageBox应该显示:字符串; “承认”  
            }
            else
            {
                MessageBox.Show("Timeout!");
            }
        }


        #endregion

        #region //上位机日志放大缩小
        private void message_lbo_MouseEnter(object sender, EventArgs e)
        {
            //message_lbo.Size = new Size(572, 400);
        }

        private void message_lbo_MouseLeave(object sender, EventArgs e)
        {
            // message_lbo.Size = new Size(572, 99);
        }

        #endregion

        #region //socket通信
        Socket socketSend;

        private void confirm_btn_Click(object sender, EventArgs e)
        {
            try
            {
                if (TCP_cbo.SelectedItem.ToString() == "客户端")
                {
                    if (confirm_btn.Text == "连接")
                    {
                        TCP_cbo.Enabled = false;
                        IPadress_txb.Enabled = false;  //IP地址只读
                        Portadress_txb.Enabled = false;  //端口地址只读
                        cboUsers1.Enabled = false;

                        socketSend = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                        //创建负责通信的socket
                        IPAddress ip = IPAddress.Parse(IPadress_txb.Text);
                        IPEndPoint point = new IPEndPoint(ip, Convert.ToInt32(Portadress_txb.Text));
                        socketSend.Connect(point);
                        ShowMsg("连接成功", "");

                        Thread th = new Thread(Recive);
                        th.IsBackground = true;
                        th.Start();
                    }
                    else
                    {
                        IPadress_txb.Enabled = false;  //IP地址只读
                        Portadress_txb.Enabled = false;  //端口地址只读
                        confirm_btn.Text = "连接";
                        socketSend.Shutdown(SocketShutdown.Both);
                        socketSend.Close();
                        W.ABBmessage(message_lbo, "连接断开");
                        socketSend = null;  //断开socket
                    }
                }
                else if (TCP_cbo.SelectedItem.ToString() == "服务器")
                {
                    if (confirm_btn.Text == "开始监听")
                    {
                        cboUsers1.Enabled = true;
                        IPadress_txb.Enabled = false;  //IP地址只读
                        Portadress_txb.Enabled = false;  //端口地址只读
                        TCP_cbo.Enabled = false;

                        //当点击开始监听的时候在服务器端创建一个负责监听IP地址端口号
                        socketSend = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                        IPAddress ip = IPAddress.Parse(IPadress_txb.Text);
                        //创建端口号对象
                        IPEndPoint point = new IPEndPoint(ip, Convert.ToInt32(Portadress_txb.Text));
                        //监听
                        socketSend.Bind(point);
                        ShowMsg("监听成功", "");
                        socketSend.Listen(10);   //监听队列最多可以连10个

                        Thread th = new Thread(Listen);  //开一个新线程不然卡死
                        th.IsBackground = true;
                        th.Start(socketSend);
                    }
                    else
                    {
                        TCP_cbo.Enabled = true;
                        IPadress_txb.Enabled = true;  //IP地址只读
                        Portadress_txb.Enabled = true;  //端口地址只读
                        confirm_btn.Text = "开始监听";
                        socketSend.Shutdown(SocketShutdown.Both);
                        socketSend.Close();
                        W.ABBmessage(message_lbo, "连接断开");
                        socketSend = null;  //断开socket
                    }
                }
                else
                {
                    W.ABBmessage(message_lbo, "请选择协议");
                }
            }

            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        Dictionary<string, Socket> dicSocket = new Dictionary<string, Socket>();
        private void Listen(object o)   //服务器接受信息
        {
            Socket socketwatch = o as Socket;  //一直等待客户端的链接，需要开一个线程
            while (true)
            {
                socketSend = socketwatch.Accept();
                //将远程连接的客户端的IP地址和socket存入集合中
                dicSocket.Add(socketSend.RemoteEndPoint.ToString(), socketSend);
                cboUsers1.Items.Add(socketSend.RemoteEndPoint.ToString());
                ShowMsg(socketSend.RemoteEndPoint.ToString() + " : " + "链接成功", "");

                Thread th = new Thread(ServerRecive);  //开一个新线程不断的接受客户端的信息
                th.IsBackground = true;
                th.Start(socketSend);
            }
        }

        private void ServerRecive(object o)
        {
            while (true)
            {
                try
                {
                    //客户端连接成功后，服务器应该接受客户端发来的消息
                    socketSend = o as Socket;
                    byte[] buffer = new byte[1024 * 1024 * 2];
                    int r = socketSend.Receive(buffer);   //把收到的字节数据赋值给r

                    if (r == 0)
                    {
                        break;
                    }
                    string str = Encoding.UTF8.GetString(buffer, 0, r);
                    if (open == true)
                    {
                        if (interval_cbo.SelectedItem.ToString()[0] == null)
                        {
                            W.ABBmessage(message_lbo, "请选择间隔符");
                            return;
                        }
                        string[] strNew = str.Split(new char[] { interval_cbo.SelectedItem.ToString()[0] }, StringSplitOptions.RemoveEmptyEntries);
                        for (int i = 0; i < strNew.Length; i++)
                        {
                            switch (DataType_cbo.SelectedItem.ToString())
                            {
                                case "num":
                                    W.ArrayDataWrite(controller, DataName_cbo.SelectedItem.ToString(), strNew[i], "num", 1, i, 0, 0);
                                    break;
                                case "bool":
                                    W.ArrayDataWrite(controller, DataName_cbo.SelectedItem.ToString(), strNew[i], "bool", 1, i, 0, 0);
                                    break;
                                case "string":
                                    strNew[i] = $"\"{strNew[i]}\"";
                                    W.ArrayDataWrite(controller, DataName_cbo.SelectedItem.ToString(), strNew[i], "string", 1, i, 0, 0);
                                    break;
                            }
                        }
                    }
                    ShowMsg(str, " ");

                }
                catch
                {

                }

            }
        }

        string Recivestring = "";
        private void Recive()  //客户端接受信息
        {
            while (true)
            {
                try
                {
                    if (socketSend == null)
                    {
                        return;
                    }
                    byte[] buffer = new byte[1024 * 1024 * 2];
                    //实际接受的有效字节数                 
                    int r = socketSend.Receive(buffer);
                    if (r == 0)
                    {

                        break;
                    }
                    Recivestring = Encoding.UTF8.GetString(buffer, 0, r);
                    if (open == true)
                    {
                        if (interval_cbo.SelectedItem.ToString()[0] == null)
                        {
                            W.ABBmessage(message_lbo, "请选择间隔符");
                            return;
                        }
                        string[] strNew = Recivestring.Split(new char[] { interval_cbo.SelectedItem.ToString()[0] }, StringSplitOptions.RemoveEmptyEntries);
                        for (int i = 0; i < strNew.Length; i++)
                        {
                            switch (DataType_cbo.SelectedItem.ToString())
                            {
                                case "num":
                                    W.ArrayDataWrite(controller, DataName_cbo.SelectedItem.ToString(), strNew[i], "num", 1, i, 0, 0);
                                    break;
                                case "bool":
                                    W.ArrayDataWrite(controller, DataName_cbo.SelectedItem.ToString(), strNew[i], "bool", 1, i, 0, 0);
                                    break;
                                case "string":
                                    strNew[i] = $"\"{strNew[i]}\"";
                                    W.ArrayDataWrite(controller, DataName_cbo.SelectedItem.ToString(), strNew[i], "string", 1, i, 0, 0);
                                    break;
                            }
                        }
                    }
                    ShowMsg(Recivestring, " ");
                }
                catch (Exception ex)
                {
                    W.ABBmessage(message_lbo, ex.Message);
                }

            }
        }

        private void sned_txt_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {

                char KeyChar = e.KeyChar;
                if (KeyChar == (char)Keys.Enter)
                {
                    if (socketSend == null)
                    {
                        W.ABBmessage(message_lbo, "连接已断开");
                        return;
                    }
                    string str = sned_txt.Text.Trim();
                    byte[] buffer = System.Text.Encoding.UTF8.GetBytes(str);
                    if (TCP_cbo.SelectedItem.ToString() == "客户端")
                    {
                        socketSend.Send(buffer);
                        ShowMsg(str, "ABB上位机");
                    }
                    else if (TCP_cbo.SelectedItem.ToString() == "服务器")
                    {
                        string ip = cboUsers1.SelectedItem.ToString();
                        if (ip == "All Connections")
                        {
                            for (int i = 1; i < cboUsers1.Items.Count; i++)
                            {
                                string stritem = cboUsers1.Items[i].ToString();
                                dicSocket[stritem].Send(buffer);
                                ShowMsg(str, "ABB上位机");
                            }
                        }
                        else
                        {
                            dicSocket[ip].Send(buffer);
                        }
                    }
                    sned_txt.Clear();
                    sned_txt.Focus();
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, "请连接服务端");
            }
        }

        public void ShowMsg(string str, string Name)
        {
            DateTime dt = DateTime.Now;
            message_lbx.Items.Add(dt.ToLocalTime().ToString() + " " + Name);
            message_lbx.Items.Add(str);
            message_lbx.Items.Add(" ");
            confirm_btn.Text = "断开";
            message_lbx.TopIndex = message_lbx.Items.Count - 1;   //进行全选
        }
        private void DataType_cbo_SelectedIndexChanged(object sender, EventArgs e)
        {
            Thread th = new Thread(SocketDataName);
            th.IsBackground = true;
            th.Start();
        }
        public void SocketDataName()
        {
            if (open == true && controller == null)
            {
                W.ABBmessage(message_lbo, "请打开ABB接受数据");
                return;
            }
            DataName_cbo.Items.Clear();
            RapidSymbol[] symbolsNum = new RapidSymbol[] { };
            switch (DataType_cbo.SelectedItem.ToString())
            {
                case "num":
                    {
                        symbolsNum = W.rapidSymbol(controller, "num");
                        break;
                    }
                case "bool":
                    {
                        symbolsNum = W.rapidSymbol(controller, "bool");
                        break;
                    }
                case "string":
                    {
                        symbolsNum = W.rapidSymbol(controller, "string");
                        break;
                    }
            }
            for (int i = 0; i < symbolsNum.Length; i++)
            {
                if (symbolsNum[i].Type.ToString() == "Persistent")
                {
                    RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                    if (rd.IsArray == true)  //只获取一位数组
                    {
                        ArrayData ad = (ArrayData)rd.Value;
                        if (ad.Rank == 1)
                        {
                            DataName_cbo.Items.Add(rd.Name);
                        }
                    }
                }
            }
        }

        private void SendDataType_cbo_SelectedIndexChanged(object sender, EventArgs e)
        {
            Thread th = new Thread(SocketSendName);
            th.IsBackground = true;
            th.Start();
        }

        private void SocketSendName()
        {
            if (Seropen == true && controller == null)
            {
                W.ABBmessage(message_lbo, "请打开ABB接受数据");
                return;
            }
            SendDataName_cbo.Items.Clear();
            RapidSymbol[] symbolsNum = W.rapidSymbol(controller, "string");

            for (int i = 0; i < symbolsNum.Length; i++)
            {
                if (symbolsNum[i].Type.ToString() == "Persistent")
                {
                    RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                    if (rd.IsArray != true)  //只获取一位数组
                    {
                        SendDataName_cbo.Items.Add(rd.Name);
                    }
                }
            }
        }
        bool Tcp = false;

        private void TCP_cbo_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (TCP_cbo.SelectedItem.ToString() == "服务器")
            {
                confirm_btn.Text = "开始监听";
            }
            else
            {
                confirm_btn.Text = "连接";
            }
        }

        bool open = false;
        private void Open_btn_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            if (Open_btn.Text == "ABB接受数据")
            {
                Open_btn.Text = "ABB不接收数据";
                DataType_cbo.Items.AddRange(new string[] { "string", "num", "bool" });
                interval_cbo.Items.AddRange(new string[] { ",", "/" });
                SendDataType_cbo.Items.Add("string");
                SendDataType_cbo.SelectedIndex = 0;
                DataType_cbo.SelectedIndex = 0;
                open = true;
            }
            else
            {
                Open_btn.Text = "ABB接受数据";
                DataType_cbo.Items.Clear();
                interval_cbo.Items.Clear();
                DataName_cbo.Items.Clear();
                interval_cbo.Text = "";
                open = false;
            }
        }


        #endregion

        #region //串口通信
        public bool isopen = false;
        public bool isRxShow = true;

        public List<byte> reciveBuffer = new List<byte>();
        public List<byte> sendBuffer = new List<byte>();

        public int reciveCount = 0;
        public int sendCount = 0;

        string strRead;



        public void seriaLoad()
        {
            try
            {
                RegistryKey keyCom = Registry.LocalMachine.OpenSubKey(@"Hardware\DeviceMap\SerialComm");  //获取注册列表中的COM口
                if (keyCom == null)
                {
                    return;
                }
                EncodingInfo[] encodingInfos = Encoding.GetEncodings();
                string[] sSubkeys = keyCom.GetValueNames();
                string[] getsSubkeys = new string[sSubkeys.Length];
                if (sSubkeys == null)
                {
                    return;
                }
                port_cbb.Items.Clear();
                for (int i = 0; i < sSubkeys.Length; i++)
                {
                    getsSubkeys[i] = keyCom.GetValue(sSubkeys[i]).ToString(); //把搜索到的COM口赋值给字符串
                }
                port_cbb.Items.AddRange(getsSubkeys.Distinct().ToArray());  //删除字符串数组重复的元素;      
                this.port_cbb.SelectedIndex = 1;
                this.baud_cbb.SelectedIndex = 1;
                this.check_cbb.SelectedIndex = 0;
                this.databit_cbb.SelectedIndex = 3;
                this.stopbit_cbb.SelectedIndex = 0;
            }
            catch
            {

            }
        }

        private void send_rtb_KeyPress(object sender, KeyPressEventArgs e)
        {
            char KeyChar = e.KeyChar;
            if (KeyChar == (char)Keys.Enter)
            {
                if (this.send_rtb.Text != "" && serialPort1.IsOpen)
                {
                    Console.WriteLine(Transform.ToHexString(sendBuffer.ToArray()));
                    sendData();
                    send_rtb.Clear();
                    //recive_rtb.Items.Clear();
                    //send_rtb.Text.Trim();
                    //serialPort1.Write(send_rtb.Text);     //发送COM数据
                }
                else
                {
                    MessageBox.Show("请先输入发送数据！");
                }
            }
        }
        public void sendData()
        {
            //serialPort1.Write(sendBuffer.ToArray(), 0, sendBuffer.Count);
            serialPort1.Write(send_rtb.Text.Trim());
            SerShowMsg(send_rtb.Text, "ABB上位机");
            //recive_rtb.Items.Add(send_rtb.Text);
            sendCount += sendBuffer.Count();
        }

        private void send_rtb_Leave(object sender, EventArgs e)
        {
            if (sendhex_chb.CheckState == CheckState.Checked)
            {
                if (sendhex_chb.CheckState == CheckState.Checked)
                {
                    sendBuffer.Clear();
                    sendBuffer.AddRange(Transform.ToBytes(send_rtb.Text.Replace(" ", "")));
                }
                else
                {
                    MessageBox.Show("请输入正确的十六进制数据!!");
                    send_rtb.Select();
                }
            }
            else
            {
                sendBuffer.Clear();
                sendBuffer.AddRange(Encoding.GetEncoding("gb2312").GetBytes(send_rtb.Text));
            }
        }

        private void send_rtb_TextChanged(object sender, EventArgs e)
        {
            //十六进制切换 会出现问题 这问题是0×00；
        }

        private void DTR_chb_CheckedChanged(object sender, EventArgs e)
        {
            if (DTR_chb.CheckState == CheckState.Checked)
            {
                serialPort1.DtrEnable = true;
            }
            else
            {
                serialPort1.DtrEnable = false;
            }
        }

        private void RTS_chb_CheckedChanged(object sender, EventArgs e)
        {
            if (RTS_chb.CheckState == CheckState.Checked)
            {
                serialPort1.RtsEnable = true;
            }
            else
            {
                serialPort1.RtsEnable = false;
            }
        }

        private void openSp_btn_Click(object sender, EventArgs e)
        {
            try
            {
                if (serialPort1.IsOpen == false)
                {
                    serialPort1.PortName = port_cbb.SelectedItem.ToString();
                    serialPort1.BaudRate = Convert.ToInt32(baud_cbb.SelectedItem.ToString());
                    serialPort1.DataBits = Convert.ToInt32(databit_cbb.SelectedItem.ToString());
                    switch (check_cbb.SelectedIndex)
                    {
                        // none odd even
                        case 0:
                            serialPort1.Parity = Parity.None;
                            break;
                        case 1:
                            serialPort1.Parity = Parity.Odd;
                            break;
                        case 2:
                            serialPort1.Parity = Parity.Even;
                            break;
                        default:
                            serialPort1.Parity = Parity.None;
                            break;
                    }

                    switch (stopbit_cbb.SelectedIndex)
                    {
                        // 1 1.5 2
                        case 0:
                            serialPort1.StopBits = StopBits.One;
                            break;
                        case 1:
                            serialPort1.StopBits = StopBits.OnePointFive;
                            break;
                        case 2:
                            serialPort1.StopBits = StopBits.Two;
                            break;
                        default:
                            serialPort1.StopBits = StopBits.One;
                            break;
                    }
                    serialPort1.Open();
                    isopen = true;
                    openSp_btn.Text = "关闭串口";
                    //state_tssl.Text = $"关闭{serialPort1.PortName}窗口成功!";


                }
                else
                {
                    serialPort1.Close();
                    isopen = false;
                    openSp_btn.Text = "打开串口";
                    //state_tssl.Text = $"打开{serialPort1.PortName}窗口成功!";
                }

            }
            catch (Exception ex)
            {
                //state_tssl.Text = $"打开{serialPort1.PortName}串口异常!";
                MessageBox.Show(ex.ToString() + serialPort1.PortName.ToString());
            }
        }

        private void ReciveSerType_cbb_SelectedIndexChanged(object sender, EventArgs e)
        {
            Thread th = new Thread(serialPortDataName);
            th.IsBackground = true;
            th.Start();
        }

        private void serialPortDataName()
        {
            if (Seropen == true && controller == null)
            {
                W.ABBmessage(message_lbo, "请打开串口");
                return;
            }
            ReciveSerName_cbb.Items.Clear();
            RapidSymbol[] symbolsNum = new RapidSymbol[] { };
            switch (ReciveSerType_cbb.SelectedItem.ToString())
            {
                case "num":
                    {
                        symbolsNum = W.rapidSymbol(controller, "num");
                        break;
                    }
                case "bool":
                    {
                        symbolsNum = W.rapidSymbol(controller, "bool");
                        break;
                    }
                case "string":
                    {
                        symbolsNum = W.rapidSymbol(controller, "string");
                        break;
                    }
            }
            for (int i = 0; i < symbolsNum.Length; i++)
            {
                if (symbolsNum[i].Type.ToString() == "Persistent")
                {
                    RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                    if (rd.IsArray == true)  //只获取一位数组
                    {
                        ArrayData ad = (ArrayData)rd.Value;
                        if (ad.Rank == 1)
                        {
                            ReciveSerName_cbb.Items.Add(rd.Name);
                        }
                    }
                }
            }
        }
        bool Seropen = false;
        private void OpenSer_btn_Click(object sender, EventArgs e)
        {
            if (controller == null)
            {
                W.ABBmessage(message_lbo, "请连接控制器");
                return;
            }
            if (OpenSer_btn.Text == "ABB接受数据")
            {
                OpenSer_btn.Text = "ABB不接收数据";
                ReciveSerType_cbb.Items.AddRange(new string[] { "string", "num", "bool" });
                intervalSer_cbb.Items.AddRange(new string[] { ",", "/" });
                SendType_cbb.Items.Add("string");
                SendType_cbb.SelectedIndex = 0;
                ReciveSerType_cbb.SelectedIndex = 0;
                Seropen = true;
            }
            else
            {
                OpenSer_btn.Text = "ABB接受数据";
                ReciveSerType_cbb.Items.Clear();
                intervalSer_cbb.Items.Clear();
                ReciveSerType_cbb.Items.Clear();
                //intervalSer_cbb.Text = "";
                Seropen = false;
            }
        }

        private void SerialPortSendName()
        {
            if (Seropen == true && controller == null)
            {
                W.ABBmessage(message_lbo, "请打开ABB接受数据");
                return;
            }
            SendDataName_cbo.Items.Clear();
            RapidSymbol[] symbolsNum = W.rapidSymbol(controller, "string");
            for (int i = 0; i < symbolsNum.Length; i++)
            {
                if (symbolsNum[i].Type.ToString() == "Persistent")
                {
                    RapidData rd = tasks[0].GetRapidData(symbolsNum[i]);
                    if (rd.IsArray != true)  //只获取一位数组
                    {
                        SendSerName_cbb.Items.Add(rd.Name);
                    }
                }
            }
        }

        private void serialPort1_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            Thread th = new Thread(serialPort1Three);
            th.IsBackground = true;
            th.Start();
        }

        private void SendType_cbb_SelectedIndexChanged(object sender, EventArgs e)
        {
            Thread th = new Thread(SerialPortSendName);
            th.IsBackground = true;
            th.Start();
        }


        public void serialPort1Three()
        {
            string str = "";
            if (isRxShow == false)
            {
                return;
            }
            byte[] datatemp = new byte[serialPort1.BytesToRead];
            int a = serialPort1.Read(datatemp, 0, datatemp.Length);
            //if (a == 0)
            //{
            //    return;
            //}
            //string serRecive = Encoding.UTF8.GetString(datatemp, 0, a);
            reciveBuffer.AddRange(datatemp);
            reciveCount += datatemp.Length;
            this.Invoke(new EventHandler(delegate
            {
                if (!recivehex_chb.Checked)
                {
                    //编码格式的选择必须2边都一样是gb2312
                    str = Encoding.GetEncoding("gb2312").GetString(datatemp);
                    //0*00→\0 结束 不会显示
                    str = str.Replace("\0", "\\0");
                    SerShowMsg(str, "");
                    if (Seropen == true)
                    {
                        if (intervalSer_cbb.SelectedItem == null)
                        {
                            W.ABBmessage(message_lbo, "请选择间隔符");
                            return;
                        }
                        string[] strNew = str.Split(new char[] { intervalSer_cbb.SelectedItem.ToString()[0] }, StringSplitOptions.RemoveEmptyEntries);
                        for (int i = 0; i < strNew.Length; i++)
                        {
                            switch (ReciveSerType_cbb.SelectedItem.ToString())
                            {
                                case "num":
                                    W.ArrayDataWrite(controller, ReciveSerName_cbb.SelectedItem.ToString(), strNew[i], "num", 1, i, 0, 0);
                                    break;
                                case "bool":
                                    W.ArrayDataWrite(controller, ReciveSerName_cbb.SelectedItem.ToString(), strNew[i], "bool", 1, i, 0, 0);
                                    break;
                                case "string":
                                    strNew[i] = $"\"{strNew[i]}\"";
                                    W.ArrayDataWrite(controller, ReciveSerName_cbb.SelectedItem.ToString(), strNew[i], "string", 1, i, 0, 0);
                                    break;
                            }
                        }
                    }


                    //可以简化上面3句代码
                    //recive_reb.AppendText(Encoding.GetEncoding("gb2312").GetString(datatemp).Replace("\0", "\\0"));

                }
                else
                {
                    //十六进制是选中的状态下
                    // recive_rtb.AppendText(Transform.ToHexString(datatemp, " "));
                    SerShowMsg(Transform.ToHexString(datatemp, " "), " ");
                }

            }));
        }
        public void SerShowMsg(string str, string Name)
        {
            DateTime dt = DateTime.Now;
            recive_rtb.Items.Add(dt.ToLocalTime().ToString() + " " + Name);
            recive_rtb.Items.Add(str);
            recive_rtb.Items.Add(" ");
            recive_rtb.TopIndex = recive_rtb.Items.Count - 1;   //进行全选
        }


        #endregion

        #region //获取坐标
        public void GetRobotPos()
        {
            string[] DataName = { "四元素", "笛尔卡", ",", " " };
            string[] posname = { "大地坐标", "工件坐标" };
            string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3" };

            int[] sizeWith = { 40, 100, 40, 150 };
            int sizeRow = 30;
            Getposchb_dgv.Rows.Clear();
            Getposchb_dgv.Columns.Clear();
            Getposchb_dgv.ColumnHeadersVisible = false;   //禁用行标题
            Getposchb_dgv.RowHeadersVisible = false;  //禁用列标题
            Getposchb_dgv.RowsDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //文本居中
            Getposchb_dgv.AllowUserToAddRows = false;  //关闭自动添加行  
            Getposchb_dgv.RowsDefaultCellStyle.Font = new Font("宋体", 14, FontStyle.Regular);
            DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
            for (int i = 0; i < DataName.Length; i++)
            {
                if (i == 0 || i == 2)
                {
                    dgv[i] = new DataGridViewCheckBoxColumn()
                    {
                        Name = DataHeaderText[i],
                        HeaderText = DataName[i],
                        Width = sizeWith[i],
                        CellTemplate = new DataGridViewCheckBoxCell()
                    };
                }
                else
                {
                    dgv[i] = new DataGridViewColumn()
                    {
                        Name = DataHeaderText[i],
                        HeaderText = DataName[i],
                        Width = sizeWith[i],
                        CellTemplate = new DataGridViewTextBoxCell()
                    };
                }
                Getposchb_dgv.Columns.Add(dgv[i]);
            }

            for (int i = 0; i < posname.Length; i++)
            {
                Getposchb_dgv.RowTemplate.MinimumHeight = sizeRow;  //设置行高
            }
            for (int i = 0; i < posname.Length; i++)
            {
                Getposchb_dgv.Rows.Add();
                Getposchb_dgv[1, i].Value = DataName[i];
                Getposchb_dgv[3, i].Value = posname[i];
            }
            Getposchb_dgv[0, 0].Value = true;
            Getposchb_dgv[2, 0].Value = true;
            W.Dgvsize(Getposchb_dgv);
            for (int i = 0; i < sizeWith.Length; i++)
            {
                Getposchb_dgv.Columns[i].Width = sizeWith[i];
            }
            Getposchb_dgv.Rows[0].Selected = false;  //单元格不被选中

            this.Getposchb_dgv.Columns[1].ReadOnly = true;     //禁止1列单元格编辑
            this.Getposchb_dgv.Columns[3].ReadOnly = true;     //禁止3列单元格编辑
        }
        private void Getposchb_dgv_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.ColumnIndex == 0 || e.ColumnIndex == 2)
            {
                foreach (DataGridViewRow row in Getposchb_dgv.Rows)
                {
                    row.Cells[e.ColumnIndex].Value = false;//只能勾选一个Chebox
                }
                Getposchb_dgv.Rows[e.RowIndex].Cells[e.ColumnIndex].Value = true;
                if ((bool)Getposchb_dgv[0, 0].Value == true)
                {
                    Getpos_dgv[2, 1].Value = "Q1";
                    Getpos_dgv[2, 2].Value = "Q2";
                    Getpos_dgv[2, 3].Value = "Q3";
                    Getpos_dgv[2, 4].Value = "Q4";
                }
                else
                {
                    Getpos_dgv[2, 1].Value = "Rz";
                    Getpos_dgv[2, 2].Value = "Ry";
                    Getpos_dgv[2, 3].Value = "Rx";
                    Getpos_dgv[2, 4].Value = " ";
                }
            }
        }

        public void Getpos()
        {
            string[] DataName = { " ", " ", ",", " " };
            string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3" };
            string[] Dataxyz = { "X", "Y", "Z", " " };
            string[] DataRxyz = { "Rz", "Ry", "Rx", " " };
            string[] DataQxyz = { "Q1", "Q2", "Q3", "Q4" };
            string[] Datajoin123 = { "J1", "J2", "J3" };
            string[] Datajoin456 = { "J4", "J5", "J6" };
            string[] Datatool = { "工具坐标", "工件坐标", "有效载荷" };
            string[] DataTROB = { "当前任务", "是否校准", "机械类型" };
            int[] sizeWith = { 100, 100, 100, 100 };
            Getpos_dgv.Rows.Clear();
            Getpos_dgv.Columns.Clear();
            Getpos_dgv.ColumnHeadersVisible = false;   //禁用行标题
            Getpos_dgv.RowHeadersVisible = false;  //禁用列标题
            Getpos_dgv.RowsDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //文本居中
            Getpos_dgv.AllowUserToAddRows = false;  //关闭自动添加行
            Getpos_dgv.RowsDefaultCellStyle.Font = new Font("宋体", 14, FontStyle.Regular);
            DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];

            for (int i = 0; i < dgv.Length; i++)
            {
                dgv[i] = new DataGridViewColumn() { Name = DataHeaderText[i], HeaderText = DataName[i], Width = sizeWith[i], CellTemplate = new DataGridViewTextBoxCell() };
                Getpos_dgv.Columns.Add(dgv[i]);
            }

            Getpos_dgv.RowTemplate.MinimumHeight = 30;
            for (int i = 0; i < 20; i++)
            {
                Getpos_dgv.Rows.Add();
            }
            Getpos_dgv[0, 0].Value = "线性坐标";
            for (int i = 0; i < Dataxyz.Length; i++)
            {
                Getpos_dgv.Rows.Add();
                Getpos_dgv[0, i + 1].Value = Dataxyz[i];
                Getpos_dgv[2, i + 1].Value = DataQxyz[i];
            }
            Getpos_dgv[0, 5].Value = "关节坐标";
            for (int i = 0; i < Datajoin123.Length; i++)
            {
                Getpos_dgv[0, i + 6].Value = Datajoin123[i];
                Getpos_dgv[2, i + 6].Value = Datajoin456[i];
            }
            Getpos_dgv[0, 9].Value = "机械单元";
            for (int i = 0; i < Datatool.Length; i++)
            {
                Getpos_dgv[0, i + 10].Value = Datatool[i];
                Getpos_dgv[2, i + 10].Value = DataTROB[i];
            }
            W.Dgvsize(Getpos_dgv);
            Getpos_dgv.Rows[0].Selected = false;  //单元格不被选中
            for (int i = 0; i < Getpos_dgv.Columns.Count; i++)
            {
                Getpos_dgv.Columns[i].ReadOnly = true;
            }
        }
        private void GetPos_timer_Tick(object sender, EventArgs e)
        {
            try
            {
                if (controller == null)
                {
                    return;
                }

                if ((bool)Getposchb_dgv[2, 0].Value == true)
                {
                    aRobTarget = controller.MotionSystem.ActiveMechanicalUnit.GetPosition(CoordinateSystemType.World);
                }
                else
                {
                    aRobTarget = controller.MotionSystem.ActiveMechanicalUnit.GetPosition(CoordinateSystemType.WorkObject);
                }
                ajointTarget = controller.MotionSystem.ActiveMechanicalUnit.GetPosition();
                Getpos_dgv[1, 1].Value = aRobTarget.Trans.X.ToString(format: "0.00");
                Getpos_dgv[1, 2].Value = aRobTarget.Trans.Y.ToString(format: "0.00");
                Getpos_dgv[1, 3].Value = aRobTarget.Trans.Z.ToString(format: "0.00");
                if ((bool)Getposchb_dgv[0, 0].Value == true)
                {
                    Getpos_dgv[3, 1].Value = aRobTarget.Rot.Q1.ToString(format: "0.00");
                    Getpos_dgv[3, 2].Value = aRobTarget.Rot.Q2.ToString(format: "0.00");
                    Getpos_dgv[3, 3].Value = aRobTarget.Rot.Q3.ToString(format: "0.00");
                    Getpos_dgv[3, 4].Value = aRobTarget.Rot.Q4.ToString(format: "0.00");
                }
                else
                {
                    aRobTarget.Rot.ToEulerAngles(out rx, out ry, out rz);
                    Getpos_dgv[3, 1].Value = rz.ToString(format: "0.00");
                    Getpos_dgv[3, 2].Value = ry.ToString(format: "0.00");
                    Getpos_dgv[3, 3].Value = rx.ToString(format: "0.00");
                    Getpos_dgv[3, 4].Value = " ";
                }

                Getpos_dgv[1, 6].Value = ajointTarget.RobAx.Rax_1.ToString(format: "0.00");
                Getpos_dgv[1, 7].Value = ajointTarget.RobAx.Rax_2.ToString(format: "0.00");
                Getpos_dgv[1, 8].Value = ajointTarget.RobAx.Rax_3.ToString(format: "0.00");
                Getpos_dgv[3, 6].Value = ajointTarget.RobAx.Rax_4.ToString(format: "0.00");
                Getpos_dgv[3, 7].Value = ajointTarget.RobAx.Rax_5.ToString(format: "0.00");
                Getpos_dgv[3, 8].Value = ajointTarget.RobAx.Rax_6.ToString(format: "0.00");

                Getpos_dgv[1, 10].Value = controller.MotionSystem.ActiveMechanicalUnit.Tool.ToString();
                Getpos_dgv[1, 11].Value = controller.MotionSystem.ActiveMechanicalUnit.WorkObject.ToString();
                Getpos_dgv[1, 12].Value = controller.MotionSystem.ActiveMechanicalUnit.PayLoad.ToString();

                Getpos_dgv[3, 10].Value = controller.MotionSystem.ActiveMechanicalUnit.Task.ToString();
                Getpos_dgv[3, 11].Value = controller.MotionSystem.ActiveMechanicalUnit.IsCalibrated.ToString();
                Getpos_dgv[3, 12].Value = controller.MotionSystem.ActiveMechanicalUnit.Type.ToString();

                if (controller == null)
                {
                    return;
                }
                ExecutionCycle cycle = controller.Rapid.Cycle;
                if (cycle.ToString() == "Once")
                {
                    label_period.Text = "单周模式";
                    label_period.BackColor = Color.Yellow;
                }
                else
                {
                    label_period.Text = "连续模式";
                    label_period.BackColor = Color.GreenYellow;
                }
                if (controller.Rapid.ExecutionStatus.ToString() == "Running")
                {
                    this.label_exe.Text = "正在运行";
                    this.label_exe.BackColor = Color.GreenYellow;
                    this.btn_Start.BackColor = Color.GreenYellow;
                    this.btn_Stop.BackColor = Color.Transparent;
                }
                else if (controller.Rapid.ExecutionStatus.ToString() == "Stopped")
                {
                    this.label_exe.Text = "停止运行";
                    this.label_exe.BackColor = Color.Red;
                    this.btn_Start.BackColor = Color.Transparent;
                    this.btn_Stop.BackColor = Color.Red;
                }
                else
                {
                    this.label_exe.Text = controller.Rapid.ExecutionStatus.ToString();
                    this.label_exe.BackColor = Color.Red;
                    this.btn_Start.BackColor = Color.Transparent;
                    this.btn_Stop.BackColor = Color.Red;
                }
                if (isVirtual)
                {
                    MainComputerServiceInfo m1 = controller.MainComputerServiceInfo;
                    label_temperature.Text = m1.Temperature.ToString() + "°C";
                }
                new Thread(() =>
                {
                    int nCount = 0;
                    int nCount_ = 0;
                    for (int i = 0; i < rapids.Length; i++)
                    {
                        
                        RapidData data = controller.Rapid.GetRapidData(rapids[i].Scope);
                        if (data.RapidType == "jointtarget" || data.RapidType == "wobjdata" || data.RapidType == "tooldata" || data.RapidType == "loaddata" || data.RapidType == "speeddata") continue;
                        switch (data.RapidType)
                        {
                            case "robtarget":
                                try
                                {
                                    RobTarget_Dgv[0, nCount_].Value = data.Name;
                                    RobTarget_Dgv[1, nCount_].Value = rapids[i].Scope[0].ToString(); ;
                                    RobTarget_Dgv[2, nCount_].Value = rapids[i].Scope[1].ToString();
                                    RobTarget_Dgv[3, nCount_].Value = data.RapidType;
                                    if (data.Value != null)
                                    {
                                        RobTarget rbt = (RobTarget)data.Value;
                                        RobTarget_Dgv[4, nCount_].Value = rbt.Trans.X.ToString("0.000");
                                        RobTarget_Dgv[5, nCount_].Value = rbt.Trans.Y.ToString("0.000");
                                        RobTarget_Dgv[6, nCount_].Value = rbt.Trans.Z.ToString("0.000");
                                        rbt.Rot.ToEulerAngles(out double rx, out double ry, out double rz);
                                        RobTarget_Dgv[7, nCount_].Value = rx.ToString("0.000");
                                        RobTarget_Dgv[8, nCount_].Value = ry.ToString("0.000");
                                        RobTarget_Dgv[9, nCount_].Value = rz.ToString("0.000");
                                    }

                                }
                                catch
                                {

                                }
                                nCount_++;
                                break;
                            default:
                                try
                                {


                                    NumBoolData_Dgb[0, nCount].Value = data.Name;
                                    NumBoolData_Dgb[1, nCount].Value = rapids[i].Scope[0].ToString();
                                    NumBoolData_Dgb[2, nCount].Value = rapids[i].Scope[1].ToString();
                                    NumBoolData_Dgb[3, nCount].Value = data.RapidType;
                                    if (data.Value == null)
                                    {
                                        NumBoolData_Dgb[4, nCount].Value = "";
                                    }
                                    else
                                    {
                                        NumBoolData_Dgb[4, nCount].Value = data.StringValue;
                                    }
                                }
                                catch
                                {

                                }
                                nCount++;
                                break;
                        }



                    }

                }).Start();

                RapidData rapid = controller.Rapid.GetRapidData("GetJoint", "Module1", "C_Join");
                for (int i = 0; i < 6; i++)
                {
                    num[i] = (Num)rapid.ReadItem(i);
                    userCurve1.AddCurveData(str[i], ((float)num[i].Value));
                }
                //在第七处加上主轴转速的数据
                //float spindleRotSpeed = toolManager
            }
            catch
            {

            }

        }

        #endregion

        #region //ABB移动
        public void ABBmovea()
        {
            Thread th = new Thread(ABBmoveThread);
            th.IsBackground = true;
            th.Start();

            Thread th1 = new Thread(ABBjoinThread);
            th1.IsBackground = true;
            th1.Start();
        }


        public void ABBmoveThread()
        {
            string[] DataName = { "线性+", "线性-", "重定位+", "重定位-" };
            string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3" };
            string[] DataXyz = { "X+", "Y+", "Z+", "X-", "Y-", "Z-", "RX+", "RY+", "RZ+", "RX-", "RY-", "RZ-" };
            int sizeWith = 100;
            int sizeRow = 30;
            ABBMoveL_dgv.Rows.Clear();
            ABBMoveL_dgv.Columns.Clear();
            ABBMoveL_dgv.ColumnHeadersVisible = false;   //禁用行标题
            ABBMoveL_dgv.RowHeadersVisible = false;  //禁用列标题
            ABBMoveL_dgv.RowsDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //文本居中
            ABBMoveL_dgv.AllowUserToAddRows = false;  //关闭自动添加行
            ABBMoveL_dgv.RowsDefaultCellStyle.Font = new Font("宋体", 14, FontStyle.Regular);
            DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
            for (int i = 0; i < DataName.Length; i++)
            {
                dgv[i] = new DataGridViewButtonColumn()
                {
                    Name = DataHeaderText[i]
                    ,
                    HeaderText = DataName[i],
                    Width = sizeWith,
                    CellTemplate = new DataGridViewButtonCell()
                };
                ABBMoveL_dgv.Columns.Add(dgv[i]);
            }
            ABBMoveL_dgv.RowTemplate.MinimumHeight = 30;
            for (int i = 0; i < DataXyz.Length; i++)
            {
                if (i < 3)
                {
                    ABBMoveL_dgv.Rows.Add();
                    ABBMoveL_dgv.Rows[i].Cells[0].Value = DataXyz[i];
                }
                else if (i < 6)
                {
                    ABBMoveL_dgv.Rows[i - 3].Cells[1].Value = DataXyz[i];
                }
                else if (i < 9)
                {
                    ABBMoveL_dgv.Rows[i - 6].Cells[2].Value = DataXyz[i];
                }
                else if (i < 12)
                {
                    ABBMoveL_dgv.Rows[i - 9].Cells[3].Value = DataXyz[i];
                }
            }
            W.Dgvsize(ABBMoveL_dgv);
        }


        public void ABBjoinThread()
        {
            string[] DataName = { "线性+", "线性-", "重定位+", "重定位-" };
            string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3" };
            string[] DataXyz = { "J1+", "J2+", "J3+", "J1-", "J2-", "J3-", "J4+", "J5+", "J6+", "J4-", "J5-", "J6-" };
            int sizeWith = 100;
            int sizeRow = 30;
            ABBJoin_dgv.Rows.Clear();
            ABBJoin_dgv.Columns.Clear();
            ABBJoin_dgv.ColumnHeadersVisible = false;   //禁用行标题
            ABBJoin_dgv.RowHeadersVisible = false;  //禁用列标题
            ABBJoin_dgv.RowsDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //文本居中
            ABBJoin_dgv.AllowUserToAddRows = false;  //关闭自动添加行
            ABBJoin_dgv.RowsDefaultCellStyle.Font = new Font("宋体", 14, FontStyle.Regular);
            DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
            for (int i = 0; i < DataName.Length; i++)
            {
                dgv[i] = new DataGridViewButtonColumn()
                {
                    Name = DataHeaderText[i]
                    ,
                    HeaderText = DataName[i],
                    Width = sizeWith,
                    CellTemplate = new DataGridViewButtonCell()
                };
                ABBJoin_dgv.Columns.Add(dgv[i]);
            }
            ABBJoin_dgv.RowTemplate.MinimumHeight = 30;
            for (int i = 0; i < DataXyz.Length; i++)
            {
                if (i < 3)
                {
                    ABBJoin_dgv.Rows.Add();
                    ABBJoin_dgv.Rows[i].Cells[0].Value = DataXyz[i];
                }
                else if (i < 6)
                {
                    ABBJoin_dgv.Rows[i - 3].Cells[1].Value = DataXyz[i];
                }
                else if (i < 9)
                {
                    ABBJoin_dgv.Rows[i - 6].Cells[2].Value = DataXyz[i];
                }
                else if (i < 12)
                {
                    ABBJoin_dgv.Rows[i - 9].Cells[3].Value = DataXyz[i];
                }
            }
            W.Dgvsize(ABBJoin_dgv);
        }




        private void ABBMoveL_dgv_CellMouseUp(object sender, DataGridViewCellMouseEventArgs e)
        {

        }
        private void ABBMoveL_dgv_CellMouseDown(object sender, DataGridViewCellMouseEventArgs e)
        {

        }
        private void ABBJoin_dgv_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            switch (e.ColumnIndex)
            {
                case 0:
                    W.ABBMovedistance(controller, message_lbo, "C_Count", (e.RowIndex + 13).ToString(), "num");
                    break;
                case 1:
                    W.ABBMovedistance(controller, message_lbo, "C_Count", (e.RowIndex + 16).ToString(), "num");
                    break;
                case 2:
                    W.ABBMovedistance(controller, message_lbo, "C_Count", (e.RowIndex + 19).ToString(), "num");
                    break;
                case 3:
                    W.ABBMovedistance(controller, message_lbo, "C_Count", (e.RowIndex + 22).ToString(), "num");
                    break;
            }
        }
        #endregion

        #region //取消选中单元格
        private void tabPage11_Click(object sender, EventArgs e)
        {
            NumBoolData_Dgb.ClearSelection();
            NumBoolDataArray_Dgb.ClearSelection();
        }

        private void tabPage12_Click(object sender, EventArgs e)
        {
            RobTarget_Dgv.ClearSelection();
        }



        private void tabPage3_Click(object sender, EventArgs e)
        {
            DO_Dgv.ClearSelection();
            DI_Dgv.ClearSelection();
        }

        private void tabPage1_Click(object sender, EventArgs e)
        {
            Getpos_dgv.ClearSelection();
            Getposchb_dgv.ClearSelection();
        }


        #endregion

        #region //单选或多选单元格
        private void 单选单元格ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            this.NumBoolData_Dgb.SelectionMode = DataGridViewSelectionMode.CellSelect;
            this.NumBoolDataArray_Dgb.SelectionMode = DataGridViewSelectionMode.CellSelect;
        }


        private void 多选单元格ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            this.NumBoolData_Dgb.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            this.NumBoolDataArray_Dgb.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        }

        private void 单选单元格ToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            this.DO_Dgv.SelectionMode = DataGridViewSelectionMode.CellSelect;
            this.DI_Dgv.SelectionMode = DataGridViewSelectionMode.CellSelect;
        }

        private void 多选单元格ToolStripMenuItem2_Click(object sender, EventArgs e)
        {
            this.DO_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            this.DI_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        }

        private void 单选2单元格ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            RobTarget_Dgv.SelectionMode = DataGridViewSelectionMode.CellSelect;
        }
        private void 多选单元格ToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            this.RobTarget_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        }
        #endregion

        #region //获取扭矩速度
        System.Windows.Forms.Timer timer1;
        public void GetspeedTorque()
        {
            try
            {
                if (controller == null)
                {
                    W.ABBmessage(message_lbo, "请连接控制器");
                    return;
                }
                if (controller.Rapid.GetRapidData("t2", "MainModul", "C_speed") == null)
                {
                    W.ABBmessage(message_lbo, "请在ABB查看是否有建立 C_speed 数据");
                }
                else if (controller.Rapid.GetRapidData("t2", "MainModul", "C_Join") == null)
                {
                    W.ABBmessage(message_lbo, "请在ABB查看是否有建立 C_Join 数据");
                }
                string[] str = { "A", "B", "C", "D", "E", "F", "G" };
                RapidData rd;
                float[] t = new float[str.Length];
                userCurve1.SetLeftCurve(str[0], new float[] { }, Color.Tomato);
                userCurve1.SetLeftCurve(str[1], new float[] { }, Color.DarkOrchid);
                userCurve1.SetLeftCurve(str[2], new float[] { }, Color.Red);
                userCurve1.SetLeftCurve(str[3], new float[] { }, Color.Black);
                userCurve1.SetLeftCurve(str[4], new float[] { }, Color.DodgerBlue);
                userCurve1.SetLeftCurve(str[5], new float[] { }, Color.Coral);
                //userCurve1.SetLeftCurve(str[6], new float[] { }, Color.BlanchedAlmond);

                timer.Tick += (sender1, e1) =>
                {
                    if (getspeedandtorque == 1)
                    {
                        rd = controller.Rapid.GetRapidData("t2", "MainModul", "C_speed"); //获取任务t2下的module1下的axis_tor_arr数组
                        userCurve1.ValueMaxLeft = 400;
                        userCurve1.ValueMinLeft = 400;
                        userCurve1.ValueMaxRight = 400;
                        userCurve1.ValueMinLeft = 400;
                    }
                    else
                    {
                        rd = controller.Rapid.GetRapidData("t2", "MainModul", "C_Join");
                        userCurve1.ValueMaxLeft = 300;
                        userCurve1.ValueMinLeft = -300;
                        userCurve1.ValueMaxRight = 300;
                        userCurve1.ValueMinLeft = -300;
                    }
                    userCurve1.ValueSegment = 10;
                    userCurve1.IsAbscissaStrech = true;
                    if (rd.IsArray)
                    {
                        ArrayData arr = (ArrayData)rd.Value;
                        switch (getCount)
                        {
                            case 0:
                                t[0] = Convert.ToSingle(arr[0].ToString());
                                userCurve1.AddCurveData(str[0], t[0]);
                                break;
                            case 1:
                                t[1] = Convert.ToSingle(arr[1].ToString());
                                userCurve1.AddCurveData(str[1], t[1]);
                                break;
                            case 2:
                                t[2] = Convert.ToSingle(arr[2].ToString());
                                userCurve1.AddCurveData(str[2], t[2]);
                                break;
                            case 3:
                                t[3] = Convert.ToSingle(arr[3].ToString());
                                userCurve1.AddCurveData(str[3], t[3]);
                                break;
                            case 4:
                                t[4] = Convert.ToSingle(arr[4].ToString());
                                userCurve1.AddCurveData(str[4], t[4]);
                                break;
                            case 5:
                                t[5] = Convert.ToSingle(arr[5].ToString());
                                userCurve1.AddCurveData(str[5], t[5]);
                                break;
                            case 6:
                                for (int i = 0; i < arr.Length; i++)
                                {
                                    t[i] = Convert.ToSingle(arr[i].ToString());
                                    userCurve1.AddCurveData(str[i], t[i]);
                                }
                                break;

                        }
                    }
                };
                timer.Start();
            }
            catch (Exception)
            {

            }
        }

        private int getspeedandtorque;
        private int getCount;

        public void speed_cmsa(int getspeedandtorque, int getCount)
        {
            userCurve1.RemoveAllCurve();
            this.getspeedandtorque = getspeedandtorque;
            this.getCount = getCount;
            GetspeedTorque();
        }

        public void Spindle_speed_show()
        {
            try
            {
                userCurve1.RemoveAllCurve();

                if (this.toolManager == null)
                {
                    W.ABBmessage(message_lbo, "主轴未上电，请连接主轴");
                    Console.WriteLine("主轴未上电，请连接主轴");
                    return;
                }
                userCurve1.SetLeftCurve("G", new float[] { }, Color.Blue);
                userCurve1.SetLeftCurve("H", new float[] { }, Color.Green);
                userCurve1.ValueMaxLeft = Convert.ToInt32(this.numericUpDown1.Maximum);// 向上取整
                userCurve1.ValueMinLeft = Convert.ToInt32(this.numericUpDown1.Minimum);// 向下取整

                timer.Tick += (sender1, e1) =>
                {
                    int speed = 0;
                    if (toolManager != null)
                    {
                        if (this.toolManager.GetCurrentRotSpeed(out speed))
                        {
                            //userCurve1.ValueMaxLeft = Convert.ToInt32(Math.Max(speed, (Int32)this.numericUpDown1.Value) * 1.2);
                            userCurve1.AddCurveData("G", speed);
                            userCurve1.AddCurveData("H", (Int32)this.numericUpDown1.Value);
                        }
                        else
                        {
                            //userCurve1.ValueMaxLeft = Convert.ToInt32((Double)(this.numericUpDown1.Value) * 1.2);
                            userCurve1.AddCurveData("G", 0);
                            userCurve1.AddCurveData("H", (Int32)this.numericUpDown1.Value);
                        }
                    }
                    else
                    {
                        userCurve1.AddCurveData("G", 0);
                        userCurve1.AddCurveData("H", 0);
                    }


                };
                timer.Start();
            }
            catch (Exception)
            {

            }
        }
        private void 轴ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 0);
        }

        private void 轴ToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 1);
        }

        private void 轴ToolStripMenuItem2_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 2);
        }

        private void 轴ToolStripMenuItem3_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 3);
        }

        private void 轴ToolStripMenuItem4_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 4);
        }


        private void 轴ToolStripMenuItem5_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 5);
        }

        private void 所有轴ToolStripMenuItem_Click(object sender, EventArgs e)
        {
            speed_cmsa(2, 6);
        }
        private void 轴ToolStripMenuItem6_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 0);
        }

        private void 轴ToolStripMenuItem7_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 1);
        }


        private void 轴ToolStripMenuItem8_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 2);
        }


        private void 轴ToolStripMenuItem9_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 3);
        }


        private void 轴ToolStripMenuItem10_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 4);
        }



        private void 轴ToolStripMenuItem11_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 5);
        }
        private void 轴ToolStripMenuItem12_Click(object sender, EventArgs e)
        {
            Console.WriteLine("Hello, button12");
            Spindle_speed_show();
            //speed_cmsa(1, 6);
        }
        private void 所有轴ToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            speed_cmsa(1, 6);
        }
        #endregion

        #region //保存数据到表格
        XLWorkbook g_wb = new XLWorkbook();
        RobTarget GetRobTarget;
        JointTarget GetjointTarget;
        private void button6_Click(object sender, EventArgs e)
        {
            //try
            //{
            string c = DateTime.Now.ToLongTimeString().ToString();
            string asd = c.Replace(":", string.Empty);
            string a = asd + ".xlsx";
            string GetFile = controller.FileSystem.LocalDirectory + a;
            // File.Delete(GetFile);
            if (!File.Exists(GetFile))
            {
                g_wb.AddWorksheet(asd);
                g_wb.SaveAs(GetFile);
            }

            stoptask = 0;
            g_wb = new XLWorkbook(GetFile);
            IXLWorksheet sheet = g_wb.Worksheet(1);
            sheet.Cell(1, 1).Value = "X";
            sheet.Cell(1, 2).Value = "Y";
            sheet.Cell(1, 3).Value = "Z";
            sheet.Cell(1, 4).Value = "Q1";
            sheet.Cell(1, 5).Value = "Q2";
            sheet.Cell(1, 6).Value = "Q3";
            sheet.Cell(1, 7).Value = "Q4";
            sheet.Cell(1, 8).Value = "RX";
            sheet.Cell(1, 9).Value = "RY";
            sheet.Cell(1, 10).Value = "RZ";
            sheet.Cell(1, 11).Value = "J1";
            sheet.Cell(1, 12).Value = "J2";
            sheet.Cell(1, 13).Value = "J3";
            sheet.Cell(1, 14).Value = "J4";
            sheet.Cell(1, 15).Value = "J5";
            sheet.Cell(1, 16).Value = "J6";
            g_wb.Save();
            System.Threading.Tasks.Task.Run(new Action(() =>      //异步方法
            {
                for (int i = 2; i < 1002; i++)
                {
                    GetRobTarget = controller.MotionSystem.ActiveMechanicalUnit.GetPosition(CoordinateSystemType.World);
                    GetjointTarget = controller.MotionSystem.ActiveMechanicalUnit.GetPosition();
                    sheet.Cell(i, 1).Value = aRobTarget.Trans.X.ToString(format: "0.00");
                    sheet.Cell(i, 2).Value = aRobTarget.Trans.Y.ToString(format: "0.00");
                    sheet.Cell(i, 3).Value = aRobTarget.Trans.Z.ToString(format: "0.00");
                    sheet.Cell(i, 4).Value = aRobTarget.Rot.Q1.ToString(format: "0.00000");
                    sheet.Cell(i, 5).Value = aRobTarget.Rot.Q2.ToString(format: "0.00000");
                    sheet.Cell(i, 6).Value = aRobTarget.Rot.Q3.ToString(format: "0.00000");
                    sheet.Cell(i, 7).Value = aRobTarget.Rot.Q4.ToString(format: "0.00000");
                    aRobTarget.Rot.ToEulerAngles(out rx, out ry, out rz);
                    sheet.Cell(i, 8).Value = rz.ToString(format: "0.00");
                    sheet.Cell(i, 9).Value = ry.ToString(format: "0.00");
                    sheet.Cell(i, 10).Value = rx.ToString(format: "0.00");
                    sheet.Cell(i, 11).Value = ajointTarget.RobAx.Rax_1.ToString(format: "0.00");
                    sheet.Cell(i, 12).Value = ajointTarget.RobAx.Rax_2.ToString(format: "0.00");
                    sheet.Cell(i, 13).Value = ajointTarget.RobAx.Rax_3.ToString(format: "0.00");
                    sheet.Cell(i, 14).Value = ajointTarget.RobAx.Rax_4.ToString(format: "0.00");
                    sheet.Cell(i, 15).Value = ajointTarget.RobAx.Rax_5.ToString(format: "0.00");
                    sheet.Cell(i, 16).Value = ajointTarget.RobAx.Rax_6.ToString(format: "0.00");
                    g_wb.Save();
                    textBox1.Text = i.ToString();
                    if (i == 1000)
                    {
                        W.ABBmessage(message_lbo, "已读完1000条");
                    }
                    if (stoptask == 1)
                    {
                        break;
                    }
                    //timer2.Start();

                    // W.ABBmessage(message_lbo, "保存成功");    
                }
            }));
            //}
            //catch (Exception ex)
            //{
            //    MessageBox.Show(ex.Message);
            //}
        }
        int stoptask = 0;
        private void button5_Click(object sender, EventArgs e)
        {
            stoptask = 1;
        }




        private void openxls_btn_Click(object sender, EventArgs e)
        {
            try
            {
                string GetFile = controller.FileSystem.LocalDirectory + "Getpos.xlsx";
                System.Diagnostics.Process.Start(GetFile);
            }
            catch
            {


            }
        }
        #endregion

        #region //Modbus
        #region //modbus slave
        public string[] connectType = { "serialPort" };
        public int[] serialBaud = { 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 56000, 57600, 11520 };
        public int[] serinlDataBi = { 5, 6, 7, 8 };
        public double[] serialStopBitCbb = { 1, 1.5, 2 };
        public StopBits[] serialStopBit = { StopBits.One, StopBits.OnePointFive, StopBits.Two };
        public string[] serialParityCbb = { "None Parity", "Odd Parity", "Even Parity" };
        private Parity[] serialParity = { Parity.None, Parity.Odd, Parity.Even };

        public string[] op_string = { "读线圈(01H)", "读离散输入(02H)", "读保持寄存器(03H)","读输入寄存器(04H)"
                ,"写单个线圈(05H)","写单个保持寄存器(06H)","写多个线圈(0FH)","写多个保持寄存器(10H)"};
        private byte[] op_code = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x0f, 0x10 };

        public SerialPort m_serialPort = null;
        public ModbusSerialMaster m_serialMaster;
        public ModbusSerialMaster rtu_serialMaster;
        public ModbusSerialMaster asiic_serialMaster;
        public bool isTransPorConnect = false;


        private string[] Function = {"01 Coil Status {0x}",
                "02 Input Status {1x}","03 Holding Register {4x}","04 Input Registers {3x}" };
        public void ModbusForLoad()
        {
            try
            {
                m_serialPort = new SerialPort();
                //ui连接类型
                //  connectType_cbb.DataSource = connectType;
                RegistryKey keyCom = Registry.LocalMachine.OpenSubKey(@"Hardware\DeviceMap\SerialComm");  //获取注册列表中的COM口
                if (keyCom != null)
                {
                    string[] sSubkeys = keyCom.GetValueNames();
                    SlaveSerialPort_cbb.Items.Clear();
                    PollSerialPort_cbb.Items.Clear();
                    foreach (var sValue in sSubkeys)
                    {
                        string protName = keyCom.GetValue(sValue).ToString();   //把搜索到的COM口赋值给字符串
                        SlaveSerialPort_cbb.Items.Add(protName);
                        PollSerialPort_cbb.Items.Add(protName);
                    }
                    SlaveSerialPort_cbb.SelectedIndex = 1;
                    PollSerialPort_cbb.SelectedIndex = 1;

                    SlaveserialBaud_cbb.DataSource = serialBaud;
                    SlaveserialBaud_cbb.SelectedIndex = 5;
                    PollserialBaud_cbb.DataSource = serialBaud;
                    PollserialBaud_cbb.SelectedIndex = 5;

                    SlaveserialDatabit_cbb.DataSource = serinlDataBi;
                    SlaveserialDatabit_cbb.SelectedIndex = 3;
                    PollserialDatabit_cbb.DataSource = serinlDataBi;
                    PollserialDatabit_cbb.SelectedIndex = 3;

                    SlaveserialParity_cbb.DataSource = serialParityCbb;
                    SlaveserialParity_cbb.SelectedIndex = 0;
                    PollserialParity_cbb.DataSource = serialParityCbb;
                    PollserialParity_cbb.SelectedIndex = 0;

                    SlaveserialStopbit_cbb.DataSource = serialStopBitCbb;
                    SlaveserialStopbit_cbb.SelectedIndex = 0;
                    PollserialStopbit_cbb.DataSource = serialStopBitCbb;
                    PollserialStopbit_cbb.SelectedIndex = 0;

                    RTUSlave_rtb.Checked = true;
                    RTUPoll_rtb.Checked = true;

                    PollFunction_cbb.Items.Clear();
                    PollFunction_cbb.Items.AddRange(Function);
                    PollFunction_cbb.SelectedIndex = 2;
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        private TcpListener listener;
        private ModbusSlave slave;
        public SerialPort Slave_serialPort = null;
        private string GetSlave = "";
        public ModbusSerialSlave mobusslave = null;

        private void btn_SlaveListen_Click(object sender, EventArgs e)
        {
            try
            {
                if (Slave_serialPort != null)
                {
                    if (Slave_serialPort.IsOpen)
                    {
                        W.ABBmessage(message_lbo, "请暂停modbus串行");
                        return;
                    }
                    if (txt_SlaveIP.Text == "" || txt_port.Text == "")
                    {
                        return;
                    }
                }
                listener = new TcpListener(IPAddress.Parse(txt_SlaveIP.Text), Convert.ToInt32(txt_port.Text));
                if (btn_SlaveListen.Text == "暂停")
                {
                    slave.Dispose();
                    listener.Stop();
                    btn_SlaveListen.Text = "打开";
                    listener = null;
                    return;
                }
                else
                {
                    listener.Start();
                    GetSlave = "TcpSlave";
                    btn_SlaveListen.Text = "暂停";
                    stationSlave_txb.Text = "1";
                    startadress_txt.Text = "0";
                    ReadNum_txt.Text = "10";
                    stationSlave_txb.ReadOnly = true;
                    startadress_txt.ReadOnly = true;
                }
                slave = ModbusTcpSlave.CreateTcp(1, listener);
                //创建寄存器存储对象
                slave.DataStore = DataStoreFactory.CreateDefaultDataStore();
                ModbusSlavPoll_dgv(Modbus_dgv);
                //订阅数据到达事件，可以在此事件中读取寄存器
                slave.DataStore.DataStoreWrittenTo += new EventHandler<DataStoreEventArgs>((obj, o) =>
                {
                    int StartAddress = (int)o.StartAddress;
                    switch (o.ModbusDataType)
                    {
                        case ModbusDataType.Coil:   //code 5
                            ModbusDataCollection<bool> discretes = slave.DataStore.CoilDiscretes;
                            this.BeginInvoke(new Action(delegate
                            {
                                //ckb_CD_1.Checked = discretes[1];
                                if (discretes[StartAddress + 1])
                                {
                                    Modbus_dgv[2, StartAddress].Value = 1;
                                }
                                else
                                {
                                    Modbus_dgv[2, StartAddress].Value = 0;
                                }
                            }));
                            break;

                        case ModbusDataType.HoldingRegister:   //code 15
                            ModbusDataCollection<ushort> holdingRegisters = slave.DataStore.HoldingRegisters;
                            this.BeginInvoke(new Action(delegate
                            {
                                Modbus_dgv[2, StartAddress].Value = holdingRegisters[StartAddress + 1].ToString();
                            }));
                            break;
                            // ModbusDataType.Coil;
                            //ModbusDataType.Input;
                            //ModbusDataType.InputRegister;
                            //ModbusDataType.HoldingRegister;
                    }
                });

                slave.DataStore.DataStoreReadFrom += new EventHandler<DataStoreEventArgs>((obj, o) =>
                {

                });

                //此事件，待补充
                slave.ModbusSlaveRequestReceived += new EventHandler<ModbusSlaveRequestEventArgs>((obj, o) =>
                {


                });
                //此事件，待补充
                slave.WriteComplete += new EventHandler<ModbusSlaveRequestEventArgs>((obj, o) =>
                {

                });

                slave.Listen();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
        public void ModbusSlavPoll_dgv(DataGridView Modbus_dgv)
        {
            try
            {
                string[] DataName = { "序号", "Alias", "Vlaue" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2" };
                int[] SizeWith = { 50, 100, 100 };
                int Numdata = 0;
                Modbus_dgv.Columns.Clear();
                Modbus_dgv.Rows.Clear();
                Function_cbo.Items.AddRange(new string[] { "01 Coil Status {0x}",
                "02 Input Status {1x}","03 Holding Register {4x}","04 Input Registers {3x}"});
                Function_cbo.SelectedIndex = 2;
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                Modbus_dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头居中
                Modbus_dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中


                this.BeginInvoke(new Action(delegate
                {
                    for (int i = 0; i < dgv.Length; i++)
                    {
                        dgv[i] = new DataGridViewColumn()
                        {
                            Name = DataHeaderText[i],
                            HeaderText = DataName[i],
                            Width = SizeWith[i],
                            CellTemplate = new DataGridViewTextBoxCell()
                        };
                        Modbus_dgv.Columns.Add(dgv[i]);
                    }
                    int ReadNum = Convert.ToInt32(ReadNum_txt.Text);
                    for (int i = 0; i < ReadNum; i++)
                    {
                        Modbus_dgv.Rows.Add();
                        Modbus_dgv[0, i].Value = i;
                        Modbus_dgv[2, i].Value = "0";
                    }
                    this.Modbus_dgv.Columns[0].ReadOnly = true;     //禁止i列单元格编辑
                    for (int i = 0; i < this.NumBoolData_Dgb.Columns.Count; i++)
                    {
                        this.Modbus_dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                    }
                    this.Modbus_dgv.AllowUserToAddRows = false;  //关闭自动添加行
                }));
            }
            catch (Exception ex)
            {

            }
        }
        private void Slaveconnect_btn_Click(object sender, EventArgs e)
        {
            Slave_serialPort = new SerialPort();
            if (listener != null)
            {
                W.ABBmessage(message_lbo, "请暂停Modbus TCP");
                return;
            }
            if (!Slave_serialPort.IsOpen)
            {
                try
                {
                    Slave_serialPort.PortName = SlaveSerialPort_cbb.Text;
                    Slave_serialPort.BaudRate = serialBaud[SlaveserialBaud_cbb.SelectedIndex];
                    Slave_serialPort.DataBits = serinlDataBi[SlaveserialDatabit_cbb.SelectedIndex];
                    Slave_serialPort.StopBits = serialStopBit[SlaveserialStopbit_cbb.SelectedIndex];
                    Slave_serialPort.Parity = serialParity[SlaveserialParity_cbb.SelectedIndex];
                    if (Slaveconnect_btn.Text == "暂停")
                    {
                        mobusslave.Dispose();
                        mobusslave = null;
                        Slave_serialPort.Close();
                        Slave_serialPort.Dispose();
                        Slaveconnect_btn.Text = "打开";
                    }
                    else
                    {
                        Slave_serialPort.Open();
                        GetSlave = "serialPortTcp";
                        Slaveconnect_btn.Text = "暂停";
                        stationSlave_txb.Text = "1";
                        startadress_txt.Text = "0";
                        ReadNum_txt.Text = "10";
                        stationSlave_txb.ReadOnly = true;
                        startadress_txt.ReadOnly = true;
                    }

                    if (RTUSlave_rtb.Checked)
                    {
                        mobusslave = ModbusSerialSlave.CreateRtu(0x01, Slave_serialPort);

                    }
                    else
                    {
                        mobusslave = ModbusSerialSlave.CreateAscii(1, Slave_serialPort);
                    }


                    mobusslave.DataStore = DataStoreFactory.CreateDefaultDataStore(32, 32, 16, 16);
                    ModbusSlavPoll_dgv(Modbus_dgv);
                    mobusslave.DataStore.DataStoreWrittenTo += new EventHandler<DataStoreEventArgs>((obj, o) =>
                    {
                        int StartAddress = (int)o.StartAddress;
                        switch (o.ModbusDataType)
                        {
                            case ModbusDataType.Coil:   //code 5
                                ModbusDataCollection<bool> discretes = mobusslave.DataStore.CoilDiscretes;
                                this.BeginInvoke(new Action(delegate
                                {
                                    //ckb_CD_1.Checked = discretes[1];
                                    if (discretes[StartAddress + 1])
                                    {
                                        Modbus_dgv[2, StartAddress].Value = 1;
                                    }
                                    else
                                    {
                                        Modbus_dgv[2, StartAddress].Value = 0;
                                    }
                                }));
                                break;

                            case ModbusDataType.HoldingRegister:   //code 15
                                ModbusDataCollection<ushort> holdingRegisters = mobusslave.DataStore.HoldingRegisters;
                                this.BeginInvoke(new Action(delegate
                                {
                                    Modbus_dgv[2, StartAddress].Value = holdingRegisters[StartAddress + 1].ToString();
                                }));
                                break;
                                // ModbusDataType.Coil;
                                //ModbusDataType.Input;
                                //ModbusDataType.InputRegister;
                                //ModbusDataType.HoldingRegister;
                        }
                    });
                    System.Threading.Tasks.Task.Factory.StartNew(new Action(delegate
                    {
                        mobusslave.Listen();
                    }));
                }

                catch
                {
                    throw;
                }
            }
        }
        private void Modbus_dgv_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            try
            {
                if (e.ColumnIndex == 2)
                {
                    int groupindex = 0, offset = 0, value = 0;
                    groupindex = 3;
                    offset = e.RowIndex + 1;
                    value = Convert.ToInt32(Modbus_dgv[2, e.RowIndex].Value.ToString());
                    setValue32(Function_cbo.SelectedIndex, offset, value);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
        public void setValue32(int groupindex, int offset, int value)
        {
            if (groupindex == 2 || groupindex == 3)
            {
                byte[] valueBuf = BitConverter.GetBytes(value);
                ushort a = (ushort)BitConverter.ToUInt32(valueBuf, 0);
                ModbusDataCollection<ushort> data = getRegisterGroup(groupindex);
                data[offset] = a;
            }
            else
            {
                ModbusDataCollection<bool> booldata = getCoil12(groupindex);
                if (value == 0)
                {
                    booldata[offset] = false;
                }
                else
                {
                    booldata[offset] = true;
                }
            }

        }



        private void txt_SlaveIP_MouseClick(object sender, MouseEventArgs e)
        {
            txt_SlaveIP.Text = Getip(txt_SlaveIP.Text);
        }
        public string Getip(string iptxt)
        {
            try
            {
                string name = "";
                if (iptxt == "")
                {
                    name = Dns.GetHostName();
                    IPAddress[] ipadrlist = Dns.GetHostAddresses(name);
                    foreach (IPAddress ipa in ipadrlist)
                    {
                        if (ipa.AddressFamily == AddressFamily.InterNetwork)
                        {
                            iptxt = ipa.ToString();
                            return iptxt;
                        }

                    }
                }


            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, "获取IP失败");
            }
            return iptxt;
        }
        private void ReadNum_txt_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                char KeyChar = e.KeyChar;
                if (KeyChar == (char)Keys.Enter)
                {
                    ModbusSlavPoll_dgv(Modbus_dgv);
                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }
        ModbusDataCollection<ushort> getRegisterGroup(int groupindex)//根据3或4返回适合的寄存器
        {
            switch (groupindex)
            {

                case 2:
                    if (GetSlave == "TcpSlave")
                    {

                        return slave.DataStore.HoldingRegisters; //可修改
                    }
                    else
                    {
                        return mobusslave.DataStore.HoldingRegisters; //可修改
                    }

                case 3:
                    if (GetSlave == "TcpSlave")
                    {
                        return slave.DataStore.InputRegisters;
                    }
                    else
                    {
                        return mobusslave.DataStore.InputRegisters;
                    }
                //不可通过modbus修改
                default:
                    if (GetSlave == "TcpSlave")
                    {
                        return slave.DataStore.InputRegisters;
                    }
                    else
                    {
                        return mobusslave.DataStore.InputRegisters;
                    }
            }
        }
        ModbusDataCollection<bool> getCoil12(int groupindex)
        {
            switch (groupindex)
            {
                case 0:
                    if (GetSlave == "TcpSlave")
                    {
                        return slave.DataStore.CoilDiscretes;  //可修改
                    }
                    else
                    {
                        return mobusslave.DataStore.CoilDiscretes;  //可修改
                    }

                case 1:
                    if (GetSlave == "TcpSlave")
                    {
                        return slave.DataStore.InputDiscretes;  //不可通过modbus修改
                    }
                    else
                    {
                        return mobusslave.DataStore.InputDiscretes;
                    }
                default:
                    if (GetSlave == "TcpSlave")
                    {
                        return slave.DataStore.InputDiscretes;
                    }
                    else
                    {
                        return mobusslave.DataStore.InputDiscretes;
                    }
            }
        }


        #endregion

        #region //modbus poll
        private TcpClient client;
        private ModbusIpMaster master;
        private void GetPollIp_txt_MouseClick(object sender, MouseEventArgs e)
        {
            GetPollIp_txt.Text = Getip(GetPollIp_txt.Text.Trim());
        }
        string GetnumberOfPoints = "", Getpoll = "";
        private void Pollconnect_btn_Click(object sender, EventArgs e)
        {
            try
            {
                client = new TcpClient();
                client.Connect(IPAddress.Parse(GetPollIp_txt.Text.Trim()), Convert.ToInt32(PollPort_txt.Text));
                master = ModbusIpMaster.CreateIp(client);
                if (Pollconnect_btn.Text == "连接")
                {
                    PollId_txt.Text = "1";
                    PollAdress_txt.Text = "0";
                    ReadPoll_txt.Text = "10";
                    GetnumberOfPoints = ReadPoll_txt.Text;
                    Getpoll = "Modbus TCP";
                    ModbusPoll_dgv(Poll_dgv);
                    ModbusPollThread(true);
                    Pollconnect_btn.Text = "断开";
                    W.ABBmessage(message_lbo, "连接成功");
                }
                else
                {
                    client.Close();
                    ModbusPollThread(false);
                    Pollconnect_btn.Text = "连接";
                    W.ABBmessage(message_lbo, "连接已断开");

                }
            }
            catch (Exception ex)
            {
                W.ABBmessage(message_lbo, ex.Message);
            }
        }

        public void ModbusPoll_dgv(DataGridView Poll_dgv)
        {
            try
            {
                string[] DataName = { "序号", "Alias", "Vlaue" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2" };
                int[] SizeWith = { 50, 100, 100 };
                int Numdata = 0;

                Poll_dgv.Columns.Clear();
                Poll_dgv.Rows.Clear();

                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                Poll_dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头居中
                Poll_dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中


                this.BeginInvoke(new Action(delegate
                {
                    for (int i = 0; i < dgv.Length; i++)
                    {
                        dgv[i] = new DataGridViewColumn()
                        {
                            Name = DataHeaderText[i],
                            HeaderText = DataName[i],
                            Width = SizeWith[i],
                            CellTemplate = new DataGridViewTextBoxCell()
                        };
                        Poll_dgv.Columns.Add(dgv[i]);
                    }
                    int ReadNum = Convert.ToInt32(ReadPoll_txt.Text);
                    for (int i = 0; i < ReadNum; i++)
                    {
                        Poll_dgv.Rows.Add();
                        Poll_dgv[0, i].Value = i;
                        Poll_dgv[2, i].Value = "0";
                    }
                    this.Poll_dgv.Columns[0].ReadOnly = true;     //禁止i列单元格编辑
                    for (int i = 0; i < this.NumBoolData_Dgb.Columns.Count; i++)
                    {
                        this.Poll_dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                    }
                    this.Poll_dgv.AllowUserToAddRows = false;  //关闭自动添加行
                }));
            }
            catch (Exception ex)
            {

            }
        }
        private ushort[] GetRegisters = new ushort[] { };
        private SerialPort poll_serialPort = null;
        private ModbusSerialMaster poll_SerialMaster = null;

        private bool[] boolGetRegisters = new bool[] { };



        public void ModbusPollThread(bool start)
        {


            // byte[] slaveAddress = System.Text.Encoding.Default.GetBytes(PollId_txt.Text);
            // ushort startAddress = Convert.ToUInt16(PollAdress_txt.Text);
            Thread thread = new Thread(() =>
            {
                try
                {
                    while (start)
                    {
                        ushort numberOfPoints = Convert.ToUInt16(GetnumberOfPoints);

                        switch (PollFunction_cbb.SelectedIndex)
                        {
                            case 0:
                                if (Getpoll == "serialPortTcp")
                                {
                                    boolGetRegisters = poll_SerialMaster.ReadCoils(1, 0, numberOfPoints);
                                }
                                else
                                {
                                    boolGetRegisters = master.ReadCoils(1, 0, numberOfPoints);
                                }
                                break;
                            case 1:
                                if (Getpoll == "serialPortTcp")
                                {
                                    boolGetRegisters = poll_SerialMaster.ReadInputs(1, 0, numberOfPoints);
                                }
                                else
                                {
                                    boolGetRegisters = master.ReadInputs(1, 0, numberOfPoints);
                                }
                                break;
                            case 2:
                                if (Getpoll == "serialPortTcp")
                                {
                                    GetRegisters = poll_SerialMaster.ReadHoldingRegisters(1, 0, numberOfPoints);
                                }
                                else
                                {
                                    GetRegisters = master.ReadHoldingRegisters(1, 0, numberOfPoints);
                                }
                                break;
                            case 3:
                                if (Getpoll == "serialPortTcp")
                                {
                                    GetRegisters = poll_SerialMaster.ReadInputRegisters(1, 0, numberOfPoints);
                                }
                                else
                                {
                                    GetRegisters = master.ReadInputRegisters(1, 0, numberOfPoints);
                                }
                                break;
                        }

                        if (PollFunction_cbb.SelectedIndex == 0 || PollFunction_cbb.SelectedIndex == 1)
                        {
                            for (int i = 0; i < boolGetRegisters.Length; i++)
                                if (boolGetRegisters[i])
                                {
                                    Poll_dgv[2, i].Value = 1;
                                }
                                else
                                {
                                    Poll_dgv[2, i].Value = 0;
                                }
                        }
                        else
                        {
                            for (int i = 0; i < GetRegisters.Length; i++)
                            {
                                Poll_dgv[2, i].Value = GetRegisters[i].ToString();
                            }
                        }
                    }
                }
                catch
                {
                    return;
                }
            });
            if (start)
            {
                thread.Start();
            }


        }
        private void PollPortconnect_btn_Click(object sender, EventArgs e)
        {
            try
            {
                poll_serialPort = new SerialPort();
                //if (!poll_serialPort.IsOpen)
                //{
                poll_serialPort.PortName = PollSerialPort_cbb.Text;
                poll_serialPort.BaudRate = serialBaud[SlaveserialBaud_cbb.SelectedIndex];
                poll_serialPort.DataBits = serinlDataBi[SlaveserialDatabit_cbb.SelectedIndex];
                poll_serialPort.StopBits = serialStopBit[SlaveserialStopbit_cbb.SelectedIndex];
                poll_serialPort.Parity = serialParity[SlaveserialParity_cbb.SelectedIndex];
                if (PollPortconnect_btn.Text == "暂停")
                {
                    // ModbusPoll_timer.Stop();
                    ModbusPollThread(false);
                    poll_serialPort.Close();
                    poll_serialPort.Dispose();
                    //    poll_SerialMaster.Dispose();
                    poll_SerialMaster = null;
                    PollPortconnect_btn.Text = "打开";

                }
                else
                {
                    poll_serialPort.Open();

                    Getpoll = "serialPortTcp";
                    PollPortconnect_btn.Text = "暂停";
                    PollId_txt.Text = "1";
                    PollAdress_txt.Text = "0";
                    ReadPoll_txt.Text = "10";
                    GetnumberOfPoints = "10";
                    PollId_txt.ReadOnly = true;
                    PollAdress_txt.ReadOnly = true;
                    ModbusPoll_dgv(Poll_dgv);
                    //ModbusPoll_timer.Start();
                    ModbusPollThread(true);
                }

                //}
                if (RTUPoll_rtb.Checked)
                {
                    poll_SerialMaster = ModbusSerialMaster.CreateRtu(poll_serialPort);

                }
                else
                {
                    poll_SerialMaster = ModbusSerialMaster.CreateAscii(poll_serialPort);
                }

                poll_SerialMaster.Transport.Retries = 2;
                poll_SerialMaster.Transport.WriteTimeout = 2000;
                poll_SerialMaster.Transport.ReadTimeout = 2000;

            }
            catch
            {
                W.ABBmessage(message_lbo, "连接失败");
            }
        }
        private void Poll_dgv_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            try
            {
                ushort registerAddress = (ushort)e.RowIndex;
                ushort Vlaue = (ushort)Convert.ToUInt32(Poll_dgv[2, e.RowIndex].Value.ToString());

                switch (PollFunction_cbb.SelectedIndex)
                {
                    case 0:
                        if (Poll_dgv[2, e.RowIndex].Value.ToString() == "0")
                        {
                            if (Getpoll == "serialPortTcp")
                            {
                                poll_SerialMaster.WriteSingleCoil(1, registerAddress, false);
                            }
                            else
                            {
                                master.WriteSingleCoil(registerAddress, false);
                            }
                        }
                        else
                        {
                            if (Getpoll == "serialPortTcp")
                            {
                                poll_SerialMaster.WriteSingleCoil(1, registerAddress, true);
                            }
                            else
                            {
                                master.WriteSingleCoil(registerAddress, true);
                            }
                        }
                        break;
                    case 2:
                        if (Getpoll == "serialPortTcp")
                        {
                            poll_SerialMaster.WriteSingleRegister(1, registerAddress, Vlaue);
                        }
                        else
                        {
                            master.WriteSingleRegister(registerAddress, Vlaue);
                        }
                        break;
                }
            }
            catch
            {
                W.ABBmessage(message_lbo, "写入失败,请检查是否连接");
            }
        }
        #endregion
        #endregion
        /// <summary>
        /// 更新数据
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>


        private void NumBoolData_cms_Opening(object sender, System.ComponentModel.CancelEventArgs e)
        {

        }

        private void Dgv_RapidData()
        {

            try
            {
                string[] DataName = { "数据名称", "任务", "模块", "数据类型", "值", "注释" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Name5" };
                int[] SizeWith = { 200, 100, 120, 110, 100, 200 };
                NumBoolData_Dgb.Columns.Clear();
                NumBoolData_Dgb.Rows.Clear();
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                NumBoolData_Dgb.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头居中
                NumBoolData_Dgb.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中
                NumBoolData_Dgb.RowTemplate.MinimumHeight = 25;
                for (int i = 0; i < dgv.Length; i++)
                {
                    dgv[i] = new DataGridViewColumn()
                    {
                        Name = DataHeaderText[i],
                        HeaderText = DataName[i],
                        Width = SizeWith[i],
                        CellTemplate = new DataGridViewTextBoxCell()  //添加textbox
                    };
                    NumBoolData_Dgb.Columns.Add(dgv[i]);
                }
                for (int i = 0; i < 70; i++)
                {
                    NumBoolData_Dgb.Rows.Add();
                }
                for (int i = 0; i < NumBoolData_Dgb.Columns.Count; i++)
                {
                    NumBoolData_Dgb.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                }
                NumBoolData_Dgb.AllowUserToAddRows = false;  //关闭自动添加行
                NumBoolData_Dgb.AllowUserToResizeRows = false;      //禁止用户改变DataGridView所有行的行高 
                NumBoolData_Dgb.AllowUserToResizeColumns = false;   // 禁止用户改变DataGridView的所有列的列宽
                NumBoolData_Dgb.RowHeadersVisible = false;  //禁用列标题
                NumBoolData_Dgb.CellValueChanged += NumBoolData_Dgb_CellValueChanged;
            }
            catch
            {

            }
        }

        private void ABBJoin_dgv_CellMouseDown(object sender, DataGridViewCellMouseEventArgs e)
        {

        }

        private void ABBJoin_dgv_CellMouseUp(object sender, DataGridViewCellMouseEventArgs e)
        {

        }

        private void RobTarget_cms_Opening(object sender, System.ComponentModel.CancelEventArgs e)
        {

        }

        private void NumBoolData_Dgb_CellValueChanged(object sender, DataGridViewCellEventArgs e)
        {

        }

        private void DataName_cbo_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void userCurve1_Load(object sender, EventArgs e)
        {

        }
        private void userCurve1_MouseWheel(object sender, MouseEventArgs e)
        {
            if (e.Delta > 0)
            {
                userCurve1.ValueMaxLeft = (float)(userCurve1.ValueMaxLeft * 1.1);
            }
            else 
            {
                userCurve1.ValueMaxLeft = (float)(userCurve1.ValueMaxLeft * 0.9);
            }
        }

        private void userGaugeChart1_Load(object sender, EventArgs e)
        {

        }

        private void button7_Click(object sender, EventArgs e)
        {
            if (toolManager == null)
            {
                toolManager = new RobotToolManager("192.168.0.1", 2000);
                toolManager.Connect();
                button7.BackColor = System.Drawing.Color.Green;
                this.numericUpDown1.Enabled = true;
                this.trackBar2.Enabled = true;
                speedRecvTimer = new System.Windows.Forms.Timer();
                speedRecvTimer.Interval = 10;
                speedRecvTimer.Tick += (sender1, e1) =>
                {
                    int speed = 0;
                    if (toolManager != null)
                    {
                        if (this.toolManager.GetCurrentRotSpeed(out speed))
                        {
                            this.textBox2.Text = speed.ToString();
                        }
                        else
                        {
                            this.textBox2.Text = "0";
                        }
                    }
                    else
                    {
                        this.textBox2.Text = "0";
                    }
                };
                speedRecvTimer.Start();
            }
        }

        private void button10_Click(object sender, EventArgs e)
        {
            if (toolManager != null)
            {
                for (int i = 0; i < 5; i++)
                {
                    toolManager.CommandToTool("!!00000,0#");
                    Thread.Sleep(10);
                }
                toolManager.Close();
                toolManager = null;
                button7.BackColor = System.Drawing.Color.DarkRed;
                this.numericUpDown1.Value = 0;
                this.numericUpDown1.Enabled = false;
                this.trackBar2.Value = 0;
                this.trackBar2.Enabled = false;

                speedRecvTimer.Stop();
                speedRecvTimer.Dispose();
                speedRecvTimer = null;
            }
        }

        private void trackBar2_Scroll(object sender, EventArgs e)
        {
            if (this.numericUpDown1.Enabled == true && toolManager != null)
            {
                this.numericUpDown1.Value = this.trackBar2.Value;
                toolManager.AlterSpeedTo(trackBar2.Value);
            }
        }

        private void numericUpDown1_ValueChanged(object sender, EventArgs e)
        {
            if (this.trackBar2.Enabled == true && toolManager != null)
            {
                this.trackBar2.Value = Convert.ToInt32(this.numericUpDown1.Value);
                // int Value = Convert.ToInt32(this.numericUpDown1.Value);
                // this.toolManager.AlterSpeedTo(Value);
            }
        }

        private void numericUpDown1_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter && toolManager != null)
            {
                int Value = Convert.ToInt32(this.numericUpDown1.Value);
                this.toolManager.AlterSpeedTo(Value);
                e.Handled = true;
                e.SuppressKeyPress = true;
                // int Value = Convert.ToInt32(this.numericUpDown1.Value);
                // this.toolManager.AlterSpeedTo(Value);
            }
        }

        private void label43_Click(object sender, EventArgs e)
        {

        }

        private void textBox2_TextChanged(object sender, EventArgs e)
        {

        }

        private void label44_Click(object sender, EventArgs e)
        {

        }

        private void ABBMoveL_dgv_CellMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            if (string.IsNullOrEmpty(txt_tcpvalue.Text))
            {
                MessageBox.Show("TCP距离不能为空");
                return;
            }
            Button button = sender as Button;
            if (!SetValue("1", "T_ROB1", "MainModule", "Function"))
            {
                MessageBox.Show("移动失败");
                return;
            }
            switch (e.ColumnIndex)
            {
                case 0:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("direction", 0, txt_tcpvalue.Text.Trim());
                            break;
                        case 1:
                            SetValue("direction", 1, txt_tcpvalue.Text.Trim());
                            break;
                        case 2:
                            SetValue("direction", 2, txt_tcpvalue.Text.Trim());
                            break;
                    }
                    break;
                case 1:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("direction", 0, "-" + txt_tcpvalue.Text.Trim());
                            break;
                        case 1:
                            SetValue("direction", 1, "-" + txt_tcpvalue.Text.Trim());
                            break;
                        case 2:
                            SetValue("direction", 2, "-" + txt_tcpvalue.Text.Trim());
                            break;
                    }
                    break;
                case 2:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("direction", 3, "2");
                            break;
                        case 1:
                            SetValue("direction", 4, "2");
                            break;
                        case 2:
                            SetValue("direction", 5, "2");
                            break;
                    }
                    break;
                case 3:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("direction", 3, "-2");
                            break;
                        case 1:
                            SetValue("direction", 4, "-2");
                            break;
                        case 2:
                            SetValue("direction", 5, "-2");
                            break;
                    }
                    break;
            }
        }

        private void ABBJoin_dgv_CellMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            if (string.IsNullOrEmpty(txt_jointValue.Text))
            {
                MessageBox.Show("TCP距离不能为空");
                return;
            }

            if (!SetValue("2", "T_ROB1", "MainModule", "Function"))
            {
                MessageBox.Show("移动失败");
                return;
            }
            switch (e.ColumnIndex)
            {
                case 0:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("joint", 0, txt_jointValue.Text.Trim());
                            break;
                        case 1:
                            SetValue("joint", 1, txt_jointValue.Text.Trim());
                            break;
                        case 2:
                            SetValue("joint", 2, txt_jointValue.Text.Trim());
                            break;
                    }
                    break;
                case 1:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("joint", 0, "-" + txt_jointValue.Text.Trim());
                            break;
                        case 1:
                            SetValue("joint", 1, "-" + txt_jointValue.Text.Trim());
                            break;
                        case 2:
                            SetValue("joint", 2, "-" + txt_jointValue.Text.Trim());
                            break;
                    }
                    break;
                case 2:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("joint", 3, txt_jointValue.Text.Trim());
                            break;
                        case 1:
                            SetValue("joint", 4, txt_jointValue.Text.Trim());
                            break;
                        case 2:
                            SetValue("joint", 5, txt_jointValue.Text.Trim());
                            break;
                    }
                    break;
                case 3:
                    switch (e.RowIndex)
                    {
                        case 0:
                            SetValue("joint", 3, "-" + txt_jointValue.Text.Trim());
                            break;
                        case 1:
                            SetValue("joint", 4, "-" + txt_jointValue.Text.Trim());
                            break;
                        case 2:
                            SetValue("joint", 5, "-" + txt_jointValue.Text.Trim());
                            break;
                    }
                    break;
            }
        }

        private void button12_Click(object sender, EventArgs e)
        {
            GetPos_timer.Stop();
            //string strFileFullName = string.Empty;
            //string strFileNmae = string.Empty;
            //OpenFileDialog ofd = new OpenFileDialog();
            //if (ofd.ShowDialog() == DialogResult.OK)
            //{
            //    strFileFullName = ofd.FileName;
            //    strFileNmae = ofd.SafeFileName;
            //}
            //try
            //{
            //    string remoteDir = controller.FileSystem.RemoteDirectory;
            //    if (controller.FileSystem.FileExists("MainModule.mod"))
            //    {
            //        controller.FileSystem.PutFile(strFileFullName,strFileNmae,true);
            //        MessageBox.Show("上传成功");
            //    }
            //    else
            //    {
            //        controller.FileSystem.PutFile(strFileFullName, strFileNmae);
            //        MessageBox.Show("上传成功");
            //    }
            //    using (Mastership.Request(this.controller.Rapid))
            //    {
            //        bool bLoadSuccess = tasks[0].LoadModuleFromFile("MainModule.mod", RapidLoadMode.Replace);
            //        if (bLoadSuccess)
            //        {
            //            W.ABBmessage(message_lbo, "修改成功");
            //        }

            //    }
            //}
            //catch
            //{

            //}
        }

        private void txt_tcpvalue_TextChanged(object sender, EventArgs e)
        {

        }

        private void label45_Click(object sender, EventArgs e)
        {

        }

        private void label47_Click(object sender, EventArgs e)
        {

        }

        public bool SetValue(string newValue, params string[] rapidData)
        {
            try
            {
                RapidData rd = controller.Rapid.GetRapidData(rapidData[0], rapidData[1], rapidData[2]);
                IRapidData data = rd.Value;
                data.FillFromString(newValue);
                using (Mastership.Request(controller.Rapid))
                {
                    rd.Value = data;
                }
            }
            catch
            {
                return false;
            }
            return true;
        }
        //public bool SetValue(Func<IRapidData> data, params string[] rapidData)
        //{
        //    try
        //    {
        //        //RapidData rd = controller.Rapid.GetRapidData(rapidData[0], rapidData[1], rapidData[2]);
        //        IRapidData _data = data();
        //        using (Mastership.Request(controller.Rapid))
        //        {
        //            rd.Value = data();
        //            _data.
        //        }
        //    }
        //    catch
        //    {
        //        return false;
        //    }
        //    return true;
        //}
        private bool SetValue(string name, int index, string value)
        {
            if (controller == null || !controller.Connected) return false;
            RapidData rd = controller.Rapid.GetRapidData("T_ROB1", "MainModule", name);
            IRapidData data = rd.ReadItem(index);
            data.Fill(value);
            using (Mastership.Request(controller.Rapid))
            {
                rd.WriteItem(data, index);
            }
            return true;
        }

        private void Dgv_robtargetData()
        {

            try
            {
                string[] DataName = { "数据名称", "任务", "模块", "数据类型", "X", "Y", "Z", "RX", "RY", "RZ" };
                string[] DataHeaderText = { "Name0", "Name1", "Name2", "Name3", "Name4", "Name5", "Name6", "Name7", "Name8", "Name9", "Name10" };
                int[] SizeWith = { 150, 100, 120, 110, 90, 90, 90, 90, 90, 90, 90 };
                RobTarget_Dgv.Columns.Clear();
                RobTarget_Dgv.Rows.Clear();
                DataGridViewColumn[] dgv = new DataGridViewColumn[DataName.Length];
                RobTarget_Dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;  //列头居中
                RobTarget_Dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;   //文本居中
                RobTarget_Dgv.RowTemplate.MinimumHeight = 25;
                for (int i = 0; i < dgv.Length; i++)
                {
                    dgv[i] = new DataGridViewColumn()
                    {
                        Name = DataHeaderText[i],
                        HeaderText = DataName[i],
                        Width = SizeWith[i],
                        CellTemplate = new DataGridViewTextBoxCell()  //添加textbox
                    };
                    RobTarget_Dgv.Columns.Add(dgv[i]);
                }
                for (int i = 0; i < 70; i++)
                {
                    RobTarget_Dgv.Rows.Add();
                }
                for (int i = 0; i < RobTarget_Dgv.Columns.Count; i++)
                {
                    RobTarget_Dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
                }
                RobTarget_Dgv.AllowUserToAddRows = false;  //关闭自动添加行
                RobTarget_Dgv.AllowUserToResizeRows = false;      //禁止用户改变DataGridView所有行的行高 
                RobTarget_Dgv.AllowUserToResizeColumns = false;   // 禁止用户改变DataGridView的所有列的列宽
                RobTarget_Dgv.RowHeadersVisible = false;  //禁用列标题
                                                          // NumBoolData_Dgb.CellValueChanged += NumBoolData_Dgb_CellValueChanged;
            }
            catch
            {

            }
        }
    }
}
