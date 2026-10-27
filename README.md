# BongoCat (KDE Plasma 6 Plasmoid)

A Bongo Cat animation that speeds up with CPU usage and blinks while idle.

Requires **KDE Plasma 6** and KSystemStats/LibKSysGuard (`org.kde.ksysguard.sensors`). The cat reads `cpu/all/usage` from the native sensor backend; no commands or local-file QML access are needed.

## Install from a directory

```bash
kpackagetool6 --type Plasma/Applet --install .
# For an existing installation:
kpackagetool6 --type Plasma/Applet --upgrade .
```

You can also use **Add Widgets → Get New Widgets → Install Widget From Local File** with the `.plasmoid` created by `./pack.sh`.

## Test

```bash
plasmoidviewer -a org.kde.plasma.bongocat
```

The cat should react to changing CPU usage. Plasma 5 is not supported.

## Resource management

The widget keeps one fixed KSystemStats sensor subscription and one animation timer. It does not poll `/proc/stat` or spawn processes.
