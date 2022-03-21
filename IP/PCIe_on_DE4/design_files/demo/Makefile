#
TARGET = demo reprogram

#
CFLAGS = -g -Wall
LDFLAGS = -g -Wall

build: $(TARGET)

demo: demo.o alt_up_pci_lib.o
	$(CC) $(LDFLAGS) $^ -o $@

reprogram: reprogram.c alt_up_pci_lib.o
	cc reprogram.c alt_up_pci_lib.o -o $@

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) *.a *.o *~
