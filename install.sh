#!/bin/sh
# Yılbaşı: ./install.sh kurar, ./install.sh kaldir eski haline döndürür.
# The colours go to ~/.claude/themes; the banner is picked by the iotrocop plugin through ~/.claude/iotrocop/banner.
here=$(cd "$(dirname "$0")" && pwd)
dir="$HOME/.claude/iotrocop"
case ${1:-kur} in
  kur)
    mkdir -p "$HOME/.claude/themes" "$dir"
    cp "$here/themes/yilbasi.json" "$HOME/.claude/themes/yilbasi.json"
    chmod +x "$here/banner/yilbasi-banner.sh"
    printf '%s\n' "$here/banner/yilbasi-banner.sh" > "$dir/banner"
    cp "$here/words.json" "$dir/words.json"
    echo "Kuruldu. Yeni bir terminalde claude aç, /theme ile Yılbaşı'nı seç." ;;
  kaldir)
    rm -f "$dir/banner" "$dir/words.json"
    echo "Yılbaşı bandı kaldırıldı, Iotrocop robotu geri geldi. (Renkler için /theme)" ;;
  *) echo "kullanım: $0 [kur|kaldir]"; exit 1 ;;
esac
