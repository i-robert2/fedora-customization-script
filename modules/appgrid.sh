# shellcheck shell=bash
mod_appgrid() {
    echo "[appgrid] Organizing app grid into category folders..."

    FOLDER_SCHEMA="org.gnome.desktop.app-folders"
    FOLDER_CHILD="org.gnome.desktop.app-folders.folder"
    FOLDER_PATH="/org/gnome/desktop/app-folders/folders"

    # Enable app folders
    # Order matters: an app goes into the first folder that matches.
    # Explicit 'apps' entries always win over 'categories' matching.
    gsettings set "$FOLDER_SCHEMA" folder-children \
        "['Dev', 'Office', 'Media', 'System', 'Accessories']"

    # ── Dev ────────────────────────────────────────────────────────────
    # Explicit list only — terminals and dev tools have System category,
    # so we pin them here before the System folder can grab them.
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Dev/" name 'Dev'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Dev/" apps \
        "['com.visualstudio.code.desktop', \
          'code.desktop', \
          'com.ghostty.ghostty.desktop', \
          'com.mitchellh.ghostty.desktop', \
          'ghostty.desktop', \
          'org.gnome.Terminal.desktop', \
          'htop.desktop', \
          'btop.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Dev/" categories \
        "['Development', 'IDE']"
    echo "  Dev folder created."

    # ── Office ─────────────────────────────────────────────────────────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Office/" name 'Office'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Office/" apps \
        "['org.libreoffice.LibreOffice.writer.desktop', \
          'org.libreoffice.LibreOffice.calc.desktop', \
          'org.libreoffice.LibreOffice.impress.desktop', \
          'libreoffice-writer.desktop', \
          'libreoffice-calc.desktop', \
          'libreoffice-impress.desktop', \
          'org.gnome.Contacts.desktop', \
          'org.gnome.Maps.desktop', \
          'org.gnome.Weather.desktop', \
          'org.gnome.Calendar.desktop', \
          'org.gnome.Clocks.desktop', \
          'org.gnome.clocks.desktop', \
          'org.gnome.Evince.desktop', \
          'evince.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Office/" categories \
        "['Office', 'Calendar', 'ContactManagement']"
    echo "  Office folder created."

    # ── Media ──────────────────────────────────────────────────────────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" name 'Media'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" apps \
        "['org.gnome.Totem.desktop', \
          'totem.desktop', \
          'org.gnome.Videos.desktop', \
          'org.gnome.Snapshot.desktop', \
          'org.gnome.Cheese.desktop', \
          'org.fedoraproject.MediaWriter.desktop', \
          'org.gnome.Characters.desktop', \
          'org.gnome.Music.desktop', \
          'org.gnome.Rhythmbox3.desktop', \
          'rhythmbox.desktop', \
          'org.gnome.Loupe.desktop', \
          'org.gnome.eog.desktop', \
          'eog.desktop', \
          'simple-scan.desktop', \
          'org.gnome.SimpleScan.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" categories \
        "['Audio', 'Video', 'AudioVideo', 'Graphics', 'Photography', 'Scanning']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" excluded-apps \
        "['org.gnome.Font-viewer.desktop', \
          'org.gnome.font-viewer.desktop']"
    echo "  Media folder created."

    # ── System ─────────────────────────────────────────────────────────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" name 'System'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" apps \
        "['org.gnome.Settings.desktop', \
          'gnome-system-monitor.desktop', \
          'org.gnome.SystemMonitor.desktop', \
          'org.gnome.DiskUtility.desktop', \
          'org.gnome.Boxes.desktop', \
          'org.gnome.Connections.desktop', \
          'org.gnome.Logs.desktop', \
          'org.gnome.Tour.desktop', \
          'yelp.desktop', \
          'org.gnome.Yelp.desktop', \
          'org.gnome.tweaks.desktop', \
          'com.mattjakeman.ExtensionManager.desktop', \
          'org.gnome.baobab.desktop', \
          'org.freedesktop.MalcontentControl.desktop', \
          'malcontent-control.desktop', \
          'gnome-abrt.desktop', \
          'abrt-applet.desktop', \
          'org.gnome.Font-viewer.desktop', \
          'org.gnome.font-viewer.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" categories \
        "['System', 'Security', 'Monitor', 'Settings', 'HardwareSettings', \
          'PackageManager', 'Network', 'Documentation', 'TerminalEmulator']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" excluded-apps \
        "['com.visualstudio.code.desktop', \
          'code.desktop', \
          'com.ghostty.ghostty.desktop', \
          'com.mitchellh.ghostty.desktop', \
          'ghostty.desktop', \
          'org.gnome.Terminal.desktop', \
          'htop.desktop', \
          'btop.desktop', \
          'org.gnome.Nautilus.desktop']"
    echo "  System folder created."

    # ── Accessories (catch-all — broad Utility category goes last) ────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Accessories/" name 'Accessories'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Accessories/" apps \
        "['org.gnome.TextEditor.desktop', \
          'org.gnome.Calculator.desktop', \
          'org.gnome.FileRoller.desktop', \
          'org.gnome.Nautilus.desktop', \
          'rofi.desktop', \
          'rofi-theme-selector.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Accessories/" categories \
        "['Utility', 'TextEditor', 'Archiving', 'Calculator', 'Compression', \
          'FileManager', 'FileTools', 'Core', 'Clock', 'GNOME']"
    echo "  Accessories folder created."

    # Reset the cached grid layout so GNOME rebuilds it from the new folders.
    # Without this, the old two-page layout persists even after folder changes.
    gsettings reset org.gnome.shell app-picker-layout

    echo "  App grid organized into folders (layout reset — may need Alt+F2 → r or re-login)."
}