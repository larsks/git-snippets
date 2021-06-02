prefix=$(HOME)
bindir=$(prefix)/bin

INSTALL = install
LN = ln

BINS = \
       git-dot \
       git-synth \
       git-ptt \
	   git-set-message \
	   git-mark

all: $(BINS)

git-mark: common.sh git-mark.in.sh
	cat $^ > $@
	chmod 755 $@

git-ptt: common.sh git-ptt.in.sh
	cat $^ > $@
	chmod 755 $@

git-set-message: common.sh git-set-message.in.sh
	cat $^ > $@
	chmod 755 $@

install: all
	$(INSTALL) -m 755 git-dot $(bindir)/
	$(INSTALL) -m 755 git-synth $(bindir)/
	$(INSTALL) -m 755 git-ptt $(bindir)/
	$(INSTALL) -m 755 git-set-message $(bindir)/
	$(INSTALL) -m 755 git-mark $(bindir)/
	$(LN) -sf git-mark $(bindir)/unmark
