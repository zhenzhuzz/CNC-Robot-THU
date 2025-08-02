using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ABB_二次开发1230
{
    public partial class ForemstartNew : Form
    {
        public ForemstartNew()
        {
            InitializeComponent();
            CheckForIllegalCrossThreadCalls = false;
        }

        private void ForemstartNew_Load(object sender, EventArgs e)
        {
            string path = Application.StartupPath;
            string patha = System.Environment.CurrentDirectory + "\\" + "ABB二次开发启动界面.gif";
            Label label_start = new Label();        
            label_start.Name = "label_start";
            label_start.Location = new Point(0, 0);
            label_start.Size = this.Size;
            label_start.Click += laber_click;
            label_start.Image = Image.FromFile(patha);
            this.Controls.Add(label_start);
            new Thread(Init).Start();
            //Account_cbo.Items.AddRange(new string[] { "管理员", "操作员" });
            //this.BackgroundImage = Image.FromFile(@"C:\Users\Administrator\Pictures\gif图片\ABB背景图.jpg");
            //Password_txb.Focus();
            //Account_cbo.SelectedIndex = 0;
        }

        private void laber_click(object sender, EventArgs e)
        {
            this.Close();
            visible(true);
            
        }

        void visible(bool isvisibel)
        {
            foreach (Control con in this.Controls)
            {
                if (con.Name == "label_start")
                {
                    con.Visible = !isvisibel;
                }
                else
                {
                    con.Visible = isvisibel;
                }
            }
        }
        void Init()
        {
            visible(false);
            Thread.Sleep(4000);
            visible(true);
            this.Close();
        }
        string password = "123456";
        private void Register_btn_Click(object sender, EventArgs e)
        {
            string tempStr = Password_txb.Text.Replace("\n", "");
            tempStr = tempStr.Replace("\r", "");
            if (Account_cbo.SelectedItem.ToString() == "管理员" && Password_txb.Text == password)
            {
                this.Close();
            }
            else
            {
                Password_txb.Clear();
                MessageBox.Show("密码错误");
            }
        }

        private void Exit_btn_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void Reset_btn_Click(object sender, EventArgs e)
        {
            Password_txb.Clear();
        }

        private void Password_txb_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                char KeyChar = e.KeyChar;
                if (KeyChar == (char)Keys.Enter)
                {
                   string  text = Password_txb.Text.Replace(System.Environment.NewLine, string.Empty);  //去除空格
                    if (Account_cbo.SelectedItem.ToString() == "管理员" && text == password)
                    {
                        this.Close();
                    }
                    else
                    {
                        Password_txb.Clear();
                        MessageBox.Show("密码错误");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
    }
}
