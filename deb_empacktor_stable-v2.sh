#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------
# Variables globales
# ----------------------------
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
APP_ICON="$SCRIPT_DIR/dppak-icon.png"  # PNG supporté par YAD

# ----------------------------
# ASCII et instructions
# ----------------------------
DEBASCII="<span foreground='blue' font='Monospace bold 12'>
┏━━━┓┏━━━┓┏━━┓━━━━━┏━━━┓━━━━━━━━━━━━━━━━━┏┓━━━┏┓━━━━━━━━
┗┓┏┓┃┃┏━━┛┃┏┓┃━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━┃┃━━┏┛┗┓━━━━━━━
━┃┃┃┃┃┗━━┓┃┗┛┗┓━━━━┃┗━━┓┏┓┏┓┏━━┓┏━━┓━┏━━┓┃┃┏┓┗┓┏┛┏━━┓┏━┓
━┃┃┃┃┃┏━━┛┃┏━┓┃━━━━┃┏━━┛┃┗┛┃┃┏┓┃┗━┓┃━┃┏━┛┃┗┛┛━┃┃━┃┏┓┃┃┏┛
┏┛┗┛┃┃┗━━┓┃┗━┛┃━━━━┃┗━━┓┃┃┃┃┃┗┛┃┃┗┛┗┓┃┗━┓┃┏┓┓━┃┗┓┃┗┛┃┃┃━
┗━━━┛┗━━━┛┗━━━┛━━━━┗━━━┛┗┻┻┛┃┏━┛┗━━━┛┗━━┛┗┛┗┛━┗━┛┗━━┛┗┛━
━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━
</span>"

# ----------------------------
# 1️⃣ Informations package
# ----------------------------
PACKAGE_INFO=$(yad --form \
    --title="DEB Empacktor - Informations du package" \
    --window-icon="$APP_ICON" \
    --width=500 --height=400 --center \
    --text="$DEBASCII\n💡 Saisissez les informations de votre package." \
    --field="Nom du package:TXT" "demo-app" \
    --field="Version:TXT" "1.0" \
    --field="Mainteneur:TXT" "Moi <moi@example.com>" \
    --field="Architecture:CB" "all!amd64!i386" \
    --field="Inclure README:CHK" FALSE \
    --field="Inclure LICENSE MIT:CHK" FALSE)

[[ -z "$PACKAGE_INFO" ]] && exit 0

PACKAGE=$(echo "$PACKAGE_INFO" | cut -d'|' -f1)
VERSION=$(echo "$PACKAGE_INFO" | cut -d'|' -f2)
MAINT=$(echo "$PACKAGE_INFO" | cut -d'|' -f3)
ARCH=$(echo "$PACKAGE_INFO" | cut -d'|' -f4)
INCL_README=$(echo "$PACKAGE_INFO" | cut -d'|' -f5)
INCL_LICENSE=$(echo "$PACKAGE_INFO" | cut -d'|' -f6)

# ----------------------------
# 2️⃣ Sélection du dossier README (facultatif)
# ----------------------------
SRC_DIR_README=""
if [[ "$INCL_README" == "TRUE" ]]; then
    SRC_DIR_README=$(yad --file --directory \
        --title="Sélectionnez le dossier source pour README (facultatif)" \
        --window-icon="$APP_ICON" --center)
fi

# ----------------------------
# 3️⃣ Sélection du dossier de destination
# ----------------------------
DEST_DIR=$(yad --file --directory \
    --title="Sélectionnez le dossier de destination" \
    --window-icon="$APP_ICON" --center)
[[ -z "$DEST_DIR" ]] && exit 0

# ----------------------------
# Création dossier final
# ----------------------------
DATE_NOW=$(date '+%d%m%Y%H%M')
FINAL_DIR="$DEST_DIR/${PACKAGE}-${VERSION}-deb-${DATE_NOW}"
mkdir -p "$FINAL_DIR/DEBIAN"
mkdir -p "$FINAL_DIR/opt/$PACKAGE"
mkdir -p "$FINAL_DIR/usr/bin"
mkdir -p "$FINAL_DIR/usr/share/applications"
mkdir -p "$FINAL_DIR/usr/share/pixmaps"
mkdir -p "$FINAL_DIR/usr/share/doc/$PACKAGE"

# ----------------------------
# 4️⃣ Sélection de plusieurs binaires
# ----------------------------
BIN_FILES=$(yad --file --multiple \
    --title="Choisissez les binaires de l'application" \
    --window-icon="$APP_ICON" --center)
[[ -z "$BIN_FILES" ]] && exit 0

IFS='|' read -r -a BIN_ARRAY <<< "$BIN_FILES"

for BIN_PATH in "${BIN_ARRAY[@]}"; do
    BIN_NAME_TMP=$(basename "$BIN_PATH")
    cp "$BIN_PATH" "$FINAL_DIR/opt/$PACKAGE/$BIN_NAME_TMP"
    chmod 755 "$FINAL_DIR/opt/$PACKAGE/$BIN_NAME_TMP"
    ln -s "/opt/$PACKAGE/$BIN_NAME_TMP" "$FINAL_DIR/usr/bin/$BIN_NAME_TMP"
