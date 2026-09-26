CC      = musl-gcc
CFLAGS  = -Wall -Wextra -O2 -static -std=c17 -Iinclude
LDFLAGS =
STRIP   = strip

BIN     = cat echo
TARGETS = $(BIN:%=build/bin/%)

# Shared utility code
SHARED_SRC = src/shared/utils.c
SHARED_OBJ = build/obj/shared/utils.o

PREFIX ?= $(HOME)/.local/share/my-coreutils
BINDIR  = $(DESTDIR)$(PREFIX)/bin
BUILD_DIR = $(CURDIR)/build/bin

all: $(TARGETS)

build/bin/%: build/obj/%.o $(SHARED_OBJ)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

build/obj/shared/utils.o: src/shared/utils.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

build/obj/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

install: all
	mkdir -p $(BINDIR)
	cp -f $(TARGETS) $(BINDIR)/

install-strip: all
	@$(MAKE) install
	$(STRIP) $(addprefix $(BINDIR)/, $(BIN))

uninstall:
	rm -f $(addprefix $(BINDIR)/, $(BIN))

check: all
	@BIN_DIR=$(BUILD_DIR) sh tests/run_tests.sh

clean:
	rm -rf build/

.PHONY: all install uninstall clean install-strip check

