
MODULE MainModule
    TASK PERS tooldata tEleSpindle:=[TRUE,[[320,0,175],[1,0,0,0]],[40,[69.5,-82,175],[1,0,0,0],0,0,0]];
    TASK PERS wobjdata Aluminum6061:=[FALSE,TRUE,"",[[1240.783,-152.976,800],[1,0,0,0]],[[0,0,0],[1,0,0,0]]];

    LOCAL CONST robtarget pHome:=[[1299.64,39.71,1278.98],[0.706876,-0.000200197,0.707338,0.000205699],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
    TASK PERS robtarget pApp:=[[12,58,10],[0.706876,-0.000200197,0.707338,0.000205699],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];

    VAR robtarget pStart;

    VAR robtarget Target_tmp:=[[76.25,84.92,330.38],[0.707107,1.99282E-6,0.707107,1.99064E-6],[-1,-1,0,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];

    CONST num zSafe:=50;
    CONST num xySafe:=90;
    TASK PERS wobjdata wobj1:=[FALSE,TRUE,"",[[1240.78,-152.976,800],[1,0,0,0]],[[0,0,0],[0.96363,0,0,-0.26724]]];
    VAR num mytest:=0;

    VAR num Function:=1;
	VAR num direction{6}:=[10,0,0,0,0,0];
	VAR num joint{6}:=[0,0,0,0,0,0];
    VAR robtarget curPos;
    VAR jointtarget curJoint;
    VAR robtarget movePos{3};
    PERS string str{10};

    PROC main()
        start:
        TPErase;
          TPErase;
        TPReadFK reg1,"Choose behaviour","Slot milling","SpinSpeedSet","pAppXYZ","Warm up",stEmpty;
        TEST reg1
        CASE 1:
            slotMilling;
        CASE 2:
            spindleSpeedSet;
            GOTO start;
        CASE 3:
            pAppXYZ;
            GOTO start;
        CASE 4:
            warmUp;
            GOTO start;
        ENDTEST

    ENDPROC

    PROC spindleOn()
        Set profinet_do0;
    ENDPROC

    PROC airOn()
        Set profinet_do1;
    ENDPROC

    PROC spindleSpeedSet()

        VAR rawbytes raw_DA;
        VAR num spinV:=500;
        VAR num spinV_Hz:=0.88;

        VAR byte byte_1:=0;
        VAR byte byte_2:=0;
        VAR byte byte_3:=0;
        VAR byte byte_4:=0;
        TPErase;
        TPWrite "Current spindle speed is:"\Num:=spinV;
        TPReadNum spinV,"Spindle speed=? (rpm)";
        spinV_Hz:=spinV/563.5;

        ClearRawBytes raw_DA;
        PackRawBytes spinV_Hz,raw_DA,1\Float4;
        UnpackRawBytes raw_DA,1,byte_4\Hex1;
        UnpackRawBytes raw_DA,2,byte_3\Hex1;
        UnpackRawBytes raw_DA,3,byte_2\Hex1;
        UnpackRawBytes raw_DA,4,byte_1\Hex1;
        SetGO profinet_go0,byte_1;
        SetGO profinet_go1,byte_2;
        SetGO profinet_go2,byte_3;
        SetGO profinet_go3,byte_4;

        TPWrite "Current spindle speed is:"\Num:=spinV;

    ENDPROC

    PROC pAppXYZ()
        VAR num X;
        VAR num Y;
        VAR num Z;
        XYZ:
        WHILE TRUE DO
            TPReadFK reg2,"Change approaching point's XYZ","X","Y","Z","Done",stEmpty;
            TEST reg2
            CASE 1:
                TPReadNum X,"X=? (mm)";
                pApp.trans.x:=X;
                TPWrite "pApp postion:"\Pos:=pApp.trans;
            CASE 2:
                TPReadNum Y,"Y=? (mm)";
                pApp.trans.y:=Y;
                TPWrite "pApp postion:"\Pos:=pApp.trans;
            CASE 3:
                TPReadNum Z,"Z=? (mm)";
                pApp.trans.z:=Z;
                TPWrite "pApp postion:"\Pos:=pApp.trans;
            CASE 4:
                RETURN ;
            DEFAULT:
                GOTO XYZ;
            ENDTEST
        ENDWHILE


    ENDPROC

    FUNC string showCuttingCondition(num ap,num feed,num distance,string direction)
        RETURN "ap="+NumToStr(ap,1)+" mm,"+"f="+NumToStr(feed,1)+" mm/s,"+"d="+NumToStr(distance,1)+" mm,"+direction;
    ENDFUNC


    PROC slotMilling()
        VAR num ap:=0;
        VAR num feed:=100;
        VAR num length:=300;
        VAR num distance:=400;

        VAR string direction:="NaN";

        TPErase;
        cutSetting:
        MoveJ pHome,v500,fine,tEleSpindle\WObj:=wobj0;
        WHILE TRUE DO
            TPWrite showCuttingCondition(ap,feed,distance,direction);
            TPReadFK reg3,"Change cutting condition","ap(mm)","f(mm/s)","l(mm)","direction","Done";
            TEST reg3
            CASE 1:
                TPReadNum ap,"Depth of cut ap=? (mm)";
            CASE 2:
                TPReadNum feed,"Feed velocity f=? (mm/s)";
            CASE 3:
                TPReadNum length,"Length l=? (mm)";
                distance:=length+2*xySafe;
            CASE 4:
                TPReadFK reg4,"Select direction","X+","X-","Y+","Y-",stEmpty;
                TEST reg4
                CASE 1:
                    direction:="X+";
                CASE 2:
                    direction:="X-";
                CASE 3:
                    direction:="Y+";
                CASE 4:
                    direction:="Y-";
                ENDTEST
            CASE 5:
                GOTO action;
            DEFAULT:
                GOTO cutSetting;
            ENDTEST
        ENDWHILE

        check:
        TPWrite showCuttingCondition(ap,feed,distance,direction);
        TPReadFK reg5,"Continue?",stEmpty,stEmpty,stEmpty,"cutSetting","OK";
        TEST reg5
        CASE 4:
            GOTO cutSetting;
        CASE 5:
            GOTO action;
        DEFAULT:
            GOTO cutSetting;
        ENDTEST

        action:
        MoveL pApp,v500,fine,tEleSpindle\WObj:=Aluminum6061;
        MoveL Offs(pApp,0,0,-zSafe),v500,fine,tEleSpindle\WObj:=Aluminum6061;
        TPReadFK reg6,"Ready?",stEmpty,stEmpty,stEmpty,"YES","Back";
        TEST reg6
        CASE 4:
            TEST reg4
            CASE 1:
                path ap,feed,distance,0;
            CASE 2:
                path ap,feed,-distance,0;
            CASE 3:
                path ap,feed,0,distance;
            CASE 4:
                path ap,feed,0,-distance;
            ENDTEST
        CASE 5:
            MoveL pApp,v500,fine,tEleSpindle\WObj:=Aluminum6061;
            GOTO cutSetting;
        DEFAULT:
            MoveL pApp,v500,fine,tEleSpindle\WObj:=Aluminum6061;
            GOTO cutSetting;
        ENDTEST
        MoveL pApp,v500,fine,tEleSpindle\WObj:=Aluminum6061;
        MoveL pHome,v500,fine,tEleSpindle\WObj:=wobj0;
    ENDPROC

    PROC path(num ap1,num feed1,num x,num y)
        VAR speeddata feedr:=v200;

        feedr.v_tcp:=feed1;

        pStart:=pApp;
        pStart.trans.z:=pStart.trans.z-zSafe;
        TPWrite "The Start point is:"\Pos:=pStart.trans;
        MoveL Offs(pStart,0,0,-ap1),v500,fine,tEleSpindle\WObj:=Aluminum6061;
        MoveL Offs(pStart,x,y,-ap1),feedr,fine,tEleSpindle\WObj:=Aluminum6061;
        MoveL Offs(pStart,x,y,zSafe),v500,fine,tEleSpindle\WObj:=Aluminum6061;
    ENDPROC


    PROC warmUp()
        MoveAbsJ [[0,0,0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,0,20,90],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,0,-20,-90],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,0,30,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,0,-30,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,50,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,-50,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,15,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,-40,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,15,-15,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,-45,45,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,15,-15,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,-60,60,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[35,-30,30,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[-50,-30,30,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
        MoveAbsJ [[0,0,0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v3000,fine,tEleSpindle;
    ENDPROC


    PROC communication()
        VAR socketdev server;
        VAR socketdev client;
        VAR bool serverActive:=TRUE;
        VAR string received_string;

        SocketClose server;
        SocketClose client;
        WaitTime 0.2;
        SocketCreate server;
        ! '192.168.125.1' for actual robot's IP
        SocketBind server,"127.0.0.1",55000;

        SocketListen server;
        serverActive:=TRUE;

        MoveJ pHome,v500,fine,tEleSpindle\WObj:=wobj0;

        SocketAccept server,client;

        WHILE serverActive DO
            SocketReceive client\Str:=received_string;
            data_decode(received_string);
            MoveL Target_tmp,v200,fine,tEleSpindle\WObj:=Aluminum6061;
            SocketSend client,\Str:="Done";
        ENDWHILE

        SocketClose client;
        SocketClose server;
    ENDPROC


    PROC data_decode(string str_rcv)
        VAR num StartBit1;
        VAR num StartBit2;
        VAR num StartBit3;
        VAR num EndBit1;
        VAR num EndBit2;
        VAR num EndBit3;
        VAR num LenBit1;
        VAR num LenBit2;
        VAR num LenBit3;

        VAR string s1;
        VAR string s2;
        VAR string s3;
        VAR string s4;
        VAR bool flag1;

        VAR num X;
        VAR num Y;
        VAR num Z;
        TPErase;
        StartBit1:=1;
        EndBit1:=StrFind(str_rcv,StartBit1,",");
        LenBit1:=EndBit1-StartBit1;

        StartBit2:=EndBit1+1;
        EndBit2:=StrFind(str_rcv,StartBit2,",");
        LenBit2:=EndBit2-StartBit2;

        StartBit3:=EndBit2+1;
        EndBit3:=StrFind(str_rcv,StartBit3,",");
        LenBit3:=EndBit3-StartBit3;

        s1:=StrPart(str_rcv,StartBit1,LenBit1);
        s2:=StrPart(str_rcv,StartBit2,LenBit2);
        s3:=StrPart(str_rcv,StartBit3,LenBit3);

        flag1:=StrToVal(s1,X);
        flag1:=StrToVal(s2,Y);
        flag1:=StrToVal(s3,Z);

        Target_tmp.trans.x:=X;
        Target_tmp.trans.y:=Y;
        Target_tmp.trans.z:=Z;

        IF flag1=FALSE THEN
            Stop;
        ENDIF
    ENDPROC

    PROC newFrame()
        CONST robtarget px{5}:=[[[29.68,-17.83,-0.00],[0.705771,0.120146,0.688029,-0.118609],[-1,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[68.39,-41.10,-0.00],[0.70577,0.120146,0.68803,-0.11861],[-1,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[140.98,-84.72,-0.01],[0.705769,0.120147,0.68803,-0.118611],[-1,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[177.07,-106.41,-0.01],[0.705769,0.120148,0.68803,-0.118612],[-1,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[216.42,-130.06,-0.01],[0.705769,0.120148,0.688031,-0.118612],[-1,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]]];
        CONST robtarget py{5}:=[[[16.84,28.02,-0.00],[0.705772,0.120144,0.688029,-0.118608],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[31.88,53.06,-0.00],[0.705772,0.120143,0.688029,-0.118607],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[71.43,118.89,-0.00],[0.705772,0.12014,0.68803,-0.118605],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[109.27,181.87,-0.01],[0.705771,0.120138,0.688031,-0.118604],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]],[[161.56,268.92,-0.01],[0.705771,0.120135,0.688033,-0.118602],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]]];
        VAR num X{5};
        VAR num Y{5};
        CONST robtarget pz1:=[[161.56,268.92,-0.01],[0.705771,0.120135,0.688033,-0.118602],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
        CONST robtarget px1:=[[161.56,268.92,-0.01],[0.705771,0.120135,0.688033,-0.118602],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
        CONST robtarget py1:=[[161.56,268.92,-0.01],[0.705771,0.120135,0.688033,-0.118602],[0,0,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
        
        FOR i FROM 1 TO 5 DO
            X{i} := px{i}.trans.x;
            Y{i} := py{i}.trans.y;
        ENDFOR
    ENDPROC
PROC WinMove()
        Function:=0;
        WHILE TRUE DO
        WaitUntil Function<>0;
		curPos := CRobT(\Tool:= tEleSpindle,\WObj:=wobj0);
        curJoint:=CJointT();
        TEST Function
        CASE 1:
        MoveL RelTool(curPos,direction{1},direction{2},direction{3}\Rx:=direction{4}\Ry:=direction{5}\Rz:=direction{6}),v1000,fine,tEleSpindle\WObj:=wobj0; 
        CASE 2:
        curJoint.robax.rax_1:=curJoint.robax.rax_1+joint{1};
        curJoint.robax.rax_2:=curJoint.robax.rax_2+joint{2};
        curJoint.robax.rax_3:=curJoint.robax.rax_3+joint{3};
        curJoint.robax.rax_4:=curJoint.robax.rax_4+joint{4};
        curJoint.robax.rax_5:=curJoint.robax.rax_5+joint{5};
        curJoint.robax.rax_6:=curJoint.robax.rax_6+joint{6};
        MoveAbsJ curJoint\NoEOffs,v1000,fine,tool0\WObj:=wobj0;
        ENDTEST
       
        ENDWHILE
	ENDPROC
ENDMODULE
