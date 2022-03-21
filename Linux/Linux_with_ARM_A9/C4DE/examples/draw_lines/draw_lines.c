#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <intelfpgaup/KEY.h>
#include <intelfpgaup/video.h>

int screen_x, screen_y;
int char_x, char_y;

void gen_line (int *, int *, int *, int *, unsigned *);
void print_text (int, int, int, int, unsigned);

volatile sig_atomic_t stop;
void catchSIGINT(int signum){
    stop = 1;
}

/* This program draws randomly-generated lines on the VGA display. The code uses
 * the character device drivers IntelFPGAUP/video and IntelFPGAUP/KEY. It draws a
 * random line each time a pushbutton KEY is pressed. The coordinates of each new 
 * line are displayed on the bottom right of the screen. Exit by typing ^C. */
int main(int argc, char *argv[]) {
	int KEY_data;
	int x1, y1, x2, y2;
	unsigned color;
	char msg_buffer[80];
	time_t t;	// used to seed the rand() function
    
  	// catch SIGINT from ^C, instead of having it abruptly close this program
  	signal(SIGINT, catchSIGINT);
    
	srand ((unsigned) time(&t));	// seed the rand function
	// Open the character device drivers
	if (!KEY_open ( ) || !video_open ( ))
		return -1;
	
	video_read (&screen_x, &screen_y, &char_x, &char_y);  // get screen & text size
	video_erase ( );  // erase any text on the screen

	// set random initial line coordinates
	gen_line (&x1, &y1, &x2, &y2, &color);

	/* There are two VGA buffers. The one we are drawing on is called the Back 
	 * buffer, and the one being displayed is called the Front buffer. The function 
	 * video_show swaps the two buffers, allowing us to display what has been drawn 
	 * on the Back buffer */
	video_clear ( );	// clear current VGA Back buffer
	video_show ( );		// swap Front/Back to display the cleared buffer
	video_clear ( );	// clear the VGA Back buffer, where we will draw lines
	video_line (x1, y1, x2, y2, color);
	video_show ( );		// swap Front/Back to display the line
  	while (!stop) {
		sprintf (msg_buffer, "(%03d,%03d) (%03d,%03d) color:%04X", x1, y1, x2, y2, color);
		video_text (char_x - strlen(msg_buffer), char_y - 1, msg_buffer);
		printf ("Press a pushbutton KEY (^C to exit)\n");
		KEY_read (&KEY_data);
		while (!KEY_data && !stop)
			KEY_read (&KEY_data);
		gen_line (&x1, &y1, &x2, &y2, &color);
		video_show ( );	// swap Front/Back
		video_line (x1, y1, x2, y2, color);
		video_show ( );	// swap Front/Back to display lines 
	}
	video_close ( );
	KEY_close ( );
	printf ("\nExiting sample program\n");
	return 0;
}

/* Generate a new random line */
void gen_line (int *x1, int *y1, int *x2, int *y2, unsigned *color) {
	unsigned int video_color[] = {video_WHITE, video_YELLOW, video_RED, 
		video_GREEN, video_BLUE, video_CYAN, video_MAGENTA, video_GREY, 
		video_PINK, video_ORANGE};
	*x1 = rand()%(screen_x - 1);		// random x position
	*y1 = rand()%(screen_y - 1);		// random y position
	*x2 = rand()%(screen_x - 1);		// random x position
	*y2 = rand()%(screen_y - 1);		// random y position
	*color = video_color[(rand()%10)];	// random out of 10 video colors
}

