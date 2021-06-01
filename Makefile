prefix=$(HOME)
bindir=$(prefix)/bin

INSTALL = install
LN = ln

BINS = \
       git-dot \
       git-synth \
       git-ptt

all: $(BINS)

install: all
	$(INSTALL) -m 755 git-dot $(bindir)/git-dot
	$(INSTALL) -m 755 git-synth $(bindir)/git-synth
	$(INSTALL) -m 755 git-ptt $(bindir)/git-ptt
	$(INSTALL) -m 755 git-mark $(bindir)/git-mark
	$(LN) -s git-mark $(bindir)/unmark
