prefix=$(HOME)
bindir=$(prefix)/bin

INSTALL = install
LN = ln

BINS = \
       git-dot \
       git-mark \
       git-ptt \
       git-set-message \
       git-synth \
       git-pick \
       git-resume

GENERATED = \
			git-mark \
			git-ptt \
			git-set-message \
			git-pick

all: $(BINS)

git-pick: common.sh git-pick.in.sh
	cat $^ > $@
	chmod 755 $@

git-mark: common.sh git-mark.in.sh
	cat $^ > $@
	chmod 755 $@

git-ptt: common.sh git-ptt.in.sh
	cat $^ > $@
	chmod 755 $@

git-resume: common.sh git-resume.in.sh
	cat $^ > $@
	chmod 755 $@

git-set-message: common.sh git-set-message.in.sh
	cat $^ > $@
	chmod 755 $@

install: all
	$(INSTALL) -d -m 755 $(DESTDIR)$(bindir)
	$(INSTALL) -m 755 $(BINS) $(DESTDIR)$(bindir)/
	$(LN) -sf git-mark $(DESTDIR)$(bindir)/git-unmark

clean:
	rm -f $(GENERATED)
