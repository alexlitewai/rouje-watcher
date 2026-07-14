#!/bin/bash
# Surveillance stock Rouje — Robe GABIN, tailles 36 & 38.
# Version GitHub Actions : backup cloud du watcher launchd local (couvre les
# heures où le Mac est fermé). Push ntfy à chaque retour en stock.
# L'état "déjà notifié" est persisté dans state.txt (commité par le workflow).
set -euo pipefail

TOPIC="${NTFY_TOPIC:?secret NTFY_TOPIC manquant}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
STATE="state.txt"

# handle Shopify | nom lisible
PRODUCTS=(
  "gabin-robe-midi-portefeuille-pois-noir|Robe GABIN"
)

touch "$STATE"

for ENTRY in "${PRODUCTS[@]}"; do
  HANDLE="${ENTRY%%|*}"
  NAME="${ENTRY##*|}"
  URL="https://www.rouje.com/products/$HANDLE"

  JSON=$(curl -s --max-time 20 -A "$UA" "$URL.js" || true)

  # Pas d'alerte "cassé" depuis le cloud : le watcher local joue ce rôle.
  if ! echo "$JSON" | jq -e '.variants' >/dev/null 2>&1; then
    echo "$(date -u '+%F %T') $NAME: ERREUR lecture"
    continue
  fi

  AVAILABLE=$(echo "$JSON" | jq -r '.variants[] | select(.available==true) | select(.title|test("/ (36|38)$")) | .title' | sort)
  CUR=$(echo "$AVAILABLE" | paste -s -d';' -)
  PREV=$(grep "^$HANDLE=" "$STATE" 2>/dev/null | cut -d= -f2- || true)

  echo "$(date -u '+%F %T') $NAME: ${CUR:-rupture}"

  if [ -n "$CUR" ] && [ "$CUR" != "$PREV" ]; then
    SIZES=$(echo "$AVAILABLE" | sed 's|.*/ ||' | paste -s -d, -)
    curl -s \
      -H "Title: 🛍️ $NAME dispo ! (via GitHub)" \
      -H "Priority: max" \
      -H "Tags: rotating_light" \
      -H "Click: $URL" \
      -d "DISPONIBLE en $SIZES : $NAME. Commande vite: $URL" \
      "https://ntfy.sh/$TOPIC" >/dev/null
    echo ">>> push envoyé ($SIZES)"
  fi

  # Mise à jour de l'état (ligne remplacée, ou supprimée si retour en rupture)
  grep -v "^$HANDLE=" "$STATE" > "$STATE.tmp" || true
  [ -n "$CUR" ] && echo "$HANDLE=$CUR" >> "$STATE.tmp"
  mv "$STATE.tmp" "$STATE"
done
