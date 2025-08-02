using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ABB.Robotics.Controllers.Discovery;
using ABB.Robotics.Controllers.RapidDomain;
using ABB.Robotics.Controllers.IOSystemDomain;
using ABB.Robotics.Controllers.MotionDomain;
using ABB.Robotics.Controllers.EventLogDomain;
using ABB.Robotics.Controllers;
using System.Windows.Forms;
using System.Collections.ObjectModel;
using ABB_1230;
using System.IO;
using System.Drawing;
using DocumentFormat.OpenXml.Drawing.Charts;
using static ClosedXML.Excel.XLPredefinedFormat;

namespace ABB_二次开发1230
{
  public  class WinMove
    {
    
        public  void ABBMove(Controller controller,string Numdata,string Count)
        {
            using (Mastership.Request(controller.Rapid))
            {
                RapidData rd = controller.Rapid.GetRapidData("T_ROB1", "Module1", Numdata);
                Num number = (Num)rd.Value;
                number.FillFromString2(Count);
                rd.Value = number;
                rd.Log = true;
               // MessageBox.Show("已更改" + rd.Value.ToString());
            }
        }

        public bool SetValue(Controller controller,string newValue,params string[] rapidData)
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
        public void ABBMovedistance(Controller controller,ListBox lbx, string Numdata, string Count,string DataType)
        {
            try
            {
                if (controller == null)
                {
                    return;
                 }
                //if (controller.Rapid.GetRapidData("T_ROB1", "Module1", Numdata) == null || controller == null)
                //{
                //    return;
                //}
                using (Mastership.Request(controller.Rapid))
                {
                    RapidData rd = controller.Rapid.GetRapidData("T_ROB1", "Module1", Numdata);
                    switch (DataType)
                    {
                        case "num":
                            Num number = (Num)rd.Value;
                            number.FillFromString2(Count);
                            rd.Value = number;
                            rd.Log = true;
                            break;
                        case "bool":
                            Bool boolber = (Bool)rd.Value;
                            boolber.FillFromString2(Count);
                            rd.Value = boolber;
                            rd.Log = true;
                            break;
                        case "string":
                            ABB.Robotics.Controllers.RapidDomain.String stringber = (ABB.Robotics.Controllers.RapidDomain.String)rd.Value;
                            stringber.FillFromString(Count);
                            rd.Value = stringber;
                            rd.Log = true;
                            break;
                    }
                    ABBmessage(lbx, rd.Name + " 已更改：" + rd.Value.ToString());
                    //number.FillFromString2(Count);
                    //rd.Value = number;
                    //rd.Log = true;
                    //MessageBox.Show("已更改" + rd.Value.ToString());
                }
            }
            catch (Exception ex)
            {
            }
        }

