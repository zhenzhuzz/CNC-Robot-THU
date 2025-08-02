import socket
import struct
import pyqtgraph as pg
import numpy as np

# UDP configuration
UDP_IP = "192.168.88.2"
UDP_PORT = 1600

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.settimeout(0.001)  # ultra low latency

# Buffer configuration (20 seconds at 8000Hz)
sampling_rate = 8000  # samples per second
buffer_duration = 20  # seconds
buffer_size = sampling_rate * buffer_duration  # total number of samples

# Initialize circular buffers for each acceleration axis
data_x = np.zeros(buffer_size)
data_y = np.zeros(buffer_size)
data_z = np.zeros(buffer_size)
ptr = 0  # global pointer for new data position

# PyQtGraph realtime plotting initialization
app = pg.mkQApp("Realtime XYZ Acceleration")
win = pg.GraphicsLayoutWidget(show=True, title="Realtime XYZ Acceleration")
win.resize(1000, 600)

p_x = win.addPlot(title="Acc X (mg)")
p_x.showGrid(True, True)
win.nextRow()

p_y = win.addPlot(title="Acc Y (mg)")
p_y.showGrid(True, True)
win.nextRow()

p_z = win.addPlot(title="Acc Z (mg)")
p_z.showGrid(True, True)

def get_buffer_data(data_array, ptr, buffer_size):
    """
    Returns the circular buffer data in the correct chronological order.
    Think of it like reordering a circular tape so the playhead always starts at the oldest sample.
    """
    n = min(ptr, buffer_size)
    if ptr < buffer_size:
        return data_array[:n]
    else:
        idx = ptr % buffer_size
        # Concatenate the tail and head of the circular buffer to form a continuous array.
        return np.concatenate((data_array[idx:], data_array[:idx]))

def update():
    global ptr, data_x, data_y, data_z
    # Drain the UDP socket: process all available packets
    while True:
        try:
            data, addr = sock.recvfrom(1024)
            # Check that the packet is large enough (56 bytes expected in original code)
            if len(data) >= 56:
                # Extract 3 short integers from bytes 4 to 10 representing acceleration (x, y, z)
                acc_x, acc_y, acc_z = struct.unpack('<hhh', data[4:10])
                # Update the circular buffers
                data_x[ptr % buffer_size] = acc_x
                data_y[ptr % buffer_size] = acc_y
                data_z[ptr % buffer_size] = acc_z
                ptr += 1
        except socket.timeout:
            break

    # Retrieve data in the correct order from the circular buffers
    x_data = get_buffer_data(data_x, ptr, buffer_size)
    y_data = get_buffer_data(data_y, ptr, buffer_size)
    z_data = get_buffer_data(data_z, ptr, buffer_size)
    # Create a time axis in seconds
    time_axis = np.arange(len(x_data)) / sampling_rate

    # Update plots with new data
    p_x.clear()
    p_x.plot(time_axis, x_data, pen='r')
    p_x.setTitle('Acc X (mg)')

    p_y.clear()
    p_y.plot(time_axis, y_data, pen='g')
    p_y.setTitle('Acc Y (mg)')

    p_z.clear()
    p_z.plot(time_axis, z_data, pen='b')
    p_z.setTitle('Acc Z (mg)')

# Setup timer to refresh the plots every 10 ms (~100Hz)
timer = pg.QtCore.QTimer()
timer.timeout.connect(update)
timer.start(10)

pg.exec()
