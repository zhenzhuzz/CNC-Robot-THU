
namespace ABB_二次开发1230
{
    partial class ForemstartNew
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.label1 = new System.Windows.Forms.Label();
            this.Account_cbo = new System.Windows.Forms.ComboBox();
            this.label2 = new System.Windows.Forms.Label();
            this.Password_txb = new System.Windows.Forms.TextBox();
            this.Register_btn = new System.Windows.Forms.Button();
            this.Exit_btn = new System.Windows.Forms.Button();
            this.Reset_btn = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.label1.Location = new System.Drawing.Point(142, 91);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(57, 19);
            this.label1.TabIndex = 0;
            this.label1.Text = "账户:";
            // 
            // Account_cbo
            // 
            this.Account_cbo.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.Account_cbo.FormattingEnabled = true;
            this.Account_cbo.Location = new System.Drawing.Point(205, 88);
            this.Account_cbo.Name = "Account_cbo";
            this.Account_cbo.Size = new System.Drawing.Size(191, 27);
            this.Account_cbo.TabIndex = 1;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.label2.Location = new System.Drawing.Point(142, 136);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(57, 19);
            this.label2.TabIndex = 2;
            this.label2.Text = "密码:";
            // 
            // Password_txb
            // 
            this.Password_txb.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.Password_txb.Location = new System.Drawing.Point(205, 133);
            this.Password_txb.Multiline = true;
            this.Password_txb.Name = "Password_txb";
            this.Password_txb.PasswordChar = '*';
            this.Password_txb.Size = new System.Drawing.Size(191, 27);
            this.Password_txb.TabIndex = 3;
            this.Password_txb.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.Password_txb_KeyPress);
            // 
            // Register_btn
            // 
            this.Register_btn.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.Register_btn.Location = new System.Drawing.Point(146, 190);
            this.Register_btn.Name = "Register_btn";
            this.Register_btn.Size = new System.Drawing.Size(82, 25);
            this.Register_btn.TabIndex = 4;
            this.Register_btn.Text = "登录";
            this.Register_btn.UseVisualStyleBackColor = true;
            this.Register_btn.Click += new System.EventHandler(this.Register_btn_Click);
            // 
            // Exit_btn
            // 
            this.Exit_btn.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.Exit_btn.Location = new System.Drawing.Point(251, 190);
            this.Exit_btn.Name = "Exit_btn";
            this.Exit_btn.Size = new System.Drawing.Size(82, 25);
            this.Exit_btn.TabIndex = 5;
            this.Exit_btn.Text = "退出";
            this.Exit_btn.UseVisualStyleBackColor = true;
            this.Exit_btn.Click += new System.EventHandler(this.Exit_btn_Click);
            // 
            // Reset_btn
            // 
            this.Reset_btn.Font = new System.Drawing.Font("宋体", 14.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.Reset_btn.Location = new System.Drawing.Point(364, 190);
            this.Reset_btn.Name = "Reset_btn";
            this.Reset_btn.Size = new System.Drawing.Size(82, 25);
            this.Reset_btn.TabIndex = 6;
            this.Reset_btn.Text = "重置";
            this.Reset_btn.UseVisualStyleBackColor = true;
            this.Reset_btn.Click += new System.EventHandler(this.Reset_btn_Click);
            // 
            // ForemstartNew
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(584, 299);
            this.Controls.Add(this.Reset_btn);
            this.Controls.Add(this.Exit_btn);
            this.Controls.Add(this.Register_btn);
            this.Controls.Add(this.Password_txb);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.Account_cbo);
            this.Controls.Add(this.label1);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "ForemstartNew";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "ForemstartNew";
            this.Load += new System.EventHandler(this.ForemstartNew_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox Account_cbo;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.TextBox Password_txb;
        private System.Windows.Forms.Button Register_btn;
        private System.Windows.Forms.Button Exit_btn;
        private System.Windows.Forms.Button Reset_btn;
    }
}