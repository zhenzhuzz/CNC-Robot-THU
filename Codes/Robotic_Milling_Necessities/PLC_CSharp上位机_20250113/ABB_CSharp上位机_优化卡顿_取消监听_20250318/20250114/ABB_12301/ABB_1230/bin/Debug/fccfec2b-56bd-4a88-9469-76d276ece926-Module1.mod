MODULE Module1
    PERS robtarget p_low_pick:=[[4673.41,629.45,304.09],[1.5875E-07,-0.707107,0.707107,1.19969E-07],[-1,1,-2,0],[4000,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget p_up_pick:=[[4673.41,617.54,499.45],[2.95794E-07,-0.707107,0.707107,1.68132E-07],[-1,1,-2,0],[4000,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget p_take_cnc1:=[[2720.21,1383.81,715.00],[0.00149343,-0.707039,-0.707172,-0.00112123],[0,0,1,1],[2750,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget p_put_cnc1:=[[2720.21,1383.81,715.00],[5.03847E-08,-0.707107,0.707107,-1.56874E-07],[0,-2,1,0],[2750,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget p_take_cnc2:=[[19.41,1383.81,715],[0.0014937,-0.707039,-0.707172,-0.00112107],[0,0,1,1],[200,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget p_put_cnc2:=[[19.41,1383.81,715],[1.04742E-07,0.707107,-0.707107,-1.92139E-07],[0,-2,1,0],[200,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget p_belt_put:=[[-1876.10,274.08,263.37],[0.00149385,-0.70704,-0.707171,-0.00112079],[0,1,1,1],[-490,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS jointtarget Jhome:=[[1.60083,-61.2926,58.015,-2.52478,33.3128,2.91089],[4000,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS jointtarget J_cnc1:=[[1.60083,-61.2926,58.015,-2.52478,33.3128,2.91089],[2750,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS jointtarget J_cnc2:=[[1.60083,-61.2926,58.015,-2.52478,33.3128,2.91089],[75.1166,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS jointtarget J_cnc2_take:=[[1.60083,-61.2926,58.015,177.5,-33.1,2.91089],[0,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS num nLine:=3;
    PERS num nRow:=0;
    PERS bool empty_flag:=FALSE;
    VAR wzstationary CNC1_wzstat1:=[0];
    VAR wzstationary CNC2_wzstat2:=[0];
    VAR shapedata CNC1_shape1;
    VAR shapedata CNC2_shape2;
    PERS pos CNC2_pos1:=[-317.409,782.191,430.333];
    PERS pos CNC1_pos2:=[3523,1880,1630];
    PERS pos CNC1_pos1:=[2318.73,783.524,425.693];
    PERS pos CNC2_pos2:=[888,1879,1674];
    PERS pos p10:=[0,0,0];
    VAR intnum intno_speed;
    VAR intnum intno_getData;
    VAR intnum intnp_Gettool;
    PERS num no_speed:=10000;
    PERS num C_Count;
    PERS robtarget C_Move:=[[4035.58,218.467,995.074],[0.389435,-0.566368,0.655153,0.313594],[-1,-1,0,0],[4000.01,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS num  C_coordinate;
    PERS num C_rotate;
    PERS robtarget ptep;
    PERS jointtarget C_join:=[[-10.7156,-61.2924,58.0146,-2.52134,33.3127,0.906989],[4000.01,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS num C_joinMove:=1;
    PERS num arraydata1{2}:=[20,30];
    PERS num arraydata2{2,2}:=[[1,1],[1,1]];
    PERS num arraydata3{2,1,2}:=[[[0,0]],[[0,0]]];
    PERS string Ipadress:="sadasd";
    PERS string stringRecive{5}:=["asd","s","578","64","50"];
    PERS num numRecive{5}:=[2,2,2,2,2];
    PERS bool boolRecive{5}:=[TRUE,TRUE,TRUE,TRUE,TRUE];
    TASK PERS loaddata load1:=[0,[0,0,0],[1,0,0,0],0,0,0]; 
    PERS string GetTool :="Tool_Green";
    PERS wobjdata Workobject_1:=[FALSE,TRUE,"",[[2880.206,1263.81,694.999],[0.707106781,0,0,0.707106781]],[[0,0,0],[1,0,0,0]]];
	PERS wobjdata Workobject_2:=[FALSE,TRUE,"",[[179.413,1263.81,694.999],[0.707106781,0,0,0.707106781]],[[0,0,0],[1,0,0,0]]];
    PERS tooldata Tool_Green:=[TRUE,[[-129.904,0,134.999],[0.866025,0,-0.5,0]],[2,[0,0,100],[1,0,0,0],0,0,0]];
    PERS tooldata Tool_Yellow:=[TRUE,[[129.904,0,134.999],[0.866025,0,0.5,0]],[2,[0,0,100],[1,0,0,0],0,0,0]];
    
    
    PROC main() 
        recover;
        TPWrite"hello word";
        WHILE TRUE DO
            IF di0_up_ok=1 AND di1_low_ok=0 THEN
                pick_UP;
            ELSEIF di0_up_ok=0 AND di1_low_ok=1 THEN
                pick_low;
            else
                TPWrite "Feeder Erroer,pleace cheack it!";
                Stop;
            ENDIF
            again:
            IF sdi1_CNC1_Busy=0 THEN
                IF di8_CNC1Have=1 THEN
                    take_cnc1;
                    PUT_CNC1;
                ELSE
                    PUT_CNC1;
                ENDIF
            ELSEIF sdi2_CNC2_Busy=0 THEN
                IF di15_CNC2Have=1 THEN
                    take_cnc2;
                    PUT_CNC2;
                ELSE
                    PUT_CNC2;
                ENDIF
            ELSE
                GOTO again;
            ENDIF
            PUT_BELT;
        ENDWHILE
    ENDPROC

    PROC recover()
        Reset do4_Y_Gripper;
        Reset do5_G_Gripper;
        Reset do2_clamp;
        Reset do3_door;
        Reset do06_clam2;
        Reset do07_door2;
        reset do0_up;
        WaitTime 0.2;
        Set do0_up;
        Reset do1_low;
        waitdi di0_up_ok,1;
        nLine:=0;
        nRow:=0;
        MoveAbsJ Jhome\NoEOffs,v5000,fine,tool0;
        
        IDelete intno_speed;
        CONNECT intno_speed WITH tr_speed;
        IPers no_speed, intno_speed;
      
    ENDPROC

    PROC pick_UP()
        again:
        IF nRow<=2 THEN
            IF nLine<=3 THEN
                MoveAbsJ Jhome\NoEOffs,v5000,fine,tool0;
                MoveJ Offs(p_up_pick,nLine*180,nRow*150,100),v2000,fine,Tool_Yellow;
                MoveL Offs(p_up_pick,nLine*180,nRow*150,0),v1000,fine,Tool_Yellow;
                Set do4_Y_Gripper;
                WaitTime 0.5;
                MoveL Offs(p_up_pick,nLine*180,nRow*150,100),v2000,fine,Tool_Yellow;
                MoveAbsJ Jhome\NoEOffs,v5000,fine,tool0;
                incr nLine;
                if di3_Y_ok=0 THEN
                    Reset do4_Y_Gripper;
                    GOTO again;
                ENDIF
            ELSE
                nLine:=0;
                Incr nRow;
                GOTO again;
            ENDIF
        ELSE
            nLine:=0;
            nRow:=0;
            Set do1_low;
            Reset do0_up;
            pick_low;
        ENDIF
    ENDPROC

    PROC pick_low()
        again:
        IF nRow<=2 THEN
            IF nLine<=3 THEN
                MoveAbsJ Jhome\NoEOffs,v5000,fine,tool0;
                MoveJ Offs(p_low_pick,nLine*180,nRow*150,350),v2000,fine,Tool_Yellow;
                MoveL Offs(p_low_pick,nLine*180,nRow*150,0),v1000,fine,Tool_Yellow;
                Set do4_Y_Gripper;
                WaitTime 0.5;
                MoveL Offs(p_low_pick,nLine*180,nRow*150,350),v2000,fine,Tool_Yellow;
                MoveAbsJ Jhome\NoEOffs,v5000,fine,tool0;
                incr nLine;
                if di3_Y_ok=0 THEN
                    Reset do4_Y_Gripper;
                    GOTO again;
                ENDIF
            ELSE
                nLine:=0;
                Incr nRow;
                GOTO again;
            ENDIF
        ELSE
            nLine:=0;
            nRow:=0;
            set do0_up;
            Reset do1_low;
            pick_UP;
        ENDIF
    ENDPROC

    PROC take_cnc1()
        MoveAbsJ J_cnc1\NoEOffs,v5000,fine,tool0;
        MoveJ Offs(p_take_cnc1,0,0,50),v2000,fine,Tool_Green;
        MoveL p_take_cnc1,v1000,fine,Tool_Green;
        Set do5_G_Gripper;
        WaitTime 0.5;
        MoveL Offs(p_take_cnc1,0,0,50),v2000,fine,Tool_Green;
        MoveAbsJ J_cnc1\NoEOffs,v5000,fine,tool0;
        IF di2_G_ok=0 THEN
            empty_flag:=TRUE;
            TPWrite"The product is missing,pleace cheak CNC1!";
            Stop;
        ENDIF
    ENDPROC

    PROC take_cnc2()
        MoveAbsJ J_cnc2\NoEOffs,v5000,fine,tool0;
        MoveJ Offs(p_take_cnc2,0,0,50),v2000,fine,Tool_Green;
        MoveL p_take_cnc2,v1000,fine,Tool_Green;
        Set do5_G_Gripper;
        WaitTime 0.5;
        MoveL Offs(p_take_cnc2,0,0,50),v2000,fine,Tool_Green;
        MoveAbsJ J_cnc2\NoEOffs,v5000,fine,tool0;
        IF di2_G_ok=0 THEN
            empty_flag:=TRUE;
            TPWrite"The product is missing,pleace cheak CNC2!";
            Stop;
        ENDIF
    ENDPROC

    PROC PUT_CNC1()
        MoveAbsJ J_cnc1\NoEOffs,v5000,fine,tool0;
        MoveJ Offs(p_put_cnc1,0,0,50),v2000,fine,Tool_Yellow;
        MoveL p_put_cnc1,v1000,fine,Tool_Yellow;
        Reset do4_Y_Gripper;
        WaitTime 1;
        PulseDO\PLength:=2,do2_clamp;
        WaitDI di5_clamped1,1;
        MoveL Offs(p_put_cnc1,0,0,50),v2000,fine,Tool_Yellow;
        MoveAbsJ J_cnc1\NoEOffs,v5000,fine,tool0;
        PulseDO do3_door;
        IF di2_G_ok=0 empty_flag:=TRUE;
    ENDPROC

    PROC PUT_CNC2()
        MoveAbsJ J_cnc2\NoEOffs,v5000,fine,tool0;
        MoveJ Offs(p_put_cnc2,0,0,50),v2000,fine,Tool_Yellow;
        MoveL p_put_cnc2,v1000,fine,Tool_Yellow;
        Reset do4_Y_Gripper;
        WaitTime 0.5;
        PulseDO\PLength:=2,do06_clam2;
        WaitDI di7_clamped2,1;
        MoveL Offs(p_put_cnc2,0,0,50),v2000,fine,Tool_Yellow;
        MoveAbsJ J_cnc2\NoEOffs,v5000,fine,tool0;
        PulseDO do07_door2;
        IF di2_G_ok=0 empty_flag:=TRUE;
    ENDPROC

    PROC PUT_BELT()
        IF empty_flag=TRUE THEN
            Reset do5_G_Gripper;
            empty_flag:=FALSE;
            GOTO over;
        ENDIF
        MoveAbsJ J_cnc2_take\NoEOffs,v5000,fine,tool0;
        MoveL Offs(p_belt_put,0,0,50),v2000,fine,Tool_Green;
        MoveL p_belt_put,v1000,fine,Tool_Green;
        Reset do5_G_Gripper;
        WaitTime 0.5;
        MoveL Offs(p_belt_put,0,0,50),v2000,fine,Tool_Green;
        MoveAbsJ J_cnc2_take\NoEOffs,v5000,fine,tool0;
        over:
    ENDPROC

    PROC wz_zone()
        WZBoxDef\Inside,CNC1_shape1,CNC1_pos1,CNC1_pos2;
        WZDOSet\Stat,CNC1_wzstat1\Before,CNC1_shape1,do08_InCNC1,0;
        WZBoxDef\Inside,CNC2_shape2,CNC2_pos1,CNC2_pos2;
        WZDOSet\Stat,CNC2_wzstat2\Before,CNC2_shape2,do09_InCNC2,0;
        TPWrite "wz ok!";
    ENDPROC

    PROC Teache_point()
        MoveL p_belt_put,v100,z5,Tool_Green;
        MoveL p_low_pick,v100,z5,Tool_Yellow;
        MoveL p_up_pick,v100,z5,Tool_Yellow;
        MoveL p_put_cnc1,v100,z5,Tool_Yellow;
        MoveL p_take_cnc1,v100,z5,Tool_Yellow;
        MoveL p_put_cnc2,v100,z5,Tool_Green;
        MoveL p_take_cnc2,v100,z5,Tool_Green;
        MoveAbsJ Jhome,v100,fine,tool0;
        MoveAbsJ J_cnc1,v100,fine,tool0;
        MoveAbsJ J_cnc2,v100,fine,tool0;
        MoveAbsJ J_cnc2_take,v100,fine,tool0;
    ENDPROC

    
	PROC WinMove()
		WHILE TRUE DO
            WaitUntil C_Count <> 0;
            C_Move := CRobT(\Tool:=tool0\WObj:=wobj0);
            C_join := CJointT();
            TEST C_Count
            CASE 1:
            MoveL RelTool(C_Move,C_coordinate,0,0),v2000,z50,tool0;
            CASE 2:
            MoveL RelTool(C_Move,0,C_coordinate,0),v2000,z50,tool0;
            CASE 3:
            MoveL RelTool(C_Move,0,0,C_coordinate),v2000,z50,tool0;
            CASE 4:
            MoveL RelTool(C_Move,-C_coordinate,0,0),v2000,z50,tool0;
            CASE 5:
            MoveL RelTool(C_Move,0,-C_coordinate,0),v2000,z50,tool0;
            CASE 6:
            MoveL RelTool(C_Move,0,0,-C_coordinate),v2000,z50,tool0;
            CASE 7:
            MoveL RelTool(C_Move,0,0,0\Rx:=C_rotate\Ry:=0\Rz:=0), v2000, z50, tool0;
            CASE 8:
            MoveL RelTool(C_Move,0,0,0\Rx:=0\Ry:=C_rotate\Rz:=0), v2000, z50, tool0;
            CASE 9:
           MoveL RelTool(C_Move,0,0,0\Rx:=0\Ry:=0\Rz:=C_rotate), v2000, z50, tool0;
            CASE 10:
              MoveL RelTool(C_Move,0,0,0\Rx:=-C_rotate\Ry:=0\Rz:=0), v2000, z50, tool0;
             CASE 11:
              MoveL RelTool(C_Move,0,0,0\Rx:=0\Ry:=-C_rotate\Rz:=0), v2000, z50, tool0;
             CASE 12:
              MoveL RelTool(C_Move,0,0,0\Rx:=0\Ry:=0\Rz:=-C_rotate), v2000, z50, tool0;
            CASE 13:
            C_join.robax.rax_1 := C_join.robax.rax_1 + C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 14:
            C_join.robax.rax_2 := C_join.robax.rax_2 + C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 15:
            C_join.robax.rax_3 := C_join.robax.rax_3 + C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 16:
            C_join.robax.rax_1 := C_join.robax.rax_1 -C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 17:
            C_join.robax.rax_2 := C_join.robax.rax_2 -C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 18:
            C_join.robax.rax_3 := C_join.robax.rax_3 -C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 19:
            C_join.robax.rax_4 := C_join.robax.rax_4 +C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 20:
            C_join.robax.rax_5 := C_join.robax.rax_5 +C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 21:
            C_join.robax.rax_6 := C_join.robax.rax_6 +C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 22:
            C_join.robax.rax_4 := C_join.robax.rax_4 -C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 23:
            C_join.robax.rax_5 := C_join.robax.rax_5 -C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            CASE 24:
            C_join.robax.rax_6 := C_join.robax.rax_6 -C_joinMove;
            MoveAbsJ C_join\NoEOffs, v1000, z50, tool0;
            ENDTEST
            C_Count:=0;
        ENDWHILE
	ENDPROC
 
    TRAP tr_speed
        VelSet 100,no_speed;
    ENDTRAP
       
      
ENDMODULE
