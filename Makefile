PREFIX ?= /usr/local
BIN_DIR := bin
HBF_SRC := src/hbf.hc
HBF_BIN := $(BIN_DIR)/hbf
SRC_FILES := $(shell find src -name '*.hc')

.PHONY: all clean install uninstall

all: $(HBF_BIN)

$(HBF_BIN): $(SRC_FILES)
	@mkdir -p $(BIN_DIR)
	cd src && hcc ./hbf.hc
	mv src/a.out $(HBF_BIN)
	chmod +x $(HBF_BIN)

install: $(HBF_BIN)
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 $(HBF_BIN) $(DESTDIR)$(PREFIX)/bin/hbf

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/hbf

clean:
	rm -f $(HBF_BIN) src/a.out
