INSTALL := C:/altera_pro/26.1
#INSTALL := C:/altera_lite/25.1std
#INSTALL := C:/intelFPGA_lite/24.1std

############################################
# makefile that changes all design example makefile installation locations

DEFAULT:
	find . -type f -name "Makefile" -exec sed -i 's#^INSTALL.*#INSTALL := $(INSTALL)#g' {} +
	find . -type f -name "Makefile" -exec unix2dos {} +

