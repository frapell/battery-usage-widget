# Translations

Translations use the gettext domain `plasma_applet_org.frapell.batteryusage`.

1. `make pot` regenerates `plasma_applet_org.frapell.batteryusage.pot` from
   the sources (needs `gettext`).
2. Copy it to `<lang>.po` (for example `es.po`), or update an existing one
   with `msgmerge -U es.po plasma_applet_org.frapell.batteryusage.pot`, and
   translate.
3. `make build` compiles every `po/*.po` into
   `package/contents/locale/<lang>/LC_MESSAGES/` inside the `.plasmoid`.

Unit symbols (W, Wh) are not translated.
