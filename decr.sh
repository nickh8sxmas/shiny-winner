#!/bin/bash

# Decryptor
version='1.0'
vault='https://www.griin.space/vault'
a='a16fac06b8331ff6c5891453a2b942e3a58b6cc54c18f7fdaca1d086a35d8251'
b='b57868fa9a46ba77e3e135a7fb73c49e'
keyvault="$vault/vault.kpx"
vault_aes="$vault/griin2.enc"
audpid=0

echo -en '\x1b[s'

has?() { hash $1 2>/dev/null; }
#cleanup() { (( audpid > 1 )) && kill $audpid 2>/dev/null; }
quit() { echo -e "\x1b[2J \x1b[0H <:) \x1b[?25h \x1b[u \x1b[m"; }
unwrap_present() { openssl enc -aes-256-cbc -nosalt -d -K $a -iv $b; }

trap "cleanup" INT
trap "quit" EXIT

grab_present() {
  if has? curl; then curl -s $1
  elif has? wget; then wget -q -O - $1
  else exit
  fi
}
echo -en "\x1b[?25l \x1b[2J \x1b[H"

if has? afplay; then
  [ -f /tmp/griin.enc ] || grab_present $vault_aes >/tmp/griin.enc
  openssl enc -aes-256-cbc -nosalt -d -in griin.enc -K $a -iv $b > /tmp/griin.dec
  afplay /tmp/griin.dec &
elif has? aplay; then
  grab_present $vault_aes | unwrap_present | aplay -Dplug:default -q -f S16_LE -r 8000 &
fi
audpid=$!

# Show secrets
python3 <(cat <<EOF
import sys
import time
fps = 25; time_per_frame = 1.0 / fps
buf = ''; frame = 0; next_frame = 0
begin = time.time()
try:
  for i, line in enumerate(sys.stdin):
    if i % 32 == 0:
      frame += 1
      sys.stdout.write(buf); buf = ''
      elapsed = time.time() - begin
      repose = (frame * time_per_frame) - elapsed
      if repose > 0.0:
        time.sleep(repose)
      next_frame = elapsed / time_per_frame
    if frame >= next_frame:
      buf += line
except KeyboardInterrupt:
  pass
EOF
) < <(grab_present $keyvault | unwrap_present | bunzip2 -q 2> /dev/null)
