# define some graphics colors
WHITE, YELLOW, RED, GREEN, BLUE, CYAN, MAGENTA, GREY, PINK, ORANGE = \
   0xFFFF, 0xFFE0, 0xF800, 0x07E0, 0x041F, 0x07FF, 0xF81F, 0xC618, 0xFC18, 0xFC00

def open_dev( ):
   ''' Opens the VGA video device
   
   :return: 1 on success, else 0
   '''


def read( ):
   ''' Reads the video device
   
   :return: four integers: screen_x (x resolution), screen_x (y resolution), 
      char_x (# of text columns), char_y (# of text lines)
   '''


def clear( ):
   ''' Erases all graphics in the current video frame buffer
   
   :return: none
   '''


def pixel(x, y, color):
   ''' Sets the pixel at coordinates (x, y) to color
   
   :param x: the column
   :param y: the row
   :param color: 16-bit VGA color
   :return: none
   '''


def line(x1, y1, x2, y2, color):
   ''' Draws a color line from graphics point (x1, y1) to (x2, y2)
   
   :param x1: the column for one end of the line
   :param y1: the row for one end of the line
   :param x2: the column for the other end of the line
   :param y2: the row for the other end of the line
   :param color: 16-bit VGA color
   :return: none
   '''


def box(x1, y1, x2, y2, color):
   ''' Draws a filled color box from corner (x1, y1) to corner (x2, y2)
 
   :param x1: the column for one corner
   :param y1: the row for one corner
   :param x2: the column for the opposite corner
   :param y2: the row for the opposite corner
   :param color: 16-bit VGA color
   :return: none
   '''


def text(x, y, msg):
   ''' Draws the text msg at character coordinates (x, y)

   :param x: the character column
   :param y: the character row
   :param msg: the text string
   :return: none
   '''


def erase( ):
   ''' Erases all text in the video character buffer
   
   :return: none
   '''


def show( ):
   ''' Swaps the front/back video frame buffers
   
   :return: none
   '''


def close( ):
   ''' Closes the video device
   
   :return: none
   '''


