CC = gcc
CFLAGS = -fPIC -Wall -O2 -I.
LDFLAGS = -shared
LIBS = -lcrypto   # Needed for file_integrity (OpenSSL)

PLUGINS = example_plugin.so system_info.so file_integrity.so network_scanner.so \
          credential_stub.so persistence_stub.so lateral_stub.so

all: $(PLUGINS)

%.so: %.c plugin.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f *.so