done

BIN_NAME=$(basename "${BIN_ARRAY[0]}")

# ----------------------------
# 5️⃣ Sélection de l’icône
# ----------------------------
ICON_FILE=$(yad --file \
    --title="Choisissez une icône (.png ou .svg)" \
    --window-icon="$APP_ICON" --center)

ICON_NAME="application-default-icon"
if [[ -f "$ICON_FILE" ]]; then
    ICON_NAME=$(basename "$ICON_FILE" | sed 's/[^a-zA-Z0-9._-]/_/g')
    cp "$ICON_FILE" "$FINAL_DIR/usr/share/pixmaps/$ICON_NAME"
    chmod 644 "$FINAL_DIR/usr/share/pixmaps/$ICON_NAME"
fi

# ----------------------------
# 6️⃣ Choix de la catégorie
# ----------------------------
SECTION=$(yad --form \
    --title="Choisissez la catégorie de l'application" \
    --window-icon="$APP_ICON" \
    --width=450 --center \
    --text="Sélectionnez la catégorie principale pour votre application" \
    --field="Catégorie:CB" "Utility!Office!Development!Graphics!Network!Games!Multimedia!System!Education!Science")

[[ -z "$SECTION" ]] && exit 0

DESKTOP_CATEGORIES=$(echo "$SECTION" | tr '|' ';' | sed 's/;*$//')
DEBIAN_SECTION="utils"

# ----------------------------
# 7️⃣ Copie README et LICENSE
# ----------------------------
# README
if [[ "$INCL_README" == "TRUE" ]]; then
    if [[ -f "$SRC_DIR_README/README.md" ]]; then
        cp "$SRC_DIR_README/README.md" "$FINAL_DIR/usr/share/doc/$PACKAGE/"
    else
        echo "# README du package $PACKAGE" > "$FINAL_DIR/usr/share/doc/$PACKAGE/README.md"
        echo "Ceci est un README généré automatiquement." >> "$FINAL_DIR/usr/share/doc/$PACKAGE/README.md"
    fi
fi

# LICENSE MIT
if [[ "$INCL_LICENSE" == "TRUE" ]]; then
    cat > "$FINAL_DIR/usr/share/doc/$PACKAGE/LICENSE" <<EOL
MIT License

Copyright (c) [année] [Nom du titulaire du copyright]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOL
fi

# ----------------------------
# 8️⃣ Fichier .desktop
# ----------------------------
cat > "$FINAL_DIR/usr/share/applications/$PACKAGE.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$PACKAGE
Comment=Application $PACKAGE installée via Debian
Exec=/opt/$PACKAGE/$BIN_NAME
Icon=$ICON_NAME
Terminal=false
Categories=$DESKTOP_CATEGORIES;
EOF
chmod 644 "$FINAL_DIR/usr/share/applications/$PACKAGE.desktop"

# ----------------------------
# 9️⃣ Fichier DEBIAN/control
# ----------------------------
cat > "$FINAL_DIR/DEBIAN/control" <<EOF
Package: $PACKAGE
Version: $VERSION
Section: $DEBIAN_SECTION
Priority: optional
Architecture: $ARCH
Maintainer: $MAINT
Installed-Size: 1024
Depends: bash (>= 4.0)
Homepage: https://example.com/$PACKAGE
Description: $PACKAGE - Application 
EOF

# ----------------------------
# 🔟 Scripts postinst / postrm
# ----------------------------
cat > "$FINAL_DIR/DEBIAN/postinst" <<EOF
#!/bin/bash
set -e
echo "Installation de $PACKAGE terminée !"
exit 0
EOF
chmod 755 "$FINAL_DIR/DEBIAN/postinst"

cat > "$FINAL_DIR/DEBIAN/postrm" <<EOF
#!/bin/bash
set -e
echo "Suppression de $PACKAGE terminée !"
exit 0
EOF
chmod 755 "$FINAL_DIR/DEBIAN/postrm"

# ----------------------------
# 11️⃣ Fenêtre finale + build .deb
# ----------------------------
FINAL_TEXT="<b>Dossier préparatoire Debian créé :</b>\n$FINAL_DIR\n\nVoulez-vous créer maintenant le package .deb ?\n\n<b>Rappel terminal :</b> dpkg-deb --build \"$FINAL_DIR\""

if yad --question \
    --title="DEB prêt" \
    --window-icon="$APP_ICON" \
    --width=500 --height=200 \
    --text="$FINAL_TEXT" --center; then

    dpkg-deb --build "$FINAL_DIR"

    yad --info \
        --title="Package .deb créé" \
        --window-icon="$APP_ICON" \
        --text="Le package .deb a été généré avec succès dans :\n$FINAL_DIR.deb" \
        --center
fi
