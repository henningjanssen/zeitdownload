#!/bin/sh

. ./.env

cookies="zeit_sso_201501=$ZEIT_SSO_201501; zeit_sso_piano_201501=$ZEIT_SSO_PIANO_201501; zeit_sso_session_201501=$ZEIT_SSO_SESSION_201501; dzcookie=$DZCOOKIE"

MAX_EDITIONS_PER_YEAR="${MAX_EDITIONS_PER_YEAR:-60}"

year="$LAST_YEAR"
edition=$([ "$FIRST_YEAR" -lt "$LAST_YEAR" ] && echo -n "1" || echo -n "$FIRST_EDITION")
editionsThisYear=0

# early editions provide "<uuid>.epub" while more current editions follow the naming "<year>_<edition>_DIE_ZEIT.epub"
uuidRegex="[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"

while true; do
  if [ "$year" -lt "$FIRST_YEAR" ]; then
    break
  fi

  if [ "${#edition}" -lt "2" ]; then
      edition="0${edition}"
  fi

  targetPath="./dl/ZEIT ONLINE GmbH/Die Zeit/Vol $edition - $year - Die Zeit Nr $edition $year"

  wget -P "$targetPath" --header="Cookie: $cookies" -r --random-wait --adjust-extension -nd -nH -nv -l 2 --compression=auto -R "index.html" -H -e robots=off --content-disposition --reject-regex="(/diezeit/$year/$edition\$)" --backups=0 -nc --accept-regex="((/download/[0-9]+\?appendPdfId=[0-9]+)|(.*.epub))$" "https://epaper.zeit.de/abo/diezeit/$year/$edition" 2>&1 >/dev/null
  rm -f "$targetPath"/*.html
  rmdir "$targetPath" > /dev/null 2>&1 || true

  existingFiles=$(ls -1 "$targetPath" 2>/dev/null | wc -l)

  if [ "$existingFiles" -ge "1" ]; then
    currentEpubName=$(ls -1 "$targetPath"/*.epub 2>/dev/null | tail -n 1)
    targetEpubName=$(echo "$currentEpubName" | sed -E "s/($uuidRegex)\.epub\$/${year}_${edition}_DIE_ZEIT.epub/g")

    if [ "${#currentEpubName}" -gt "${#targetPath}" ] && [ "${targetEpubName}" != "${currentEpubName}" ]; then
      mv "$currentEpubName" "$targetEpubName"
    fi
  fi
  
  if [ "$existingFiles" -eq "0" ] && [ "${edition#0}" -eq "1" ] && [ "$editionsThisYear" -eq "0" ]; then
    break
  fi

  if [ "${edition#0}" -eq "1" ] && [ "$year" -lt "$LAST_YEAR" ]; then
    echo "Downloaded $editionsThisYear for $((year+1))"
    editionsThisYear="0"
  fi

  if [ "$existingFiles" -gt "0" ]; then
    editionsThisYear=$((editionsThisYear+1))
  fi
  
  if [ "$year" -ge "$LAST_YEAR" ] && [ "${edition#0}" -ge "${LAST_EDITION#0}" ] || [ "$edition" -ge "$MAX_EDITIONS_PER_YEAR" ]; then
    year=$((year-1))

    if [ "$year" -le "$FIRST_YEAR" ]; then
      edition="${FIRST_EDITION#0}"
    else
      edition="1"
    fi

    continue
  fi

  edition=$(( ${edition#0} + 1))
done
