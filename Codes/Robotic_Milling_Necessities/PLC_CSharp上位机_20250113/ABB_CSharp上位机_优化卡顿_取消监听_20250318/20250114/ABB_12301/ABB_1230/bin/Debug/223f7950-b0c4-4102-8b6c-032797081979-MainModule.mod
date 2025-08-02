
MODULE MainModule
    PERS tooldata tEleSpindle40:=[TRUE,[[0.887916,-305.652,178.904],[1,0,0,0]],[40,[0.887916,-30,178.904],[1,0,0,0],0,0,0]];
    CONST robtarget pHome:=[[1743.30,-768.57,833.04],[0.702351,0.0907192,0.698558,0.102417],[-1,-1,0,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pHome_paper:=[[1484.73,-797.50,936.20],[0.498119,0.518083,0.509528,0.473126],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    TASK PERS robtarget pApp:=[[60,137.05,-12.78],[0.70032,0.0977126,0.700324,0.0977237],[-1,-1,0,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    TASK VAR robtarget pStart;

    CONST robtarget pCompact:=[[742.33,562.35,1062.42],[0.343604,0.33787,0.612371,0.626723],[0,0,0,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    TASK PERS wobjdata Paper:=[FALSE,TRUE,"",[[1493.13,-766.694,822.06],[0.999943,-0.000936594,1.88841E-05,0.0106668]],[[0,0,0],[1,0,0,0]]];
    !TASK PERS wobjdata Al300_300:=[FALSE,TRUE,"",[[1193.21,-1088.14,814.065],[0.999962,0.000143729,-0.00103706,0.0086743]],[[127.37,989.04,115.84],[1,0,0,0]]];
    TASK PERS wobjdata Al300_300_1:=[FALSE,TRUE,"",[[1498.31,-628.668,457.345],[0.999957,-0.00222989,-0.00321895,0.00840987]],[[0,0,0],[1,0,0,0]]];
    VAR robtarget Target_tmp:=[[29.69,169.12,122.88],[0.510728,0.504608,0.490076,0.494322],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    CONST num zSafe:=50;
    CONST num xySafe:=25;
    TASK PERS wobjdata wobj1:=[FALSE,TRUE,"",[[1696.55,-811.9,713.727],[0.999958,-0.00278229,-0.0038329,0.00780733]],[[0,0,0],[1,0,0,0]]];
    TASK PERS wobjdata wobj2:=[FALSE,TRUE,"",[[1412.85,-493.35,508.86],[0.999987078762688,0,0,-0.005083532990559]],[[3,3,-50],[1,0,0,0]]];
    CONST robtarget pTemp:=[[25,25,20],[0.510324,0.504295,0.490903,0.494236],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    VAR num Function:=1;
	VAR num direction{6}:=[10,0,0,0,0,0];
	VAR num joint{6}:=[0,0,0,0,0,0];
    VAR robtarget curPos;
    VAR jointtarget curJoint;
    VAR robtarget movePos{3};
    PERS string str{10};
    TASK PERS wobjdata Al300_300:=[FALSE,TRUE,"",[[1696.55,-811.9,713.727],[0.999958,-0.00278229,-0.0038329,0.00780733]],[[0,0,0],[1,0,0,0]]];

    PROC main()
        start:
        TPErase;
        TPReadFK reg1,"Choose behaviour","Slot milling","SpinSpeedSet","Drilling","Warm up",stEmpty;
        TEST reg1
        CASE 1:
            slotMilling;
        CASE 2:
            spindleSpeedSet;
            GOTO start;
        CASE 3:
            drilling;
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
        Set profinet_do1_toolChange;
        WaitTime 3;
        Reset profinet_do1_toolChange;
    ENDPROC

    PROC spindleSpeedSet()
        VAR num spinV;
        VAR num spinV_Hz;
        VAR num spinV_Hz_1000;
        Set profinet_do0;
        TPErase;
        TPWrite "Current spindle speed is:"\Num:=spinV_Hz;
        TPReadNum spinV_Hz,"Spindle speed=? (rpm)";
        !spinV_Hz:=spinV/600;
        !spinV_Hz:=spinV/552.96;
        !spinV_Hz:= Trunc(spinV_Hz\Dec:=3);
        TPWrite "SpinV=:"\Num:=spinV;
        TPWrite "SpinV_Hz=:"\Num:=spinV_Hz;
        spinV_Hz_1000:=spinV_Hz*1000;

        SetGO profinet_go0,spinV_Hz_1000;
        Reset profinet_do0;
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

    FUNC string showCuttingCondition(num ap,num ap2,num feed, num distance,string direction)
        RETURN "ap="+NumToStr(ap,1)+" mm,"+"ap2="+NumToStr(ap2,1)+" mm,"+"f="+NumToStr(feed,1)+" mm/s,"+"d="+NumToStr(distance,1)+" mm,"+direction;
    ENDFUNC

    PROC drilling()
        VAR num ap:=4;
        VAR num ap2:=0;
        VAR num feed:=5;
        VAR num distance:=0;
        VAR string direction:="NaN";
        
        TPErase;
        cutSetting:
        !MoveJ pHome,v100,fine,tEleSpindle40\WObj:=wobj0;
        WHILE TRUE DO
            TPWrite showCuttingCondition(ap,ap2,feed,distance,direction);
            TPReadFK reg3,"Change cutting condition","ap(mm)","f(mm/s)",stEmpty,stEmpty,"Done";
            TEST reg3
            CASE 1:
                TPReadNum ap,"Depth of cut ap=? (mm)";
            CASE 2:
                TPReadNum feed,"Feed velocity f=? (mm/s)";
            CASE 5:
                GOTO action;
            DEFAULT:
                GOTO cutSetting;
            ENDTEST
        ENDWHILE
        
        check:
        TPWrite showCuttingCondition(ap,ap2,feed,distance,direction);
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
        MoveL pApp,v50,fine,tEleSpindle40\WObj:=Al300_300;
        TPReadFK reg6,"Ready?",stEmpty,stEmpty,stEmpty,"YES","Back";
        TEST reg6
        CASE 4:
            drillPath ap,feed,distance,0;
        CASE 5:
            MoveL pApp,v100,fine,tEleSpindle40\WObj:=Al300_300;
            GOTO cutSetting;
        DEFAULT:
            MoveL pApp,v100,fine,tEleSpindle40\WObj:=Al300_300;
            GOTO cutSetting;
        ENDTEST
        MoveL pApp,v100,fine,tEleSpindle40\WObj:=Al300_300;
        MoveL pHome,v100,fine,tEleSpindle40\WObj:=wobj0;
    ENDPROC
    
    PROC drillPath(num ap1,num feed1,num x,num y)
        VAR speeddata feedr:=v5;

        feedr.v_tcp:=feed1;

        pStart:=pApp;
        pStart.trans.z:=pStart.trans.z-zSafe;
        TPWrite "The Start point is:"\Pos:=pStart.trans;
        MoveL Offs(pStart,0,0,-ap1),feedr,fine,tEleSpindle40\WObj:=Al300_300;
        MoveL Offs(pStart,0,0, ap1),v50,fine,tEleSpindle40\WObj:=Al300_300;
    ENDPROC
    
    PROC slotMilling()
        VAR num ap:=0;
        VAR num ap2 :=0;
        VAR num feed:=6;
        VAR num length:=150;
        VAR num distance:=200;
        VAR string direction:="NaN";

        TPErase;
        cutSetting:
        MoveJ pHome,v100,fine,tEleSpindle40\WObj:=wobj0;
        WHILE TRUE DO
            TPWrite showCuttingCondition(ap,ap2,feed,distance,direction);
            TPReadFK reg3,"Change cutting condition","ap(mm)","f(mm/s)","ap2(mm)","direction","Done";
            TEST reg3
            CASE 1:
                TPReadNum ap,"Depth of cut ap=? (mm)";
            CASE 2:
                TPReadNum feed,"Feed velocity f=? (mm/s)";
            CASE 3:
                !TPReadNum length,"Length l=? (mm)";
                !distance:=length+2*xySafe;
                TPReadNum ap2,"Variable depth ap2=? (mm)";
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
        TPWrite showCuttingCondition(ap,ap2,feed,distance,direction);
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
        MoveL pApp,v50,fine,tEleSpindle40\WObj:=Al300_300;
        !MoveL Offs(pApp,0,0,0),v10,fine,tEleSpindle40\WObj:=Al300_300;
        TPReadFK reg6,"Ready?",stEmpty,stEmpty,stEmpty,"YES","Back";
        TEST reg6
        CASE 4:
            TEST reg4
            CASE 1:
                path ap, ap2, feed,distance,0;
            CASE 2:
                path ap,ap2, feed,-distance,0;
            CASE 3:
                path ap,ap2,feed,0,distance;
            CASE 4:
                path ap,ap2,feed,0,-distance;
            ENDTEST
        CASE 5:
            MoveL pApp,v100,fine,tEleSpindle40\WObj:=Al300_300;
            GOTO cutSetting;
        DEFAULT:
            MoveL pApp,v100,fine,tEleSpindle40\WObj:=Al300_300;
            GOTO cutSetting;
        ENDTEST
        !MoveL pApp,v50,fine,tEleSpindle40\WObj:=Al300_300;
        MoveL pHome,v50,fine,tEleSpindle40\WObj:=wobj0;
    ENDPROC

    PROC path(num ap1, num ap2, num feed1,num x,num y)
        VAR speeddata feedr:=v100;
        feedr.v_tcp:=feed1;

        pStart:=pApp;
        !pStart.trans.z:=pStart.trans.z-zSafe;
        TPWrite "The Start point is:"\Pos:=pStart.trans;
        MoveL Offs(pStart,0,0,-ap1),v20,fine,tEleSpindle40\WObj:=Al300_300;
        MoveL Offs(pStart,x,y,-ap1-ap2),feedr,fine,tEleSpindle40\WObj:=Al300_300;
        MoveL Offs(pStart,x,y,zSafe),v50,fine,tEleSpindle40\WObj:=Al300_300;
    ENDPROC
    
    PROC warmUp()
        MoveAbsJ [[0,0,0,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,0,20,-30],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,0,-20,60],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,0,30,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,0,-30,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,50,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1500,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,-50,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1500,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,50,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1500,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,-50,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v1500,fine,tEleSpindle40;
        MoveAbsJ [[0,0,15,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,-40,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,15,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,-40,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,15,-15,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,-45,45,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,15,-15,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,-60,60,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,15,-15,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,-45,45,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,15,-15,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,-60,60,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[35,-30,30,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[-50,-30,30,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[35,-30,30,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[-50,-30,30,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
        MoveAbsJ [[0,0,0,0,0,15],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v2000,fine,tEleSpindle40;
    ENDPROC

    
	PROC newFrame()
		CONST robtarget px1:=[[200.82,-449.75,-415.56],[0.519574,0.504903,0.488149,0.486648],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
		CONST robtarget py1:=[[174.80,-437.74,-415.58],[0.51957,0.504912,0.48815,0.486642],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
		CONST robtarget pz1:=[[1517.76,-444.41,508.86],[0.504116,0.500631,0.499611,0.495606],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
		CONST robtarget pz2:=[[257.47,-368.24,-439.08],[0.501585,0.49809,0.50215,0.49816],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
		CONST robtarget pz{3}:=[[[1506.73,-547.06,474.88],[0.51551,0.50426,0.488232,0.491529],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]],[[1506.74,-623.36,475.49],[0.515512,0.504257,0.488232,0.49153],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]],[[1711.71,-620.57,476.68],[0.51551,0.50426,0.488233,0.491529],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]];
		CONST robtarget px{3}:=[[[1513.23,-638.89,460.59],[0.51555,0.504223,0.488236,0.49152],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]],[[1603.24,-637.45,455.60],[0.515534,0.504215,0.488248,0.491534],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]],[[1702.25,-635.74,455.60],[0.515537,0.50423,0.488239,0.491525],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]];
		CONST robtarget py{3}:=[[[1487.90,-619.34,445.55],[0.51551,0.504259,0.488232,0.49153],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]],[[1487.35,-569.77,403.54],[0.515508,0.504258,0.488235,0.49153],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]],[[1486.74,-547.06,440.46],[0.515513,0.504256,0.488231,0.491531],[-1,-1,1,1],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]];
		<SMT>
	ENDPROC

    PROC WinMove()
        Function:=0;
        WHILE TRUE DO
        WaitUntil Function<>0;
		curPos := CRobT(\Tool:= tEleSpindle40,\WObj:=Al300_300);
        curJoint:=CJointT();
        TEST Function
        CASE 1:
        !MoveL RelTool(curPos,direction{1},direction{2},direction{3}\Rx:=direction{4}\Ry:=direction{5}\Rz:=direction{6}),v500,fine,tEleSpindle40\WObj:=Al300_300; 
        Movel offs(curPos,direction{1},direction{2},direction{3}),v300,fine,tEleSpindle40\wobj:=Al300_300;
        CASE 2:
        curJoint.robax.rax_1:=curJoint.robax.rax_1+joint{1};
        curJoint.robax.rax_2:=curJoint.robax.rax_2+joint{2};
        curJoint.robax.rax_3:=curJoint.robax.rax_3+joint{3};
        curJoint.robax.rax_4:=curJoint.robax.rax_4+joint{4};
        curJoint.robax.rax_5:=curJoint.robax.rax_5+joint{5};
        curJoint.robax.rax_6:=curJoint.robax.rax_6+joint{6};
        MoveAbsJ curJoint\NoEOffs,v500,fine,tEleSpindle40\WObj:=Al300_300;
        ENDTEST
       
        ENDWHILE
	ENDPROC
    
ENDMODULE
