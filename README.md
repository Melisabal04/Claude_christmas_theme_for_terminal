# Claude_theme

Claude Code terminali için özel temalar.

> 🍎 **Şimdilik yalnızca macOS için.** Windows desteği yakında bir güncellemeyle gelecek.

## 🎄 Yılbaşı (`themes/yilbasi.json`)

Koyu çam yeşili zemin üzerinde kırmızı, altın sarısı ve kar beyazı.

| Öğe | Renk |
|---|---|
| Claude / vurgu | `#e63946` kırmızı |
| Prompt çerçevesi | `#2a9d5c` çam yeşili |
| Öneri / izin / bash | `#ffd166` altın |
| Metin | `#f8f4e3` kar beyazı |
| Plan modu | `#8ecdf5` buz mavisi |

### Üst bant 🎅🦌❄️

`banner/yilbasi-banner.sh`, iotrocop eklentisinin tmux bandında robotun yerine çizilir:
tepesinde ⭐ ve dibinde 🎁 hediyeleriyle ışıkları yanıp sönen çam ağacı, kardan adam, kızağında
dörtnala uçan Noel Baba ile geyiği (yıldız ve hediyeler dışında hepsi piksellerle çizili), rüzgârda savrulan kar, "MUTLU YILLAR" ve yeni yıla geri sayım. Claude çalışırken
"Elfler çalışıyor…", bitince "Hediyen hazır!" yazar.

Claude düşünürken dönen yazılar da (`words.json`) yılbaşı oluyor: "Noel Baba geliyor",
"Kurabiye pişiriyor", "Hediye paketliyor"…; bitince "Kurabiyeler pişti", "Ho ho ho".

### Kurulum

```sh
./install.sh          # tema + bant
./install.sh kaldir   # bandı Iotrocop robotuna geri döndür
```

Ardından yeni bir terminal açıp `claude` yaz ve `/theme` ile **Yılbaşı** temasını seç.
Bant, iotrocop eklentisinin `~/.claude/iotrocop/banner` dosyasında yazan betiği kullanmasıyla çalışır.
