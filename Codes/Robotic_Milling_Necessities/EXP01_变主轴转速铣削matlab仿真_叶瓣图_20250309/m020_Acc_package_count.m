clc;
clear;

u = udpport("datagram", "IPV4", "LocalHost", "192.168.88.2", "LocalPort", 1600);
disp('UDP服务器正在监听192.168.88.2:1600...');

packetCounter = 0;
tStart = tic;

while true
    if u.NumDatagramsAvailable > 0
        data = read(u, u.NumDatagramsAvailable, "uint8");
        packetCounter = packetCounter + length(data);

        for i = 1:length(data)
            hexStr = join(string(dec2hex(data(i).Data, 2)'), ' ');
            % fprintf('来自 %s:%d：%s\n', data(i).SenderAddress, data(i).SenderPort, hexStr);
        end
    end

    if toc(tStart) >= 1
        fprintf('每秒收到的数据包数量：%d个\n', packetCounter);
        packetCounter = 0;
        tStart = tic;
    end
    pause(0.01); % 降低CPU占用
end
