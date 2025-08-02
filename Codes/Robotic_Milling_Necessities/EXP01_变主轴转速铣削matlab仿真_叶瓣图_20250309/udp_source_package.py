
import socket

UDP_IP = "192.168.88.2"

UDP_PORT = 1600


sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

sock.bind((UDP_IP, 1600))


print(f"Listening on UDP {UDP_IP}:1600...")


while True:

    data, addr = sock.recvfrom(1024) # 接收数据包，最大长度1024字节
    print(f"接收到数据来自 {addr}: {data.hex()}")