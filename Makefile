# SPDX-FileCopyrightText: 2026 Franco Pellegrini
# SPDX-License-Identifier: GPL-2.0-or-later

ID      := org.frapell.batteryusage
VERSION := $(shell sed -n 's/.*"Version": "\(.*\)".*/\1/p' package/metadata.json)
DIST    := dist/$(ID)-$(VERSION).plasmoid
DOMAIN  := plasma_applet_$(ID)
SOURCES := $(shell find package -name '*.qml' -o -name '*.js' | sort)

.PHONY: install upgrade uninstall restart build test log view clean pot translations

install:
	kpackagetool6 -t Plasma/Applet -i package

upgrade:
	kpackagetool6 -t Plasma/Applet -u package

uninstall:
	kpackagetool6 -t Plasma/Applet -r $(ID)

# plasmashell caches compiled QML; restart it to pick up edits.
restart:
	systemctl --user restart plasma-plasmashell.service

build: test translations
	@mkdir -p dist
	rm -f $(DIST)
	cd package && zip -qr ../$(DIST) . -x '*.qmlc'
	@echo $(DIST)

test:
	node tests/format.test.js
	node tests/stats.test.js

log:
	journalctl --user -u plasma-plasmashell -f | grep --line-buffered -iE 'batteryusage|qml'

view:
	plasmawindowed $(ID)

# Translation template; needs gettext.
pot:
	xgettext --from-code=UTF-8 --language=JavaScript --add-comments=i18n \
		--keyword= --keyword=i18n:1 --keyword=i18nc:1c,2 \
		--keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
		--package-name=$(ID) --package-version=$(VERSION) \
		--output=po/$(DOMAIN).pot $(SOURCES)

# Compiles po/<lang>.po into the package, where Plasma looks for them.
translations:
	@for po in $(wildcard po/*.po); do \
		lang=$$(basename $$po .po); \
		mkdir -p package/contents/locale/$$lang/LC_MESSAGES; \
		msgfmt --check -o package/contents/locale/$$lang/LC_MESSAGES/$(DOMAIN).mo $$po || exit 1; \
	done

clean:
	rm -rf dist package/contents/locale
