MAX_VOLUME = 0x7FFFFFFF
MAX_SAMPLING_RATE, MID_SAMPLING_RATE, MIN_SAMPLING_RATE = 48000, 32000, 8000

def open_dev( ):
   ''' Opens the digital audio device
   
   :return: 1 on success, else 0
   '''


def read( ):
   ''' Reads the audio device
   
   :return: two integers: left-channel data, right-channel data
   '''


def init( ):
   ''' Initializes the audio device
   
   :return: none
   '''


def sampling_rate(data):
   ''' Sets the audio device sampling rate
   
   :param data: sampling rate in thousands/sec., where data = {8000, 32000, 48000}
   :return: none
   '''


def wait_write( ):
   ''' Waits for space to be available for writing to the audio device
   
   :return: none
   '''


def wait_read( ):
   ''' Waits until data is available for reading from the audio device
   
   :return: none
   '''


def write_left(data):
   ''' Writes data to the left audio channel
   
   :param data: integer value to be written
   :return: none
   '''


def write_right(data):
   ''' Writes data to the right audio channel
   
   :param data: integer value to be written
   :return: none
   '''


def close( ):
   ''' Closes the audio device
   
   :return: none
   '''


