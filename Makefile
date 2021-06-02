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
	$(INSTALL) -m 755 git-dot $(bindir)/
	$(INSTALL) -m 755 git-synth $(bindir)/
	$(INSTALL) -m 755 git-ptt $(bindir)/
	$(INSTALL) -m 755 git-set-message $(bindir)/
	$(INSTALL) -m 755 git-mark $(bindir)/
	$(LN) -sf git-mark $(bindir)/unmark
