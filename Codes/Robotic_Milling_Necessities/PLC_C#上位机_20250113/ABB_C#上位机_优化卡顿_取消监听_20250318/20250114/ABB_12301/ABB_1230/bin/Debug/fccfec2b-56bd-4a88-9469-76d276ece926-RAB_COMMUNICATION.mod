
MODULE RAB_COMMUNICATION
    VAR bool flag := FALSE;
    VAR intnum connectnum;
    PROC main1()
        CONNECT connectnum WITH RABMsgs;
        IRMQMessage flag, connectnum;
        WHILE flag = FALSE DO
            !do something, eg. normal processing...
            WaitTime 3;
        ENDWHILE
        !PC SDK message received - do something...
        TPWrite ""\Bool:=flag;
        TPWrite "Message from PC SDK, will now...";
        IDelete connectnum;
        EXIT;
    ENDPROC
    TRAP RABMsgs
        VAR rmqmessage msg;
        VAR rmqheader header;
        VAR rmqslot rabclient;
        VAR num userdef;
        VAR string ack := "abcd";
        RMQGetMessage msg;
        RMQGetMsgHeader msg \Header:=header
            \SenderId:=rabclient\UserDef:=userdef;
        !check data type and assign value to flag variable
        IF header.datatype = "bool" THEN
            RMQGetMsgData msg, flag;
            !return receipt to sender
            RMQSendMessage rabclient, ack;
        ELSE
            TPWrite "Unknown data received in RABMsgs...";
        ENDIF
    ENDTRAP
ENDMODULE