        public void ArrayDataWrite(Controller controller, string DataName, 
            string DataValue,string DataType,int arrayLeange, int arrayNumber1,int arrayNumber2,int arrayNumber3)
        {
            try
            {
                using (Mastership.Request(controller.Rapid))
                {
                    RapidData rd = controller.Rapid.GetRapidData("T_ROB1", "MainModule", DataName);
                    if (rd.IsArray)
                    {
                        if (DataType == "num")
                        {
                            switch (arrayLeange)
                            {
                                case 1:
                                    {
                                        Num nTemp = (Num)rd.ReadItem(arrayNumber1);
                                        nTemp.Value = Convert.ToDouble(DataValue);
                                        rd.WriteItem(nTemp, arrayNumber1);
                                    }
                                    break;
                                case 2:
                                    {
                                        Num nTemp = (Num)rd.ReadItem(arrayNumber1, arrayNumber2);
                                        nTemp.Value = Convert.ToDouble(DataValue);
                                        rd.WriteItem(nTemp, arrayNumber1, arrayNumber2);
                                    }
                                    break;
                                case 3:
                                    {
                                        Num nTemp = (Num)rd.ReadItem(arrayNumber1, arrayNumber2, arrayNumber3);
                                        nTemp.Value = Convert.ToDouble(DataValue);
                                        rd.WriteItem(nTemp, arrayNumber1, arrayNumber2, arrayNumber3);
                                    }
                                    break;
                            }
                        }
                        else if (DataType == "bool")
                        {
                            Bool nTemp = (Bool)rd.ReadItem(arrayNumber1);
                            nTemp.FillFromString2(DataValue);
                            nTemp.Value = nTemp;
                            rd.WriteItem(nTemp, arrayNumber1);
                        }
                        else if (DataType == "string")
                        {
                            ABB.Robotics.Controllers.RapidDomain.String nTemp = (ABB.Robotics.Controllers.RapidDomain.String)rd.ReadItem(arrayNumber1);
                            nTemp.FillFromString(DataValue);
                            nTemp.Value = nTemp;
                            rd.WriteItem(nTemp, arrayNumber1);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("写入失败");
            }
        }

        public void ABBsingal(Controller controller,ListBox lbx,string SingalName,int SignalVlaue,bool pulseSignal)        
        {
            try
            {
                Signal signal = controller.IOSystem.GetSignal(SingalName);
                DigitalSignal sig = (DigitalSignal)signal;
                if (pulseSignal == true)
                {
                    sig.Pulse(SignalVlaue);
                    // MessageBox.Show("已设置" + SingalName + "为：1");
                    ABBmessage(lbx, "已设置" + SingalName + "为：1");
                    return;
                }
                
                if (SignalVlaue == 1)
                {
                    sig.Set();
                    ABBmessage(lbx, "已设置" + SingalName + "为：1");
                }
                else
                {
                    sig.Reset();
                    //  MessageBox.Show("已设置" + SingalName + "为：0");
                    ABBmessage(lbx, "已设置" + SingalName + "为：0");
                }
            }
            catch (Exception ex)
            {
                ABBmessage(lbx, ex.Message);
            }
        }

        public string arithmetic(string str)
        {
                if (str.Contains("+"))
                {
                    int t = str.IndexOf("+", 0);
                    string str1 = str.Substring(0, t);
                    string str2 = str.Substring(t, str.Length - t);
                    string str3 = str2.Remove(0, 1);
                    double dou0 = double.Parse(str1);
                    double dou1 = double.Parse(str3);
                    double dou2 = dou0 + dou1;
                    return dou2.ToString();
                }
                else if (str.Contains("-"))
                {
                    int t = str.IndexOf("-", 0);
                    string str1 = str.Substring(0, t);
                    string str2 = str.Substring(t, str.Length - t);
                    string str3 = str2.Remove(0, 1);
                    double dou0 = double.Parse(str1);
                    double dou1 = double.Parse(str3);
                    double dou2 = dou0 - dou1;
                    return dou2.ToString();
                }
                else
                {
                    return str;
                }
            }

        public void RobTargetData(Controller controller,string RobTargetName,string X,string Y,string Z,double RX,double RY,double RZ)
        {
            using (Mastership.Request(controller.Rapid))
            {
         
                RapidData rd = controller.Rapid.GetRapidData("T_ROB1", "Module1", RobTargetName);
                RobTarget rt = (RobTarget)rd.Value; 
                    rt.Trans.X = Convert.ToSingle(X);
                    rt.Trans.Y = Convert.ToSingle(Y);
                    rt.Trans.Z = Convert.ToSingle(Z);
                    rt.Rot.FillFromEulerAngles(RX, RY, RZ);
                    rd.Value = rt;
                    MessageBox.Show("修改成功" + RobTargetName);
            }
        }

        public void RobTargetDataTwo(Controller controller, string RobTargetName)
        {
            using (Mastership.Request(controller.Rapid))
            {
                RapidData rd = controller.Rapid.GetRapidData("T_ROB1", "Module1", RobTargetName);
                RobTarget rt = (RobTarget)rd.Value;
                RobTarget aRobTarget = controller.MotionSystem.ActiveMechanicalUnit.GetPosition(CoordinateSystemType.World);
                rt.Trans.X = aRobTarget.Trans.X;
                rt.Trans.Y = aRobTarget.Trans.Y;
                rt.Trans.Z = aRobTarget.Trans.Z;
                rt.Rot.Q1 = aRobTarget.Rot.Q1;
                rt.Rot.Q2 = aRobTarget.Rot.Q2;
                rt.Rot.Q3 = aRobTarget.Rot.Q3;
                rt.Rot.Q4 = aRobTarget.Rot.Q4;
                rt.Robconf.Cf1 = aRobTarget.Robconf.Cf1;
                rt.Robconf.Cf4 = aRobTarget.Robconf.Cf4;
                rt.Robconf.Cf6 = aRobTarget.Robconf.Cf6;
                rt.Robconf.Cfx = aRobTarget.Robconf.Cfx;
                rt.Extax.Eax_a = aRobTarget.Extax.Eax_a;
                rt.Extax.Eax_b = aRobTarget.Extax.Eax_b;
                rt.Extax.Eax_c = aRobTarget.Extax.Eax_c;
                rt.Extax.Eax_d = aRobTarget.Extax.Eax_d;
                rt.Extax.Eax_e = aRobTarget.Extax.Eax_e;
                rt.Extax.Eax_f = aRobTarget.Extax.Eax_f;
                rd.Value = rt;
                MessageBox.Show("修改成功");
            }
        }

        public RapidSymbol[] rapidSymbol(Controller controller, string DataType)
        {

                RapidSymbolSearchProperties prop = RapidSymbolSearchProperties.CreateDefault();
                ABB.Robotics.Controllers.RapidDomain.Task[] tasks = controller.Rapid.GetTasks();
                prop.Types = SymbolTypes.Data;
                prop.InUse = false;    //在使用中包含符号
                prop.LocalSymbols = false;  //包括当地的符号。
                prop.Recursive = true;
                prop.SearchMethod = SymbolSearchMethod.Block;   //搜索当前的模块
                return tasks[0].SearchRapidSymbol(prop, DataType, string.Empty);
            
        }

        

        public void dataGridViewSize(DataGridView DI_Dgv, bool addRow )
        {
            int Datawidth = 0;
            //for (int i = 0; i < DI_Dgv.Columns.Count; i++)
            //{
            //    DI_Dgv.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
            //    Datawidth += DI_Dgv.Columns[i].Width;  //记录整个DataGridView的宽度
            //}
            ////判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
            ////则将DataGridView的列自动调整模式设置为显示的列即可，
            ////如果是小于原来设定的宽度，将模式改为填充。
            //if (Datawidth > DI_Dgv.Size.Width)
            //{
            //    DI_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
            //}
            //else
            //{
            //    DI_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            //}
            DI_Dgv.Columns[0].Frozen = true;   //冻结某列 从左开始 0，1，2
            DI_Dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
            DI_Dgv.AllowUserToAddRows = addRow;  //关闭自动添加行
                                                 //   DI_Dgv.SelectionMode = DataGridViewSelectionMode.FullRowSelect; //全选
            DI_Dgv.Columns[1].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleLeft; //居中
            for (int i = 0; i < DI_Dgv.Columns.Count; i++)
            {
                DI_Dgv.Columns[i].SortMode = DataGridViewColumnSortMode.NotSortable;  //禁止全部列排序
            }
        }
        public void RapidError(Controller controller, ABB.Robotics.Controllers.RapidDomain.Task tasks)
        {
            string RapidError = "";
            using (Mastership.Request(controller.Rapid))
            {
                tasks = controller.Rapid.GetTask("T_ROB1");
                CheckProgramResult ch = tasks.CheckProgram();
                ReadOnlyCollection<ProgramError> ac = ch.Errors;
                if (ac.Count == 0)
                {
                    MessageBox.Show("未出现任何错误");
                    return;
                }
                foreach (ProgramError error in ac)
                {
                    RapidError = $"  {error.TaskName} - {error.ModuleName} - 行 {error.Line} 错误 " + "\r\n";
                }
                MessageBox.Show(RapidError);
            }
        }

        public void ABBmessage(ListBox lbx ,string str)
        {
            lbx.Items.Add(System.DateTime.Now.ToLongTimeString().ToString()+"  " + str);
            lbx.SelectedIndex = lbx.Items.Count - 1;  //显示最后一行
            lbx.TopIndex = lbx.Items.Count - 1;   //进行全选
        }

        public void ABBDatanote(Controller controller,DataGridView NumBoolData_Dgb,string filetxt ,int writenote)
        {
            try
            {
                string GetDatanote = "";
                string filepath = "";
              
                if (System.Environment.CurrentDirectory + "\\" + "ABBnotetxt" + "\\"+ filetxt == null)    //controller.FileSystem.LocalDirectory
                {
                    using (FileStream fswrite = new FileStream(filepath, FileMode.OpenOrCreate, FileAccess.Write))
                    {

                    }
                    filepath = System.Environment.CurrentDirectory + "\\" + "ABBnotetxt" + "\\" + filetxt; //获取PC debug文件夹的绝对路径
                }
                else
                {
                    filepath = System.Environment.CurrentDirectory + "\\" + "ABBnotetxt" + "\\" + filetxt; //获取PC debug文件夹的绝对路径
                }
                for (int i = 0; i < NumBoolData_Dgb.Rows.Count; i++)
                {
                    if (NumBoolData_Dgb[writenote, i].Value != null)
                    {
                        string Datanote = NumBoolData_Dgb[writenote, i].Value.ToString();//获取变量注释
                        string DataName = NumBoolData_Dgb[0, i].Value.ToString();//获取变量名
                        GetDatanote += $"{DataName}/{Datanote}\r\n";  //名称和注释字符串拼接在一起","隔开
                    }
                }
                if (File.Exists(filepath))  //判断文件是否存在
                {
                    File.Delete(filepath);   //存在就删除文件
                }
                using (FileStream fswrite = new FileStream(filepath, FileMode.OpenOrCreate, FileAccess.Write))
                {
                    byte[] buffer = Encoding.Default.GetBytes(GetDatanote);
                    fswrite.Write(buffer, 0, buffer.Length);
                }
            }
            catch(Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "WindowFromPoint")]
        static extern IntPtr WindowFromPoint(Point pt);
        public void dgv_MouseWheel(DataGridView NumBoolData_Dgb, MouseEventArgs e, Point p)
        {
           
            //Point p = PointToScreen(e.Location);
            if ((WindowFromPoint(p)) == NumBoolData_Dgb.Handle)//鼠标指针在框内
            {
                if (e.Delta > 0)
                {
                    if (NumBoolData_Dgb.FirstDisplayedScrollingRowIndex - 5 < 0)
                    {
                        NumBoolData_Dgb.FirstDisplayedScrollingRowIndex = 0;
                    }
                    else
                    {
                        NumBoolData_Dgb.FirstDisplayedScrollingRowIndex = NumBoolData_Dgb.FirstDisplayedScrollingRowIndex - 5;
                    }
                }
                else
                {
                    NumBoolData_Dgb.FirstDisplayedScrollingRowIndex = NumBoolData_Dgb.FirstDisplayedScrollingRowIndex + 5;
                }
            }
        }
        public void ReadDatanote(Controller controller,string readnote,List<string> listNumName,DataGridView NumBoolData_Dgb,int ColumnIndex)
        {
            if (System.Environment.CurrentDirectory + "\\" + "ABBnotetxt"+"\\" +readnote != null)
            {
                string filepath = System.Environment.CurrentDirectory + "\\" + "ABBnotetxt" + "\\" + readnote; //获取PC debug文件夹的绝对路径 
                string fileRead = "";
                using (System.IO.FileStream fsRead = new FileStream(filepath, FileMode.OpenOrCreate, FileAccess.Read))
                {
                    byte[] buffer = new byte[1024 * 1024 * 5];
                    int r = fsRead.Read(buffer, 0, buffer.Length);
                    fileRead = Encoding.Default.GetString(buffer, 0, r);
                }
                fileRead = fileRead.Trim();  //清除空格
                if (fileRead != "")
                {
                    string[] str = fileRead.Split(new string[] { "\r\n" }, StringSplitOptions.None);
                    for (int i = 0; i < str.Length; i++)
                    {
                        int index = str[i].IndexOf("/");  //获取"/"前的字符串索引获取变量名
                        if (index == -1)
                        {
                            continue;
                        }
                        string GetName = str[i].Substring(0, index);  //截取字符串的名字
                        int listindex = listNumName.IndexOf(GetName);  //获取与表格相同名字的变量
                        string Datanote = str[i].Substring(index, str[i].Length - index); //截取字符串的注释
                        Datanote = Datanote.Remove(0, 1);
                        NumBoolData_Dgb[ColumnIndex, listindex].Value = Datanote;  //把注释赋值到第5列对应的位置
                    }
                }
            }
        }
        public void Dgvsize(DataGridView DI_Dgv )
        {
            int Datawidth = 0;
            for (int i = 0; i < DI_Dgv.Columns.Count; i++)
            {
                DI_Dgv.AutoResizeColumn(i, DataGridViewAutoSizeColumnMode.AllCells); //将每一列都调整为自动适应模式
                Datawidth += DI_Dgv.Columns[i].Width;  //记录整个DataGridView的宽度
            }
            //判断调整后的宽度与原来设定的宽度的关系，如果是调整后的宽度大于原来设定的宽度，
            //则将DataGridView的列自动调整模式设置为显示的列即可，
            //如果是小于原来设定的宽度，将模式改为填充。
            if (Datawidth > DI_Dgv.Size.Width)
            {
                DI_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
            }
            else
            {
                DI_Dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            }
        }
    }
    }
