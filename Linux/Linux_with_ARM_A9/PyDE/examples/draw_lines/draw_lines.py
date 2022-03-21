''' This program draws randomly-generated lines on the VGA display 

The code uses the character device drivers IntelFPGAUP/video and IntelFPGAUP/KEY.
It draws a random line each time a pushbutton KEY is pressed. The coordinates of 
each new line are displayed on the bottom right of the screen. Exit by typing ^C
'''
import sys
import KEY
import video
import signal
import random
from random import randint

video_color = [video.WHITE, video.YELLOW, video.RED, video.GREEN, video.BLUE, 
   video.CYAN, video.MAGENTA, video.GREY, video.PINK, video.ORANGE]

stop = False

def signal_handler(signal, frame) :
   global stop
   stop = True

def gen_line ():
   ''' generate a random line with two (x,y) coordinates and a color
   
   return: the x,y coordinates and color
   '''
   x1 = randint(0,screen_x-1)
   y1 = randint(0, screen_y-1)
   x2 = randint(0,screen_x-1)
   y2 = randint(0, screen_y-1)
   color = random.choice(video_color)
   return x1, y1, x2, y2, color

signal.signal(signal.SIGINT, signal_handler)   # exit cleanly on ^C
if not KEY.open_dev() or not video.open_dev():
   sys.exit()

screen_x, screen_y, char_x, char_y = video.read()   # get VGA graphics and text size
video.erase()   # erase any text on the screen

# generate a random line
x1, y1, x2, y2, color = gen_line()

# There are two VGA buffers. The one we are drawing on is called the Back buffer;
# the one being displayed is called the Front buffer. The function video_show swaps
# the two buffers, allowing us to display what has been drawn on the Back buffer
video.clear()   # clear current VGA Back buffer
video.show()   # swap Front/Back to display the cleared buffer
video.clear()   # clear the current VGA Back buffer, where we will draw lines
video.line(x1, y1, x2, y2, color)
video.show()   # swap Front/Back to display the line

while not(stop) :
   msg = "(%03d,%03d) (%03d,%03d) color:%04X" % (x1, y1, x2, y2, color)
   video.text(char_x - len(msg), char_y - 1, msg)
   print("Press a pushbutton KEY (^C to exit)\n")
   while (KEY.read() == 0) and not(stop) :
      pass   # wait
   x1, y1, x2, y2, color = gen_line()
   video.show()   # swap Front/Back
   video.line(x1, y1, x2, y2, color)
   video.show()   # swap Front/Back to display lines

KEY.close()
video.close()
print("Exiting sample program\n") 

