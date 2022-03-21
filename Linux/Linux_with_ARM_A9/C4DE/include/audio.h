#ifndef audio_H
#define audio_H

#define MAX_VOLUME 0x7FFFFFFF		// maximum audio sample value
#define MAX_SAMPLING_RATE 48000		// maximum audio sampling rate
#define MID_SAMPLING_RATE 32000		// medium audio sampling rate
#define MIN_SAMPLING_RATE 8000		// minimum audio sampling rate

/**
 * Function audio_open: opens the digital audio device
 * Return: 1 on success, else 0
 */
int audio_open (void);

/**
 * Function audio_read: reads data from the audio device
 * Parameter ldata: pointer for returning the left-channel data
 * Parameter rdata: pointer for returning the right-channel data
 * Return: 1 on success, else 0
 */
int audio_read (int * /*ldata*/, int * /*rdata*/);

/**
 * Function audio_init: initializes the digital audio device
 * Return: void
 */
void audio_init (void);

/**
 * Function audio_rate: sets the sampling rate of the digital audio device
 * Parameter data: the sampling rate in samples/sec (8000, 32000, or 48000)
 * Return: void
 */
void audio_rate(int /*data*/);

/**
 * Function audio_wait_write: waits for space to be available for writing
 * Return: void
 */
void audio_wait_write (void);

/**
 * Function audio_wait_read: waits until data is available for reading
 * Return: void
 */
void audio_wait_read (void);

/**
 * Function audio_write_left: writes data to the left channel
 * Parameter data: left-channel data
 * Return: void
 */
void audio_write_left (int /*data*/);

/**
 * Function audio_write_right: writes data to the right channel
 * Parameter data: right-channel data
 * Return: void
 */
void audio_write_right (int /*data*/);

/**
 * Function audio_close: closes the digital audio device
 * Return: void
 */
void audio_close (void);

#endif
