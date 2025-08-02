using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using ABB.Robotics.Controllers;
using ABB.Robotics.Controllers.Discovery;
using ABB.Robotics.Controllers.RapidDomain;

namespace Test_Controll
{
    class All_Controll_Method
    {
        public ControllerInfoCollection controllers = null;
        // 日志log栏显示方法
        public List<string> errLogger(List<string> err, string str)
        {
            err.Add(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "    " + str);
            //Console.Write(err.ToArray());
            return err;
        }
        // 通过Netscanner建立连接，扫描网络
        public void Scan()
        {
            NetworkScanner netscan = new NetworkScanner();
            netscan.Scan();
            controllers = netscan.Controllers;

        }
        // 获取控制器
       public Controller GetController(int Select)
        {
            return new Controller(controllers[Select]);
     }

        public int Start(Controller c, out List<string> result, string Task_name, ExecutionCycle cycle, ExecutionMode execution)
        {
            result = new List<string>();
            if (c == null)
            {
                result.Add("[error]    没有连接控制器");
                return -1;
            }
            else
            {
                return RAPID_ProgramStart(c, out result, Task_name, cycle, execution);

            }
        }

        public int Stop(Controller c, out List<string> result)
        {
            result = new List<string>();
            if (c == null)
            {
                result.Add("[error]    没有连接控制器");
                return -1;
            }
            else
            {
                return RAPID_ProgramStop(c, out result);

            }
        }

        private int RAPID_ProgramStart(Controller c, out List<string> result, string Task_name, ExecutionCycle Cycle, ExecutionMode execution)
        {
            result = new List<string>();
            try
            {
                if (c.OperatingMode != ControllerOperatingMode.Auto)
                {
                    result.Add("[error]    机器人请打自动模式");
                    return -1;
                }
                if (c.State != ControllerState.MotorsOn)
                {
                    result.Add("[error]  电机请上电");
                    return -1;
                }
                if (c.AuthenticationSystem.CheckDemandGrant(Grant.ExecuteRapid)) {
                    using (Mastership.Request(c.Rapid))
                    {
                        ABB.Robotics.Controllers.RapidDomain.Task task = c.Rapid.GetTask(Task_name);
                        RegainMode regain = RegainMode.Regain;
                        //ExecutionMode execution = ExecutionMode.Continuous;
                        c.Rapid.Start(regain, execution, Cycle);
                        //c.Rapid.Start();
                        //m.Release();
                        //result.Add("[msg]    程序运行");
                    }
                    return 0;
                }
                return -1;
            }
            catch (Exception ex)
            {
                result.Add("[error]" + ex.ToString());
                return -1;
            }
        }

        private int RAPID_ProgramStop(Controller c, out List<string> result)
        {
            result = new List<string>();
            c.Logon(ABB.Robotics.Controllers.UserInfo.DefaultUser);
            try
            {
                if (c.OperatingMode != ControllerOperatingMode.Auto)
                {
                    result.Add("[error]    机器人请打自动模式");
                    return -1;
                }
                if (!c.AuthenticationSystem.CheckDemandGrant(Grant.ExecuteRapid))
                    c.AuthenticationSystem.DemandGrant(Grant.ExecuteRapid);
                {
                    using (Mastership m = Mastership.Request(c.Rapid))
                    {
                        try
                        {
                            c.Rapid.Stop(StopMode.Immediate);
                            m.Release();
                            //result.Add("[msg]    Program Stop");
                        }
                        catch (Exception ex)
                        {
                            result.Add("[error]" + ex.ToString());
                            m.Release();
                            return -1;
                        }
                    }
                }
                return -1;
            }
            catch (Exception ex)
            {
                result.Add("[error]" + ex.ToString());
                return -1;
            }
        }

        public int PPtoMain(Controller c, out List<string> result)
        {
            result = new List<string>();
            if (c == null)
            {
                result.Add("[error]    没有连接控制器");
                return -1;
            }
            else
            {
                foreach (ABB.Robotics.Controllers.RapidDomain.Task t in c.Rapid.GetTasks())
                {
                    int re = RAPID_ProgramReset(c, out result, t.Name);
                    if (re == -1)
                    {
                        return -1;
                    }
                }
                return 0;
            }
        }

        private int RAPID_ProgramReset(Controller c, out List<string> result, string taskname)
        {
            result = new List<string>();
            c.Logon(ABB.Robotics.Controllers.UserInfo.DefaultUser);
            try
            {
                if (c.OperatingMode != ControllerOperatingMode.Auto)
                {
                    result.Add("[error]    需要自动模式");
                    return -1;
                }

                if (!c.AuthenticationSystem.CheckDemandGrant(Grant.ExecuteRapid))
                    c.AuthenticationSystem.DemandGrant(Grant.ExecuteRapid);
                using (Mastership m = Mastership.Request(c.Rapid))
                {
                    try
                    {
                        c.Rapid.GetTask(taskname).ResetProgramPointer();
                        result.Add("[msg]    Program Reset");
                        m.Release();
                    }
                    catch (Exception ex)
                    {
                        result.Add("[error]" + ex.ToString());
                        m.Release();
                        return -1;
                    }
                }
                return 0;
            }
            catch (Exception ex)
            {
                result.Add("[error]" + ex.ToString());
                return -1;
            }
        }

        public int Operating_Mode(Controller c, out List<string> result, ControllerOperatingMode Change_Mode)
        {
            result = new List<string>();
            VirtualPanel vp = VirtualPanel.Attach(c);
            try
            {
                vp.BeginChangeOperatingMode(Change_Mode, new AsyncCallback(ChangeMode), vp);
            }
            catch (ABB.Robotics.TimeoutException ex)
            {
                result.Add("[error]    切换模式错误" + "\r\n"+ex);
                return -1;
            }
            vp.Dispose();
            return 0;
        }

        private void ChangeMode(IAsyncResult iar)
        {
            VirtualPanel vp = (VirtualPanel)iar.AsyncState;
            vp.EndChangeOperatingMode(iar);
            //vp.Dispose();
        }


    }


}
