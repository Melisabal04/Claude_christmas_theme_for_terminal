#!/usr/bin/env bash
# Yılbaşı banner: the top strip the iotrocop plugin splits off in tmux, in place of iotrocop-banner.sh
# (picked through ~/.claude/iotrocop/banner, see install.sh). Same contract as that banner: $1 is the
# Claude Code pid to follow, $2 the token of ~/.claude/iotrocop/mood-<token> ("think" / "done").
# A tree with blinking lights, a star and gifts, Santa in his sleigh behind a galloping reindeer, snow blowing past.
# Everything in the scene is pixels, two to a cell with ▀ / ▄.
parent=${1:-}
token=${2:-}
dir="$HOME/.claude/iotrocop"
e=$'\033'
case $(locale charmap 2>/dev/null) in
  UTF-8|utf8) ;;
  *) LC_ALL=$(locale -a 2>/dev/null | grep -im1 -e '^C\.UTF-*8$' -e '^en_US\.UTF-*8$'); export LC_ALL=${LC_ALL:-en_US.UTF-8} ;;
esac
tall=9   # 7 rows of scene and a blank one above and below
rgb() { printf '%s' "$e[38;2;$1;$2;$3m"; }
gold=$(rgb 255 209 102); snow=$(rgb 248 244 227); pink=$(rgb 255 158 176)
dim=$(rgb 122 140 130); bold="$e[1m"; reset="$e[0m"
lights=('230;57;70' '255;209;102' '142;205;245' '255;158;176')   # red, gold, ice, pink
mood_file=${token:+$dir/mood-$token}

leave() { [ -n "$mood_file" ] && rm -f "$mood_file"; printf '%s' "$e[?25h$reset"; exit; }
trap leave INT TERM HUP
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }

