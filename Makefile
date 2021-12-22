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
       git-pick-ref \
       git-pick-commit \
       git-resume

GENERATED = \
			git-mark \
			git-ptt \
			git-set-message \
			git-pick-ref \
			git-pick-commit

all: $(BINS)

git-pick-ref: common.sh git-pick-ref.in.sh
	cat $^ > $@
	chmod 755 $@

git-pick-commit: common.sh git-pick-commit.in.sh
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
