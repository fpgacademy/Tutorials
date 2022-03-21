def open_dev( ):
   ''' Opens the 7-segment displays HEX device
   
   :return: 1 on success, else 0
   '''


def set(data):
   ''' Sets the HEX device in decimal number mode
   
   :param data: an integer to be displayed as a 6-digit decimal number. The upper
      two digits will be displayed on HEX5-4, and the lower four on HEX3-0
   :return: none
   '''


def raw(data1, data2):
   ''' Sets the HEX device in raw mode
   
   :param data1: an integer that is written to HEX5-4 as raw bits
   :param data2: an integer that is written to HEX3-0 as raw bits
   :return: none
   '''


def close( ):
   ''' Closes the HEX device
   
   :return: none
   '''


