def open_dev( ):
   ''' Opens the 3D-accelerometer accel device
   
   :return: 1 on success, else 0
   '''


def read( ):
   ''' Reads the accel device
   
   :return: seven integers: ready (1 if new acceleration data is available, else 0),
      tap (1 if tap event, else 0), dtap (1 if double-tap event, else 0), 
      x (acceleration in the x axis), y (... y axis), z (... z axis), 
      scale (mG per lsb scale factor for acceleration data)
   '''


def init( ):
   ''' Initializes the 3D-acceleration device
   
   :return: none
   '''


def calibrate( ):
   ''' Calibrates the 3D-acceleration device
   
   :return: none
   '''


def device( ):
   ''' Request printing of the device ID from the 3D-acceleration device
   
   :return: none
   '''


def format(full, range):
   ''' Sets the format of acceleration data
   
   :param full: integer value of 1 sets full resolution
   :param range: integer to set the G range to {2, 4, 8, 16}
   :return: none
   '''


def rate(rate):
   ''' Sets the data rate of acceleration data
   
   :param rate: float value to set rate to {25,12.5,6.25,1.56,0.78} Hz
   :return: none
   '''


def close( ):
   ''' Closes the accel device
   
   :return: none
   '''


