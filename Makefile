# There are only two rules:
# 1. Variables at the top of the Makefile.
# 2. Targets are listed alphabetically. No, really.

WHEREAMI = $(shell pwd)
WHOAMI = $(shell basename $(WHEREAMI))
WHATAMI = $(shell echo $(WHOAMI) | awk -F '-' '{print $$3}')
WHATAMI_REALLY = $(shell basename `pwd` | sed 's/whosonfirst-data-//')

YMD = $(shell date "+%Y%m%d")

UNAME_S := $(shell uname -s)

archive: meta-scrub
	tar --exclude='.git*' --exclude='Makefile*' -cvjf $(dest)/$(WHOAMI)-$(YMD).tar.bz2 ./data ./meta ./LICENSE.md ./CONTRIBUTING.md ./README.md

bin:
	mkdir -p bin
ifeq ($(UNAME_S),Darwin)
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/darwin/wof-build-metafiles
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/darwin/wof-build-metafiles.sha256
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/darwin/wof-build-concordances
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/darwin/wof-build-concordances.sha256
	make bin-verify
else ifeq ($(UNAME_S),Linux)
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/linux/wof-build-metafiles
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/linux/wof-build-metafiles.sha256
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/linux/wof-build-concordances
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/linux/wof-build-concordances.sha256
	make bin-verify
else ifeq ($(UNAME_S),Windows)
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/windows/wof-build-metafiles
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-meta/master/dist/windows/wof-build-metafiles.sha256
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/windows/wof-build-concordances
	cd bin && curl -s -O https://raw.githubusercontent.com/whosonfirst/go-whosonfirst-concordances/master/dist/windows/wof-build-concordances.sha256
	@echo "Skipping the SHA-256 verification, because Windows"
else
	echo "this OS is not supported yet"
	exit 1
endif

bin-verify:
	cd bin && shasum -a 256 -c wof-build-metafiles.sha256
	cd bin && shasum -a 256 -c wof-build-concordances.sha256
	chmod +x bin/wof-build-metafiles
	chmod +x bin/wof-build-concordances
	rm bin/wof-build-metafiles.sha256
	rm bin/wof-build-concordances.sha256

count:
	find ./data -name '*.geojson' -print | wc -l

docs:
	curl -s -o LICENSE.md https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/docs/LICENSE-SHORT.md
	curl -s -o CONTRIBUTING.md https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/docs/CONTRIBUTING.md

githash:
	git log --pretty=format:'%H' -n 1

gitignore:
	curl -s -o .gitignore https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/git/dot-gitignore
	curl -s -o meta/.gitignore https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/git/dot-gitignore-meta

gitlf:
	if ! test -f .gitattributes; then touch .gitattributes; fi
ifeq ($(shell grep '*.geojson text eol=lf' .gitattributes | wc -l), 0)
	cp .gitattributes .gitattributes.tmp
	perl -pe 'chomp if eof' .gitattributes.tmp
	echo "*.geojson text eol=lf" >> .gitattributes.tmp
	mv .gitattributes.tmp .gitattributes
else
	@echo "Git linefeed hoohah already set"
endif

gitlfs-track-meta:
	git-lfs track meta/*-latest.csv

# https://internetarchive.readthedocs.org/en/latest/cli.html#upload
# https://internetarchive.readthedocs.org/en/latest/quickstart.html#configuring

ia:
	ia upload $(WHOAMI)-$(YMD) $(src)/$(WHOAMI)-$(YMD).tar.bz2 --metadata="title:$(WHOAMI)-$(YMD)" --metadata="licenseurl:http://creativecommons.org/licenses/by/4.0/" --metadata="date:$(YMD)" --metadata="subject:geo;mapzen;whosonfirst" --metadata="creator:Who's On First (Mapzen)"

internetarchive:
	$(MAKE) dest=$(src) archive
	$(MAKE) src=$(src) ia
	rm $(src)/$(WHOAMI)-$(YMD).tar.bz2

list-empty:
	find data -type d -empty -print

prune:
	git gc --aggressive --prune

rm-empty:
	find data -type d -empty -print -delete

update-makefile:
	curl -s -o Makefile https://raw.githubusercontent.com/whosonfirst/whosonfirst-data-utils/master/make/Makefile
ifeq ($(shell echo $(WHATAMI) | wc -l), 1)
	if test -f $(WHEREAMI)/Makefile.$(WHATAMI);then  echo "\n# appending Makefile.$(WHATAMI)\n\n" >> Makefile; cat $(WHEREAMI)/Makefile.$(WHATAMI) >> Makefile; fi
	if test -f $(WHEREAMI)/Makefile.$(WHATAMI).local;then  echo "\n# appending Makefile.$(WHATAMI).local\n\n" >> Makefile; cat $(WHEREAMI)/Makefile.$(WHATAMI).local >> Makefile; fi
endif
	if test -f $(WHEREAMI)/Makefile.local; then echo "\n# appending Makefile.local\n\n" >> Makefile; cat $(WHEREAMI)/Makefile.local >> Makefile; fi