countdown() {
  local y doy days
  y=$((10#$(date +%Y))); doy=$((10#$(date +%j)))
  days=365; (( (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 )) && days=366
  if (( doy == 1 )); then echo "Mutlu yıllar, $y!"
  elif (( $(date +%-m) == 12 && $(date +%-d) == 31 )); then echo 'Yeni yıla saatler kaldı!'
  else echo "Yeni yıla $(( days - doy + 1 )) gün"; fi
}

# the scene: one cell per column, ch[] the glyph, co[] its colour
put() {   # row col colour text, narrow glyphs only
  local r=$1 c=$2 col=$3 s=$4 i n=${#4}
  for (( i = 0; i < n; i++ )); do
    (( c + i >= 0 && c + i < w )) || continue
    ch[r * w + c + i]=${s:i:1}; co[r * w + c + i]=$col
  done
}
emoji() {  # row col glyph: a wide glyph takes two cells, the second left empty
  local i=$(( $1 * w + $2 ))
  (( $2 >= 0 && $2 + 1 < w )) || return
  ch[i]=$3; co[i]=''; ch[i + 1]=''
}
# pixel art: spr[] holds the rows of a picture, one letter per pixel ('.' is see-through);
# 1-4 are the tree's baubles, which change colour with the tick.
# Filled edges are painted as cell background, never as a block glyph: with any line spacing a
# glyph stops short of the cell's edge and leaves dark lines between the rows.
px() {
  case $1 in
    R) v='230;57;70' ;;   W) v='248;244;227' ;; G) v='42;157;92' ;;  B) v='150;100;55' ;;
    Y) v='255;209;102' ;; K) v='40;30;30' ;;    O) v='245;145;60' ;; S) v='255;205;170' ;;
    D) v='165;35;50' ;;   N) v='95;55;30' ;;
    [1-4]) v=${lights[(tick / 2 + $1) % 4]} ;;
    *) v='' ;;
  esac
}
sprite() {  # col top: draw spr[] with its first row at pixel row <top> of the 14 (7 cells, 2 each)
  local x=$1 y0=$2 r c p i a b n=${#spr[0]} m=${#spr[@]}
  for (( r = 0; r < 7; r++ )); do
    p=$(( 2 * r - y0 ))
    for (( c = 0; c < n; c++ )); do
      (( x + c >= 0 && x + c < w )) || continue
      a=''; b=''
      (( p >= 0 && p < m )) && a=${spr[p]:c:1}
      (( p + 1 >= 0 && p + 1 < m )) && b=${spr[p + 1]:c:1}
      px "$a"; a=$v; px "$b"; b=$v
      [[ -z $a$b ]] && continue
      i=$(( r * w + x + c ))
      # Every split cell is ▄ with the upper pixel as the cell background: the glyph sits low and
      # leaves a strip at the top of the cell, and that strip then shows the upper pixel's own
      # colour (or the terminal's, when the upper pixel is see-through) instead of a seam.
      # With the lower pixel see-through, reverse video paints ▄ in the terminal's background.
      if [[ -z $a ]]; then ch[i]='▄'; co[i]="$e[38;2;${b}m"
      elif [[ -z $b ]]; then ch[i]='▄'; co[i]="$e[7;38;2;${a}m"
      elif [[ $a == "$b" ]]; then ch[i]=' '; co[i]="$e[48;2;${a}m"
      else ch[i]='▄'; co[i]="$e[38;2;${b};48;2;${a}m"; fi
    done
  done
}

printf '%s' "$e[?25l"
tick=0; last=''; size=''; info=$(date +%H:%M); left=$(countdown)
while :; do
  if [[ -n $parent ]] && ! kill -0 "$parent" 2>/dev/null; then leave; fi
  if (( tick % 5 == 0 )) && [[ -f $dir/state && $(tr -d '[:space:]' < "$dir/state") == off ]]; then leave; fi
  if (( tick % 25 == 0 )); then info=$(date +%H:%M); left=$(countdown); fi

  mood=idle
  if [[ -n $mood_file && -f $mood_file ]]; then
    mood=$(tr -d '[:space:]' < "$mood_file")
    if [[ $mood == done ]] && (( $(date +%s) - $(mtime "$mood_file") > 4 )); then mood=idle; fi
  fi
  case $mood in
    think) dots=...; say="Elfler çalışıyor${dots:0:$(( tick % 4 ))}" ;;
    done)  say='Hediyen hazır! Ho ho ho!' ;;
    *)     case $(( tick / 50 % 3 )) in
             0) say='Ho ho ho! Ne yapıyoruz?' ;;
             1) say='Kar yağıyor, kod akıyor.' ;;
             2) say='Bu yıl uslu durdun mu?' ;;
           esac ;;
  esac

  read -r h w <<< "$(stty size 2>/dev/null)"; w=${w:-80}; h=${h:-5}
  if [[ "$w x $h" != "$size" ]]; then
    printf '%s' "$reset$e[2J$e[3J"; last=''; size="$w x $h"
    (( h != tall )) && [[ -n $TMUX_PANE ]] && tmux resize-pane -t "$TMUX_PANE" -y "$tall" 2>/dev/null
    # which columns snow, how fast and from where: fixed per size so the flakes fall, not flicker
    flake=(); phase=(); speed=()
    for (( c = 0; c < w; c++ )); do
      case $(( RANDOM % 9 )) in 0) flake[c]='*' ;; 1) flake[c]='·' ;; 2) flake[c]='˙' ;; 3) flake[c]='.' ;; *) flake[c]='' ;; esac
      phase[c]=$(( RANDOM % 14 )); speed[c]=$(( 1 + RANDOM % 3 ))
    done
  fi

  rows=()
  if (( w < 62 )); then
    rows=(" $gold★$reset $snow${bold}Mutlu Yıllar!$reset  $gold$say$reset")
  else
    ch=(); co=()
    for (( i = 0; i < 7 * w; i++ )); do ch[i]=' '; co[i]=''; done

    # snow: each snowy column drops a flake every 14 steps at its own pace, blown to the right
    # as if the sleigh were racing left through it
    for (( c = 0; c < w; c++ )); do
      [[ -n ${flake[c]} ]] || continue
      r=$(( (tick / speed[c] + phase[c]) % 14 ))
      (( r < 7 )) && { i=$(( r * w + (c + 2 * r) % w )); ch[i]=${flake[c]}; co[i]=$snow; }
    done

    # snowman, tree and gifts on the left; the greeting beside them; the sleigh on the right when it fits
    group=62; (( w >= 112 )) && group=112
    pad=$(( (w - group) / 2 ))
    # the snowman looks straight at us: green hat, carrot nose, red scarf, stick arms
    spr=(....GGGGG....
         ....GGGGG....
         ..GGGGGGGGG..
         ...WWWWWWW...
         ...WKWWWKW...
         ...WWWOWWW...
         ...WWWWWWW...
         ....RRRRR....
         B..RRRRRRR..B
         .BWWWWWWWWWB.
         ..WWWWKWWWW..
         ..WWWWWWWWW..
         ..WWWWKWWWW..
         ...WWWWWWW...
         )
    sprite $pad 0
    spr=(........GGG........ 
         .......G1GGG....... 
         ......GGGGGGG...... 
         .......G2GGG.......
         ......GGGGG3G...... 
         .....GGGGGGGGG..... 
         ....GGGGGGG4GGG.... 
         ....GGGGG3GGGGG....
         ........BBB........ 
         ........BBB........)
    sprite $(( pad + 14 )) 4
    # the star on top and the gifts at its foot are real emoji
    emoji 1 $(( pad + 23 )) '⭐'
    emoji 6 $(( pad + 15 )) '🎁'
    emoji 6 $(( pad + 29 )) '🎁'

    tx=$(( pad + 35 ))
    put 2 $tx "$bold$snow" 'MUTLU YILLAR'
    put 2 $(( tx + 13 )) "$gold" '✦'
    room=$(( w - tx - 1 ))
    if (( group > 62 )); then
      # Santa in his sleigh with a gift on the back, pulled by the reindeer on a rope; the whole team
      # holds still on the bottom edge while speed lines stream off the back
      sx=$(( pad + 64 )); room=$(( sx - tx - 2 ))
      spr=(..B.B.B..............RRRR.............
           ..BBBBB.............RRRRRR............
           ....B..............WWWWWWRW....Y.Y....
           ..BBBS.............SKSSWW.....RRYRR...
           RBKBBB............WWWSWWR.....YYYYY...
           .SBBBB............WWWWWRRR....RRYRR...
           ...RRR......WW....NNWWRRRRR..YYYYYYYY.
           ...BBBBBBBBBWNNNNNNNYYYYYYYYYDDDDDDY..
           ...BBBBBBBBBB......DRRRRRRRRRRRRRRRY..
           ...BBBBBBBBBB......DRRRRRRRRRRRRRRD...
           ...BB......BB.......DDDDDDDDDDDDDD....
           ...B.B....B.B..YY.....Y.........Y.....
           ...B.B....B.B..Y......Y.........Y.....
           ...B.B....B.B...YYYYYYYYYYYYYYYYYYYYY.)
      sprite $sx 0
      for (( k = 0; k < 3; k++ )); do
        o=$(( (tick + k) % 3 ))
        put $(( 3 + k )) $(( sx + 39 - k + o )) "$gold" '━━'
        put $(( 3 + k )) $(( sx + 41 - k + o )) "$dim" '─'
      done
    fi
    fit=$say; (( ${#say} > room )) && fit="${say:0:$(( room - 1 ))}…"
    put 3 $tx "$pink" "$fit"
    put 4 $tx "$dim" "$left · $info"

    for (( r = 0; r < 7; r++ )); do
      row=''; cur=x
      for (( c = 0; c < w; c++ )); do
        g=${ch[r * w + c]}; [[ -z $g ]] && continue
        if [[ ${co[r * w + c]} != "$cur" ]]; then cur=${co[r * w + c]}; row+="$reset$cur"; fi
        row+=$g
      done
      rows+=("$row$reset")
    done
    (( h < 7 )) && rows=("${rows[@]:0:6}")
    (( h < 6 )) && rows=("${rows[@]:1}")
    (( h < 5 )) && rows=("${rows[@]:0:4}")
    (( h < 4 )) && rows=("${rows[@]:1:3}")
  fi
  for (( r = (h - ${#rows[@]}) / 2; r > 0; r-- )); do rows=('' "${rows[@]}"); done

  out=''
  for row in "${rows[@]}"; do out+="${out:+$'\n'}$row$e[K"; done
  if [[ $out != "$last" ]]; then printf '%s' "$e[?2026h$e[H$out$e[J$e[?2026l"; last=$out; fi
  tick=$(( tick + 1 )); sleep 0.2
done
