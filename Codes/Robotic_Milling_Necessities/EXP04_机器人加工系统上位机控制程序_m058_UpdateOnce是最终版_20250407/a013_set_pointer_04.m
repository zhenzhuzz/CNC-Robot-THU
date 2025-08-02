function a013_set_pointer_04
    %% 1. 加载 ABB PC SDK .NET 程序集
    NET.addAssembly('C:\Program Files (x86)\ABB\SDK\PCSDK 2025\ABB.Robotics.Controllers.PC.dll');
    % 如果需要其它DLL，可类似调用
    % NET.addAssembly('C:\Program Files (x86)\ABB\SDK\PCSDK 2025\ABB.Robotics.Controllers.RapidDomain.dll');
    % 导入命名空间（请根据实际DLL的命名空间调整）
    import ABB.Robotics.Controllers.*;
    import ABB.Robotics.Controllers.Discovery.*;
    import ABB.Robotics.Controllers.RapidDomain.*;
    
    %% 2. 创建控制器扫描/连接界面
    figScanner = uifigure('Name','ABB Controller Scanner',...
                   'Position',[500 300 600 300]);
               
    % “刷新”按钮：扫描并更新控制器列表
    btnRefresh = uibutton(figScanner, 'Text','Refresh',...
                          'Position',[20 250 80 30],...
                          'ButtonPushedFcn',@(src,evt)refreshScan());
                      
    % “连接”按钮：根据选中行连接控制器
    btnConnect = uibutton(figScanner, 'Text','Connect',...
                          'Position',[120 250 80 30],...
                          'ButtonPushedFcn',@(src,evt)connectController());
                      
    % 用于显示扫描结果的表格
    tbl = uitable(figScanner, ...
                  'Position',[20 50 560 180], ...
                  'ColumnName',{'IP Address','System Name','Availability'}, ...
                  'ColumnEditable',[false false false]);
              
    % 用于存储扫描结果和已连接的控制器对象
    controllers = [];
    controller = [];
    
    % 刷新扫描函数：扫描网络上的 ABB 控制器
    function refreshScan()
        try            
            % 创建网络扫描器对象并执行扫描
            scanner = Discovery.NetworkScanner();
            scanner.Scan();
            controllers = scanner.Controllers;
            
            % 更新表格数据
            n = controllers.Count;
            if n == 0
                tbl.Data = {};
                uialert(figScanner, 'No ABB controllers found!', 'Alert');
            else
                dataCell = cell(n,3);
                for i = 1:n
                    info = controllers.Item(i-1); % .NET集合索引从0开始
                    dataCell{i,1} = char(info.IPAddress.ToString());
                    dataCell{i,2} = char(info.SystemName);
                    dataCell{i,3} = char(info.Availability.ToString());
                end
                tbl.Data = dataCell;
            end
        catch ME
            uialert(figScanner, sprintf('Scan error:\n%s', ME.message), 'Error');
        end
    end

    % 连接控制器函数
    function connectController()
        try
            if isempty(tbl.Data)
                uialert(figScanner, 'The list is empty, please refresh the scan first!', 'Alert');
                return;
            end
            
            % 获取用户选中的单元格，Selection返回一个数组（第一项为行索引）
            sel = tbl.Selection;
            if isempty(sel)
                uialert(figScanner, 'Please select a row first!', 'Alert');
                return;
            end
            rowIdx = sel(1); % 选中的行号（从1开始）
            
            % 获取对应的 ControllerInfo 对象
            info = controllers.Item(rowIdx-1);
            
            % 判断 Availability 枚举值（使用全限定名称）
            if info.Availability == ABB.Robotics.Controllers.Availability.Available
                % 若已有连接的控制器，则先断开
                if ~isempty(controller)
                    controller.Logoff();
                    controller.Dispose();
                    controller = [];
                end
                
                % 创建控制器对象并使用默认用户登录
                controller = ABB.Robotics.Controllers.ControllerFactory.CreateFrom(info);
                controller.Logon(ABB.Robotics.Controllers.UserInfo.DefaultUser);
                uialert(figScanner, ['Logged into controller: ' char(info.SystemName)], 'Success');
                
                % 连接成功后关闭扫描界面，启动操作界面
                close(figScanner);
                createControlPanel();
            else
                uialert(figScanner, 'The selected controller is not available or already in use!', 'Alert');
            end
        catch ME
            uialert(figScanner, sprintf('Connection error:\n%s', ME.message), 'Error');
        end
    end

    %% 3. 机器人控制操作界面
    function createControlPanel()
        % 创建操作界面窗口（采用传统 figure 窗口）
        hFig = figure('Name','ABB 机器人控制','NumberTitle','off','Position',[100,100,600,400]);
        
        % 上电和下电按钮
        hPowerOn = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','上电',...
            'Position',[50,300,100,40],...
            'FontSize',12,...
            'Callback',@powerOnCallback);
        hPowerOff = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','下电',...
            'Position',[170,300,100,40],...
            'FontSize',12,...
            'Callback',@powerOffCallback);
        
        % PPtoMain 与 设置指针按钮
        hPPtoMain = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','PPtoMain',...
            'Position',[50,240,100,40],...
            'FontSize',12,...
            'Callback',@PPtoMainCallback);
        hSetPointer = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','设置指针',...
            'Position',[170,240,100,40],...
            'FontSize',12,...
            'Callback',@setPointerCallback);
        
        % 启动（▶︎️）和停止（■）按钮
        hStart = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','▶',...
            'Position',[50,180,100,40],...
            'FontSize',12,...
            'Callback',@startCallback);
        hStop = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','■',...
            'Position',[170,180,100,40],...
            'FontSize',12,...
            'Callback',@stopCallback);
        
        % 消息显示框（使用 listbox 显示历史消息）
        hMsgBox = uicontrol('Parent', hFig, 'Style','listbox',...
            'Position',[50,20,500,140],...
            'FontSize',10);
        
        % 速度输入框 (Edit)
        hSpeedInput = uicontrol('Parent', hFig, 'Style','edit',...
            'String','请输入速度(0~100)',...
            'Position',[300,300,200,40],...
            'FontSize',12,...
            'Callback',@speedEditCallback);

        % 速度显示标签
        hSpeedLabel = uicontrol('Parent', hFig, 'Style','text',...
            'String','当前速度：--%',...
            'Position',[300,260,200,30],...
            'FontSize',12);

        % “获取Routine”按钮
        hLoadRoutines = uicontrol('Parent', hFig, 'Style','pushbutton',...
            'String','获取Routine',...
            'Position',[300,220,100,30],...
            'FontSize',10,...
            'Callback',@loadRoutinesCallback);
        
        % 用于显示 Routine 列表的下拉菜单
        hRoutinePopup = uicontrol('Parent', hFig, 'Style','popupmenu',...
            'Position',[420,220,150,30],...
            'FontSize',10,...
            'String',{'-- 无 --'});  % 初始状态
        
        % 运行模式默认设置为“单周模式”
        runMode = '单周模式';
        addMsg(['运行模式：', runMode]);
        
        %% 控制面板回调函数
        
        function powerOnCallback(~,~)
            try
                % 判断机器人当前操作模式是否为自动
                if controller.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                    % 上电
                    controller.State = ABB.Robotics.Controllers.ControllerState.MotorsOn;
                    addMsg('成功上电');
                else
                    addMsg('请切换到自动模式');
                end
            catch ME
                addMsg(['Unexpected error occurred: ' ME.message]);
            end
        end

        function powerOffCallback(~,~)
            try
                % 判断机器人当前操作模式是否为自动
                if controller.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                    % 下电
                    controller.State = ABB.Robotics.Controllers.ControllerState.MotorsOff;
                    addMsg('成功下电');
                else
                    addMsg('请切换到自动模式');
                end
            catch ME
                addMsg(['Unexpected error occurred: ' ME.message]);
            end
        end

        function PPtoMainCallback(~,~)
            try
                % 首先检查是否在自动模式
                if controller.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                    
                    % 获取所有 RAPID 任务
                    tasks = controller.Rapid.GetTasks();  
                    
                    % 申请主控 (Mastership)，在 C# 中使用 using(...) { ... }，MATLAB 里需手动 Dispose
                    master = Mastership.Request(controller.Rapid);
                    try
                        % 假设我们只需要对第一个任务（通常是 "T_ROB1"）进行指针复位
                        tasks(1).ResetProgramPointer();
                        addMsg('程序指针已复位');
                    catch ME
                        % 如果指针复位中发生任何异常，在此处捕获并继续往外抛
                        master.Dispose();  % 确保在异常时也释放主控
                        rethrow(ME);
                    end
                    
                    % 正常结束后释放主控
                    master.Dispose();
                    
                else
                    addMsg('请切换到自动模式');
                end
                
            catch ME
                % 区分一下权限/占用异常还是通用异常
                if isa(ME, 'System.InvalidOperationException')
                    addMsg(['权限获取失败或客户端占有：' ME.message]);
                else
                    addMsg(['Unexpected error occurred: ' ME.message]);
                end
            end
        end

        function setPointerCallback(~,~)
            try
                % 1) 首先检查机器人是否处于自动模式
                if controller.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                    % 2) 从下拉菜单获取当前选中的 "moduleName/routineName" 字符串
                    routineStrs = get(hRoutinePopup, 'String');  % 下拉菜单选项
                    selIdx = get(hRoutinePopup, 'Value');        % 当前选中项的索引
        
                    % 3) 判断是否选择了有效的 Routine
                    if isempty(routineStrs) || selIdx < 1 ...
                       || strcmp(routineStrs{selIdx},'-- 无 --') ...
                       || strcmp(routineStrs{selIdx},'(无可用Routine)')
                        addMsg('请先获取Routine并进行选择');
                        return;
                    end
        
                    % 4) 解析出模块名与例程名
                    selectedRoutine = routineStrs{selIdx};  % 例如 "module1/myRoutine"
                    parts = strsplit(selectedRoutine, '/');
                    if numel(parts) ~= 2
                        addMsg('Routine选择格式不正确，无法解析出module/routine');
                        return;
                    end
                    moduleName = parts{1};
                    routineName = parts{2};
        
                    % 5) 申请 Mastership（主控），设置程序指针
                    master = Mastership.Request(controller.Rapid);
                    try
                        tasks = controller.Rapid.GetTasks();
                        % 假设只操作第一个任务(如 T_ROB1)
                        tasks(1).SetProgramPointer(moduleName, routineName);
                        addMsg(['程序指针已设置到: ' selectedRoutine]);
                    catch ME
                        master.Dispose();
                        rethrow(ME);
                    end
                    master.Dispose();
        
                else
                    addMsg('请切换到自动模式');
                end
            catch ME
                addMsg(['Unexpected error occurred: ' ME.message]);
            end
        end

        function startCallback(~,~)
            try
                % 先判断机器人是否处于自动模式
                if controller.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                    
                    % 申请主控 (Mastership)
                    master = Mastership.Request(controller.Rapid);
                    try
                        % 调用 Start() 方法启动 RAPID 程序
                        result = controller.Rapid.Start();
                        addMsg(['程序启动 (状态: ' char(result.ToString()) ')']);
                    catch ME
                        % 若出错，需要先释放主控
                        master.Dispose();
                        rethrow(ME);
                    end
                    
                    % 正常执行完后释放主控
                    master.Dispose();
                    
                else
                    addMsg('请切换到自动模式');
                end
                
            catch ME
                addMsg(['Unexpected error occurred: ' ME.message]);
            end
        end
        
        function stopCallback(~,~)
            try
                % 同样先判断自动模式
                if controller.OperatingMode == ABB.Robotics.Controllers.ControllerOperatingMode.Auto
                    
                    % 申请主控
                    master = Mastership.Request(controller.Rapid);
                    try
                        % 调用 Stop(...) 方法停止 RAPID 程序
                        controller.Rapid.Stop(StopMode.Immediate);
                        addMsg('程序停止');
                    catch ME
                        master.Dispose();
                        rethrow(ME);
                    end
                    
                    master.Dispose();
                    
                else
                    addMsg('请切换到自动模式');
                end
                
            catch ME
                addMsg(['Unexpected error occurred: ' ME.message]);
            end
        end

        function speedEditCallback(src, ~)
            % 从输入框中获取文本
            speedStr = get(src, 'String');  % 例如用户输入 "60" 或 "60%"
            % 尝试提取数值（可以用正则去掉非数字字符）
            speedVal = str2double(regexprep(speedStr, '[^\d.]+', ''));
            if isnan(speedVal)
                addMsg('请输入有效的数值(0~100)');
                return;
            end
            % 限制范围
            if speedVal < 0 || speedVal > 100
                addMsg('速度范围应在0~100之间');
                return;
            end
            try
                % 设置机器人速度
                controller.MotionSystem.SpeedRatio = int32(speedVal);
                % 更新标签
                set(hSpeedLabel, 'String', ['当前速度：' num2str(speedVal) '%']);
                addMsg(['速度已设置为 ' num2str(speedVal) '%']);
            catch ME
                addMsg(['设置速度时出错: ' ME.message]);
            end
        end

        function loadRoutinesCallback(~,~)
            try
                tasks = controller.Rapid.GetTasks();
                if isempty(tasks) || tasks.Length < 1
                    addMsg('未找到任何RAPID任务');
                    return;
                end
                theTask = tasks(1);  % 假设只操作第一个任务
        
                % 申请 Mastership
                master = Mastership.Request(controller.Rapid);
                try
                    % 直接获取 module1
                    modObj = theTask.GetModule('Module1');
                    if isempty(modObj)
                        addMsg('未找到 module1 模块');
                        master.Dispose();
                        return;
                    end
        
                    % 获取 module1 中的所有例程
                    routines = modObj.GetRoutines();
                    if isempty(routines) || routines.Length == 0
                        addMsg('module1 中没有例程');
                        master.Dispose();
                        return;
                    end
        
                    routineList = {};
                    for j = 1:routines.Length
                        routineObj = routines(j);
                        routineList{end+1} = ['module1/', char(routineObj.Name)];
                    end
                catch ME
                    master.Dispose();
                    rethrow(ME);
                end
                master.Dispose();
        
                % 将 routineList 赋值给下拉菜单
                set(hRoutinePopup, 'String', routineList);
                addMsg('成功获取 module1 中的所有 Routine');
            catch ME
                addMsg(['获取Routine时出错: ' ME.message]);
            end
        end

        function addMsg(msg)
            % 获取当前消息列表
            currentStr = get(hMsgBox, 'String');
            if isempty(currentStr)
                currentStr = {};
            end
            % 添加新消息，并附上当前时间
            currentStr{end+1} = [datestr(now, 'HH:MM:SS'), ' - ', msg];
            set(hMsgBox, 'String', currentStr);
            % 同时输出到命令行
            disp(msg);
        end
    end

end
