using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Collections.Concurrent;
using System.Windows.Forms.VisualStyles;
using DocumentFormat.OpenXml.Spreadsheet;

namespace CyRobotics
{
    public class RobotToolManager
    {
        private IPAddress ip;
        private Socket socketTube;
        private EndPoint endPoint;

        private bool _ConnectionStats;
        private bool _ConnectCommCanceled;

        private Thread _socketconnThread;
        private Thread _ReceiveThread;
        private Thread _SendThread;
        private Thread _hbThread;
        public RobotToolManager(string ip = "192.168.0.1", int port = 2000)
        {
            socketTube = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            IPAddress ipAddress = IPAddress.Parse(ip);
            endPoint = new IPEndPoint(ipAddress, port);

            _ConnectionStats = false;
            _ConnectCommCanceled = false;

            _socketconnThread = null;
            _ReceiveThread = null;
            _SendThread = null;
            //_hbThread = null;

            _commandsToTool = new ConcurrentQueue<string>();
            _infoFromTool = "0#";
        }

        public bool socketConnected()
        {
            return this._ConnectionStats;
        }
        public int ReConnect() 
        {
            _ConnectionStats = false;
            _ConnectCommCanceled = false;
            if (socketTube == null) 
            {
                socketTube = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            }

            return Connect();
        }
        public int Connect()
        {
            _socketconnThread = new Thread(() =>
            {
                while (_ConnectionStats != true && _ConnectCommCanceled != true)
                {
                    try
                    {
                        this.socketTube.Connect(endPoint);
                        _ConnectionStats = true;
                        Console.WriteLine("Connection:: success");

                        _ReceiveThread = new Thread(() =>
                        {
                            while (this._ConnectCommCanceled == false)
                            {
                                try
                                {
                                    byte[] buffer = new byte[1024];
                                    int length = socketTube.Receive(buffer);
                                    string message = Encoding.UTF8.GetString(buffer, 0, length);
                                    Console.WriteLine("Message Received: {0}", message);
                                    lock (_infoFromTool) 
                                    {
                                        _infoFromTool = message;
                                    }
                                    Thread.Sleep(10);
                                }
                                catch 
                                {
                                    Console.WriteLine("socket Tube broken::quit Receiving");
                                    break;
                                }
                            }
                        });
                        _SendThread = new Thread(() =>
                        {
                            string command;
                            while (this._ConnectCommCanceled == false) 
                            {
                                if ((_commandsToTool.TryDequeue(out command)) == false)
                                {
                                    Thread.Sleep(10);
                                    continue;
                                }
                                else 
                                {
                                    byte[] commandBytes = System.Text.Encoding.UTF8.GetBytes(command);
                                    socketTube.Send(commandBytes);
                                    Thread.Sleep(10);
                                }
                            }
                            Console.WriteLine("send Thread quit");
                        });
                        //_hbThread = new Thread(() => 
                        //{
                        //    while (this._ConnectCommCanceled == false) 
                        //    {
                        //        socketTube.Send(System.Text.Encoding.UTF8.GetBytes("RTM::heartBeat"));
                        //        Thread.Sleep(100);
                        //    }
                        //});
                        _ReceiveThread.Start();
                        _SendThread.Start();
                        //_hbThread.Start();
                        break;
                    }
                    catch
                    {
                        _ConnectionStats = false;
                        this.socketTube.Close();
                        this.socketTube = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                        Console.WriteLine("Connection failed:: reconnecting...");
                        Thread.Sleep(1000);
                    }
                }
            });
            _socketconnThread.Start();
            return 0;
        }
        public void CommandToTool(string command) 
        {
            _commandsToTool.Enqueue(command);
        }
        public void AlterSpeedTo(int speed) 
        {
            speed = (int)(speed * 0.867785714285714 + 17.7714285714283);
            
            StringBuilder builder = new StringBuilder();
            builder.Append("!!");
            //Console.WriteLine(speed);
            int i = 0;
            while ((speed / (10000 / (Int32)(Math.Pow(10, i)))) == 0 && i < 4) 
            {
                builder.Append('0');
                i++;
            }
            builder.Append(speed.ToString());
            builder.Append(',');
            builder.Append((_ConnectionStats? 1:0).ToString());
            builder.Append('#');
            Console.WriteLine(builder.ToString());

            _commandsToTool.Enqueue(builder.ToString());
        }
        public bool GetCurrentRotSpeed(out int speed) 
        {
            if (_ConnectionStats)
            {

                lock (_infoFromTool)
                {
                    string mess = _infoFromTool.Replace("#", "").Replace(" ", "").Replace("\b\a", "");

                    speed = int.Parse(mess);
                    return true;
                }
            }
            else 
            {
                speed = 0;
                return false;
            }
        }
        //public bool GetPowerInfo(out bool _powerOn) 
        //{
        //    lock (_infoFromTool)
        //    {
        //        string mess = _infoFromTool.TrimEnd('#');
        //        string[] messParts = mess.Split(',');
        //        if (messParts.Length == 2)
        //        {
        //            _powerOn = bool.Parse(messParts[1]);
        //            return true;
        //        }
        //        else
        //        {
        //            _powerOn = false;
        //            return false;
        //        }
        //    }
        //}
        public void Close()
        {
            _ConnectCommCanceled = true;
            if (_socketconnThread != null && _ConnectionStats == false)
            {
                Console.WriteLine("Connection canceled:: enter");
                _socketconnThread.Join();
                _socketconnThread = null;
                this.socketTube.Close();
            }
            if (_ConnectionStats == true && _socketconnThread != null)
            {
                Console.WriteLine("Connection cut down:: enter");
                //说明链接没有中断，需要按照顺序关闭发送和接受任务，再停下连接
                #region 停止连接
                _socketconnThread.Abort();
                _socketconnThread = null;
                this.socketTube.Disconnect(true);
                this.socketTube.Close();
                this.socketTube=null;
                #endregion
                #region 关闭发送和接收线程
                //if (this._hbThread.IsAlive == true) 
                //{
                //    _hbThread.Abort();
                //    _hbThread = null;
                //}
                if (this._SendThread.IsAlive == true)
                {
                    _SendThread.Abort();
                    _SendThread = null;
                }
                if (this._ReceiveThread.IsAlive == true) 
                {
                    _ReceiveThread.Abort();
                    _ReceiveThread = null;
                }
                #endregion
            }
        }
        ~RobotToolManager()
        {

        }

        private ConcurrentQueue<string> _commandsToTool;
        private string _infoFromTool;
    }
}
