MODULE MainModule
    TASK PERS tooldata MyTool:=[TRUE,[[0,0,704.774],[0,0,1,0]],[66.1,[0,0,310],[1,0,0,0],0,0,8.72]];

    CONST robtarget pHome:=[[2018.16,-93.17,925.05],[0.701404,0,0,0.712764],[-1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pGet:=[[2026,-85.96,-419],[0.700736,0,0,0.71342],[-1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pWait:=[[2042.99,-86.66,-210],[0,-0.696824,0.717242,0],[-1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pPut:=[[-18.92,1569.57,-995.45],[0.999947,0,0,0.0103142],[1,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pGetClapBorad:=[[1545.68,1996.54,1088.97],[0.700701,0,0,0.713455],[0,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pPutClapBorad:=[[-419.77,2065.43,-657.46],[0.70048,0,0,0.713672],[1,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pStandard:=[[1800,-100.08,280.06],[1,0,0,0],[-1,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget pMiddle:=[[1500,690.37,-150],[0,0.712772,-0.701396,0],[0,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    VAR robtarget Wait;
    VAR robtarget Get;
    VAR robtarget Put;
    VAR robtarget GetClapBorad;
    VAR robtarget PutClapBorad;
    VAR robtarget SL_Location;
    VAR robtarget Middle;

    PERS num Layer;
    PERS num ResetCountAsk;
    PERS num SetRunSpeed;
    PERS num AllowStacking;
    PERS num OneBundleCount;
    PERS num NowStackingSum;
    PERS num Stacking;
    PERS num OrderLength;
    PERS num OrderWidth;
    PERS num OrderHigh;
    PERS num OrderLoad;
    PERS num PutOffsetHigh;
    PERS num PracticalOneBundleCount;
    PERS num CompensationHight;

    PERS num Get_x;
    PERS num Get_y;
    PERS num Get_z;
    PERS num Get_a;
    PERS num Get_b;
    PERS num Get_c;

    PERS num Init_x;
    PERS num Init_y;
    PERS num Init_z;
    PERS num Init_a;
    PERS num Init_b;
    PERS num Init_c;

    PERS num GetClapBorad_x;
    PERS num GetClapBorad_y;
    PERS num GetClapBorad_z;
    PERS num GetClapBorad_a;
    PERS num GetClapBorad_b;
    PERS num GetClapBorad_c;

    PERS num PutClapBorad_x;
    PERS num PutClapBorad_y;
    PERS num PutClapBorad_z;
    PERS num PutClapBorad_a;
    PERS num PutClapBorad_b;
    PERS num PutClapBorad_c;

    PERS num PutData{4,12,6};

    PERS num StartNum;
    PERS num count;
    PERS num NowLayer;
    PERS num Plus1;
    PERS num Plus2;

    PERS num Trig_GetTime:=0.15;
    PERS num Trig_PutTime:=0.16;
    PERS num Trig_GetClapBorad:=0.5;

    VAR num CT;

    PERS num UpLocation_z;

    PERS speeddata Get_Speed:=[5000,5000,5000,1000];
    PERS speeddata Get_MinSpeed:=[30,30,5000,1000];

    PERS speeddata Put_Speed:=[5000,5000,5000,1000];
    PERS speeddata Put_MinSpeed:=[2000,2000,5000,1000];

    PERS speeddata GetClapBorad_Speed:=[3000,3000,4000,1000];
    PERS speeddata GetClapBorad_MinSpeed:=[500,500,5000,1000];

    PERS speeddata PutClapBorad_Speed:=[4000,4000,5000,1000];
    PERS speeddata PutClapBorad_MinSpeed:=[500,500,5000,1000];

    PERS pos Corner1:=[1650,479,3000];
    PERS pos Corner2:=[-268,2082,-2000];

    VAR string Date;
    VAR string Time;

    VAR intnum Intno1;
    VAR intnum Intno2;
    VAR intnum Intno3;
    VAR intnum Intno4;

    VAR bool NG;

    PERS bool Socket_ConnectOK;

    VAR shapedata Volume;
    VAR wzstationary Service;

    PROC main()
        WaitUntil Socket_ConnectOK=TRUE;
        rInitall;
        ClkReset clock1;
        ClkStart clock1;
        WHILE TRUE DO
            WaitUntil Socket_ConnectOK=TRUE;
            rPGet;
            rPut;
            IF Layer=NowLayer THEN
                SetGO PGO2_AllStackingDone,1;
                SetGO PGO4_NowLayer,0;
                SetGO PGO5_NowCount,0;
                SetGO PGO8_NowPutCount,0;
                Wait:=Get;
                IF pWait.trans.z-Get_z<OneBundleCount+75 THEN
                    Wait.trans.z:=OneBundleCount+75+Get_z;
                ELSE
                    Wait.trans.z:=pWait.trans.z;
                ENDIF
                NowLayer:=0;
                NG:=FALSE;
                StartNum:=1;
                count:=1;
                NowLayer:=0;
                CompensationHight:=0;
                UpLocation_z:=0;
                Plus1:=0;
                Plus2:=0;
                Middle.trans.x:=pMiddle.trans.x;
                Middle.trans.y:=pMiddle.trans.y;
                Middle.trans.z:=pMiddle.trans.z;
                ClkStop clock1;
                Date:=CDate();
                Time:=CTime();
                TPWrite ""+Date+" "+Time+""+"Shot peening time is"\num:=ClkRead(clock1);
                CT:=Round(ClkRead(clock1));
                SetGO PGO7_Speed,CT;
                !Stop;
                !-------------------------------------------------------------
            ENDIF
            IF Middle.trans.z<=(PutData{1,count,3}+((NowLayer+1)*PracticalOneBundleCount)+CompensationHight+PutOffsetHigh) AND count=1 THEN
                Middle.trans.z:=(PutData{1,count,3}+((NowLayer+1)*PracticalOneBundleCount)+CompensationHight+PutOffsetHigh);
            ENDIF
        ENDWHILE
    ENDPROC

    PROC rInitall()
        IDelete Intno1;
        IDelete Intno2;
        IDelete Intno3;
        IDelete Intno4;
        CONNECT Intno1 WITH Tr_SetRunSpeed;
        ISignalGI PGI3_SetRunSpeed,Intno1;
        CONNECT Intno2 WITH Tr_RsetAllStackingDone;
        ISignalDI PDI6_ResetAllStackingDone,1,Intno2;
        CONNECT Intno3 WITH Tr_DetectionCount;
        ISignalDI DI7_HightDetection,0,Intno3;
        CONNECT Intno4 WITH Tr_DynamicCompensation;
        ISignalDI DI7_HightDetection,0,Intno4;
        ISleep Intno3;
        ISleep Intno4;
        Reset PDO2_RobotFault;
        Reset PDO3_RobotHomeDone;
        Reset PDO5_RobotGetCartonDone;
        Reset DO3_JigMotorMinPuff;
        Reset DO4_JigMotorBigPuff;
        Reset DO5_JigMotorClamp;
        Reset PDO6_JigCylinderPush;
        Reset PDO7_JigCylinderClamp;
        Reset PDO8_RobotGetClapboardDone;
        Reset PDO9_RobotPutClapboardDone;
        SetGO PGO1_PlasticStart,0;
        SetGO PGO2_AllStackingDone,0;
        SetGO PGO3_SingleStackingDone,0;
        SetGO PGO4_NowLayer,0;
        SetGO PGO5_NowCount,0;
        SetGO PGO7_Speed,0;
        SetGO PGO8_NowPutCount,0;
        SetGO PGO15_OneBundleCount,0;
        SetGO PGO16_NowStackingHigh,0;
        NG:=FALSE;
        StartNum:=1;
        count:=1;
        NowLayer:=0;
        Plus1:=0;
        Plus2:=0;
        PracticalOneBundleCount:=0;
        CompensationHight:=0;
        UpLocation_z:=0;
        rCheckHomePos;
        Set PDO3_RobotHomeDone;
        WaitTime 0.8;
        Reset PDO3_RobotHomeDone;
        Get:=pStandard;
        Get.trans.x:=Get_x;
        Get.trans.y:=Get_y;
        Get.trans.z:=Get_z;
        Get.rot:=Get.rot*OrientZYX(Get_a,0,0);
        Wait:=Get;
        IF pWait.trans.z-Get_z<OneBundleCount+75 THEN
            Wait.trans.z:=OneBundleCount+75+Get_z;
        ELSE
            Wait.trans.z:=pWait.trans.z;
        ENDIF
        !***Middle***
        Middle:=Get;
        Middle.trans.x:=pMiddle.trans.x;
        Middle.trans.y:=pMiddle.trans.y;
        Middle.trans.z:=pMiddle.trans.z;
        !***Middle***
        Set DO4_JigMotorBigPuff;
        WaitTime 0.2;
        WaitDI DI5_JigMotorBigPuffDone,1;
        Reset DO4_JigMotorBigPuff;
    ENDPROC

    PROC rPGet()
        VAR triggdata Trig_ddat;
        AA:
        Get:=pStandard;
        Get.trans.x:=Get_x;
        Get.trans.y:=Get_y;
        Get.trans.z:=Get_z;
        Get.rot:=Get.rot*OrientZYX(Get_a,0,0);
        WaitUntil PDI8_JigCylinderShrinkDone=1 AND PDI5_PutCartonDone=1;
        IF NowLayer=0 AND count=1 THEN
            !Fist Set 0;   
            MoveL Wait,Get_Speed,fine,MyTool\WObj:=wobj0;
            WHILE DI7_HightDetection=1 DO
                ErrWrite "Induced Error","Please check whether DI7_HightDetection is 0 ";
                Stop;
            ENDWHILE
            SearchL\SStop,DI7_HightDetection,SL_Location,Get,Get_MinSpeed,MyTool;
            PracticalOneBundleCount:=Round(Abs(SL_Location.trans.z-Get_z)+23);
            !The Add Offset Value;(JigDowOffset);
            !rSetdata\INT,PGO15_RbootStackHight,Round(SL_Location.trans.z);  !Send OneBundleHigh To PLC;
            SetGO PGO15_OneBundleCount,PracticalOneBundleCount;
            SetGO PGO16_NowStackingHigh,0;
            WHILE PracticalOneBundleCount>(OneBundleCount+100) OR PracticalOneBundleCount<(OneBundleCount-100) DO
                Reset DO5_JigMotorClamp;
                ErrWrite "Carton size error","Please check the PracticalOneBundleCoun";
                Set DO2_RobotFault;
                MoveL Wait,v500,fine,MyTool;
                Stop;
                Reset DO2_RobotFault;
            ENDWHILE
            MoveLDO Get,Get_Speed,fine,MyTool,DO5_JigMotorClamp,1;
        ELSE
            !TriggEquip Trig_ddat,10,Trig_GetTime\DOp:=DO5_JigMotorClamp,1;
            TriggIO Trig_ddat,Trig_GetTime\Time\DOp:=DO5_JigMotorClamp,1;
            TriggL Get,Get_Speed,Trig_ddat,fine,MyTool;
            !MoveLDO Get,Get_Speed,fine,MyTool,DO5_JigMotorClamp,1;
        ENDIF
        IWatch Intno3;
        SetGO PGO3_SingleStackingDone,0;
        SetGO PGO2_AllStackingDone,0;
        SetGO PGO1_PlasticStart,0;
        WaitDI DI6_JigMotorClampDone,1;
        MoveLDO Wait,Get_Speed,z200,MyTool,DO5_JigMotorClamp,0;
        WaitDI DI7_HightDetection,1\MaxTime:=3\TimeFlag:=NG;
        IF NG=TRUE THEN
            NG:=FALSE;
            PulseDO\PLength:=0.4,DO4_JigMotorBigPuff;
            WaitDI PDI5_PutCartonDone,1;
            Set DO2_RobotFault;
            ErrWrite "NO Carton","Please check the carton";
            Stop;
            Reset DO2_RobotFault;
            GOTO AA;
        ENDIF
        PulseDO\PLength:=0.4,PDO5_RobotGetCartonDone;
    ERROR
        IF ERRNO=ERR_WHLSEARCH THEN
            MoveL Wait,v500,fine,MyTool;
            ErrWrite "Search for the error","The robot did not find the carton";
            EXIT;
            RETRY;
        ENDIF
    ENDPROC

    PROC rPut()
        VAR triggdata Trig_dat;
        WaitUntil PGI4_AllowStacking=1;
        !*******---1---******!  
        IF StartNum=1 THEN
            Put:=pStandard;
            Put.trans.x:=PutData{1,count,1};
            Put.trans.y:=PutData{1,count,2};
            Put.trans.z:=PutData{1,count,3};
            Put.rot:=Put.rot*OrientZYX(PutData{1,count,4},0,0);
            IF Put.trans.z+(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<Wait.trans.z THEN
                !***Middle*** 
                IF PutData{1,count,4}>-175 AND PutData{1,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{1,count,4}>0 AND PutData{1,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{1,count,1}-PutData{1,1,1}+PutData{1,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                IF (NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<300 THEN
                    MoveL Offs(Put,0,0,300),Put_Speed,z200,MyTool;
                ELSE
                    MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    IF (NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<300 THEN
                        MoveL Offs(Put,0,0,300),Put_MinSpeed,fine,MyTool;
                    ELSE
                        MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                    ENDIF
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z100,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z200,MyTool;
                    IF (NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<300 THEN
                        MoveL Offs(Put,0,0,300),Put_Speed,z200,MyTool;
                    ELSE
                        MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                    ENDIF
                ENDIF
            ELSE
                !***Middle***
                IF PutData{1,count,4}>-175 AND PutData{1,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{1,count,4}>0 AND PutData{1,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{1,count,1}-PutData{1,1,1}+PutData{1,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z100,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
            ENDIF
            count:=count+1;
            SetGO PGO3_SingleStackingDone,1;
            SetGO PGO8_NowPutCount,count-1;
            IF (count-1)>=NowStackingSum THEN
                IF PDI10_PackingPaperCount=1 THEN
                    rGetClapBorad;
                ENDIF
                count:=1;
                NowLayer:=NowLayer+1;
                SetGO PGO4_NowLayer,NowLayer;
                Plus1:=Plus1+2;
                StartNum:=2;
                SetGO PGO1_PlasticStart,1;
            ENDIF
            !*******---2---******!  
        ELSEIF StartNum=2 THEN
            Put:=pStandard;
            Put.trans.x:=PutData{2,count,1};
            Put.trans.y:=PutData{2,count,2};
            Put.trans.z:=PutData{1,count,3};
            Put.rot:=Put.rot*OrientZYX(PutData{2,count,4},0,0);
            IF Put.trans.z+(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh<Wait.trans.z THEN
                !***Middle***  
                IF PutData{2,count,4}>-175 AND PutData{2,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{2,count,4}>0 AND PutData{2,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{2,count,1}-PutData{1,1,1}+PutData{2,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                IF (NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<300 THEN
                    MoveL Offs(Put,0,0,300),Put_Speed,z200,MyTool;
                ELSE
                    MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    IF (NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<300 THEN
                        MoveL Offs(Put,0,0,300),Put_MinSpeed,fine,MyTool;
                    ELSE
                        MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                    ENDIF
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z100,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z200,MyTool;
                    IF (NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<300 THEN
                        MoveL Offs(Put,0,0,300),Put_Speed,z200,MyTool;
                    ELSE
                        MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                    ENDIF
                ENDIF
            ELSE
                !***Middle***
                IF PutData{2,count,4}>-175 AND PutData{2,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{2,count,4}>0 AND PutData{2,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{2,count,1}-PutData{1,1,1}+PutData{2,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
            ENDIF
            count:=count+1;
            SetGO PGO3_SingleStackingDone,1;
            SetGO PGO8_NowPutCount,count-1;
            IF (count-1)>=NowStackingSum THEN
                IF PDI10_PackingPaperCount=1 THEN
                    rGetClapBorad;
                ENDIF
                count:=1;
                NowLayer:=NowLayer+1;
                SetGO PGO4_NowLayer,NowLayer;
                Plus2:=Plus2+2;
                StartNum:=3;
                SetGO PGO1_PlasticStart,1;
            ENDIF
            !*******---3---******!  
        ELSEIF StartNum=3 THEN
            Put:=pStandard;
            Put.trans.x:=PutData{3,count,1};
            Put.trans.y:=PutData{3,count,2};
            Put.trans.z:=PutData{1,count,3};
            Put.rot:=Put.rot*OrientZYX(PutData{3,count,4},0,0);
            IF Put.trans.z+(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh<Wait.trans.z THEN
                !***Middle***   
                IF PutData{3,count,4}>-175 AND PutData{3,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{3,count,4}>0 AND PutData{3,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{3,count,1}-PutData{1,1,1}+PutData{3,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z100,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z200,MyTool;
                    MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
            ELSE
                !***Middle***
                IF PutData{3,count,4}>-175 AND PutData{3,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{3,count,4}>0 AND PutData{3,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.4),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{3,count,1}-PutData{1,1,1}+PutData{3,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
            ENDIF
            count:=count+1;
            SetGO PGO3_SingleStackingDone,1;
            SetGO PGO8_NowPutCount,count-1;
            IF (count-1)>=NowStackingSum THEN
                IF PDI10_PackingPaperCount=1 THEN
                    rGetClapBorad;
                ENDIF
                count:=1;
                NowLayer:=NowLayer+1;
                SetGO PGO4_NowLayer,NowLayer;
                Plus1:=Plus1+2;
                StartNum:=4;
                SetGO PGO1_PlasticStart,1;
            ENDIF
            !*******---4---******!         
        ELSEIF StartNum=4 THEN
            Put:=pStandard;
            Put.trans.x:=PutData{4,count,1};
            Put.trans.y:=PutData{4,count,2};
            Put.trans.z:=PutData{1,count,3};
            Put.rot:=Put.rot*OrientZYX(PutData{4,count,4},0,0);
            IF Put.trans.z+(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh<Wait.trans.z THEN
                !***Middle***   
                IF PutData{4,count,4}>-175 AND PutData{4,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{4,count,4}>0 AND PutData{4,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{4,count,1}-PutData{1,1,1}+PutData{4,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z100,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    !MoveL Offs(Put,0,0,Wait.trans.z-PutData{1,count,3}),Put_Speed,z200,MyTool;
                    MoveL Offs(Put,0,0,(NowLayer+1)*(PracticalOneBundleCount)+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
            ELSE
                !***Middle***
                IF PutData{4,count,4}>-175 AND PutData{4,count,4}<0 THEN
                    Middle.rot:=OrientZYX(Get_a+(180*0.3),0,0);
                ELSEIF PutData{4,count,4}>0 AND PutData{4,count,4}<Get_a THEN
                    Middle.rot:=OrientZYX(Get_a-(Get_a*0.35),0,0);
                ELSE
                    Middle.rot:=OrientZYX(Get_a,0,0);
                ENDIF
                Middle.trans.x:=pMiddle.trans.x+(PutData{4,count,1}-PutData{1,1,1}+PutData{4,count,2}-PutData{1,1,2})*0.4;
                MoveL Middle,Put_Speed,z200,MyTool;
                !***Middle***
                MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                !TriggEquip Trig_dat,10,Trig_PutTime\DOp:=DO3_JigMotorMinPuff,1;
                TriggIO Trig_dat,Trig_PutTime\Time\DOp:=DO3_JigMotorMinPuff,1;
                TriggL Offs(Put,0,0,(NowLayer*(PracticalOneBundleCount))+CompensationHight),Put_Speed,Trig_dat,fine,MyTool;
                !MoveLDO Offs(Put,0,0,NowLayer*(PracticalOneBundleCount)),Put_Speed,fine,MyTool,DO3_JigMotorMinPuff,1;
                ISleep Intno3;
                IF count=NowStackingSum THEN
                    IWatch Intno4;
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_MinSpeed,fine,MyTool;
                ELSE
                    WaitDI DI4_JigMotorMinPuffDone,1;
                    Reset DO3_JigMotorMinPuff;
                    MoveL Offs(Put,0,0,(NowLayer+1)*PracticalOneBundleCount+CompensationHight+PutOffsetHigh),Put_Speed,z200,MyTool;
                ENDIF
            ENDIF
            count:=count+1;
            SetGO PGO3_SingleStackingDone,1;
            SetGO PGO8_NowPutCount,count-1;
            IF (count-1)>=NowStackingSum THEN
                IF PDI10_PackingPaperCount=1 THEN
                    rGetClapBorad;
                ENDIF
                count:=1;
                NowLayer:=NowLayer+1;
                SetGO PGO4_NowLayer,NowLayer;
                Plus2:=Plus2+2;
                StartNum:=1;
                SetGO PGO1_PlasticStart,1;
            ENDIF
        ENDIF
        SetGO PGO5_NowCount,(NowLayer*NowStackingSum)+(count-1);
        ISleep Intno4;
        !***Middle***
        !Middle.trans.z:=Wait.trans.z;
        MoveL Middle,Get_Speed,z200,MyTool;
        !***Middle***
        MoveL Wait,Get_Speed,z200,MyTool;
        PulseDO\PLength:=0.4,DO4_JigMotorBigPuff;
    ENDPROC

    PROC rGetClapBorad()
        VAR triggdata Trig_datGetClapBorad;
        GetClapBorad:=pStandard;
        GetClapBorad.trans.x:=GetClapBorad_x;
        GetClapBorad.trans.y:=GetClapBorad_y;
        GetClapBorad.trans.z:=GetClapBorad_z;
        GetClapBorad.rot:=GetClapBorad.rot*OrientZYX(GetClapBorad_a,0,0);
        TriggIO Trig_datGetClapBorad,Trig_GetClapBorad\Time\DOp:=PDO6_JigCylinderPush,1;
        TriggL Offs(GetClapBorad,-200,0,0),GetClapBorad_Speed,Trig_datGetClapBorad,z200,MyTool;
        ISleep Intno4;
        PutClapBorad:=pStandard;
        PutClapBorad.trans.x:=PutClapBorad_x;
        PutClapBorad.trans.y:=PutClapBorad_y;
        PutClapBorad.trans.z:=PutClapBorad_z;
        PutClapBorad.rot:=PutClapBorad.rot*OrientZYX(PutClapBorad_a,0,0);
        WaitUntil PDI7_JigCylinderPushDone=1 AND PDI9_PutClapboardDoen=1;
        !MoveLDO GetClapBorad,GetClapBorad_Speed,fine,MyTool,PDO7_JigCylinderClamp,1;
        MoveL GetClapBorad,GetClapBorad_Speed,fine,MyTool;
        WaitTime\inpos,0.5;
        Set PDO7_JigCylinderClamp;
        WaitTime\inpos,0.5;
        WaitDI PDI12_JigCylinderClampDone,1;
        MoveL Offs(GetClapBorad,-200,0,0),GetClapBorad_Speed,z200,MyTool;
        MoveLDO Offs(PutClapBorad,0,0,(PracticalOneBundleCount*(NowLayer))+CompensationHight+100),PutClapBorad_Speed,fine,MyTool,PDO7_JigCylinderClamp,0;
        Reset PDO6_JigCylinderPush;
        WaitUntil PDI8_JigCylinderShrinkDone=1 AND PDI13_JigCylinderPuffDone=1;
        IF PutClapBorad.trans.z+(PracticalOneBundleCount*(NowLayer))<Wait.trans.z THEN
            MoveL Offs(PutClapBorad,0,0,Wait.trans.z-PutClapBorad.trans.z),PutClapBorad_Speed,z200,MyTool;
        ENDIF
    ENDPROC

    PROC rCheckHomePos()
        VAR robtarget home;
        BB:
        home:=CRobT(\Tool:=MyTool);
        IF (home.trans.x>GetClapBorad_x-200 AND home.trans.y>420) OR PDI4_PalletHome<>1 THEN
            Date:=CDate();
            Time:=CTime();
            TPWrite ""+Date+" "+Time+" "+"Please move the robot to the origin!";
            Stop;
            GOTO BB;
        ELSEIF home.trans.x<GetClapBorad_x-200 AND home.trans.y>420 THEN
            home.trans.z:=pHome.trans.z;
            MoveL home,v200,z50,MyTool;
            home.trans.x:=GetClapBorad_x-200;
            MoveL home,v200,z50,MyTool;
            home.trans.y:=pHome.trans.y;
            MoveL home,v200,z50,MyTool;
            MoveJ pHome,v200,fine,MyTool;

        ELSEIF home.trans.z<pHome.trans.z AND home.trans.y<420 THEN
            home.trans.z:=pHome.trans.z;
            MoveL home,v200,z50,MyTool;
            MoveJ pHome,v200,fine,MyTool;
        ELSE
            MoveJ pHome,v200,fine,MyTool;
        ENDIF
    ENDPROC

    PROC rWorldZone()
        Corner1:=[1650,479,3000];
        Corner2:=[-268,2082,-2000];
        WZBoxDef\Inside,Volume,Corner1,Corner2;
        WZDOSet\Stat,Service\Inside,Volume,PDO4_RobotRiskSignal,0;
        Date:=CDate();
        Time:=CTime();
        TPWrite ""+Date+" "+Time+" "+"WorldZone is Runing";
    ENDPROC

    PROC rCalibration()
        MoveL pHome,v200,fine,MyTool;
        Stop;
        MoveL pGet,v200,fine,MyTool;
        Stop;
        MoveL pWait,v200,fine,MyTool;
        Stop;
        MoveL pPut,v200,fine,MyTool;
        Stop;
        MoveL pGetClapBorad,v200,fine,MyTool;
        Stop;
        MoveL pPutClapBorad,v200,fine,MyTool;
        Stop;
        MoveL pMiddle,v200,fine,MyTool;
    ENDPROC

    TRAP Tr_RsetAllStackingDone
        IF PGO2_AllStackingDone=1 THEN
            SetGO PGO2_AllStackingDone,0;
            Date:=CDate();
            Time:=CTime();
            TPWrite ""+Date+" "+Time+" "+"PGO2_AllStackingDone:=0";
        ENDIF
    ENDTRAP

    TRAP Tr_SetRunSpeed
        SpeedRefresh PGI3_SetRunSpeed;
        Date:=CDate();
        Time:=CTime();
        TPWrite ""+Date+" "+Time+" "+"Speed Percentage:="\num:=PGI3_SetRunSpeed;
    ENDTRAP

    TRAP Tr_DetectionCount
        Set DO2_RobotFault;
        ErrWrite "NO Carton","Please check the carton";
        Stop;
        Reset DO2_RobotFault;
    ENDTRAP

    TRAP Tr_DynamicCompensation
        VAR num NowStackingHigh;
        VAR robtarget Location;

        Location:=CRobT(\Tool:=MyTool);
        IF NowLayer>1 THEN
            IF (Location.trans.z-UpLocation_z)-PracticalOneBundleCount<-120 THEN
                CompensationHight:=0;
            ELSE
                CompensationHight:=Location.trans.z-(Put.trans.z+((NowLayer+1)*PracticalOneBundleCount))+40;
            ENDIF
        ELSE
            CompensationHight:=Location.trans.z-(Put.trans.z+((NowLayer+1)*PracticalOneBundleCount))+40;
        ENDIF
        SetGO PGO16_NowStackingHigh,Round(((NowLayer+1)*PracticalOneBundleCount)+CompensationHight);
        Date:=CDate();
        Time:=CTime();
        TPWrite ""+Date+" "+Time+" "+"NowHight:="\num:=CompensationHight;
        UpLocation_z:=Location.trans.z;
    ENDTRAP
ENDMODULE
