#!/bin/bash
set -eu
cd "$(dirname "$0")"
if [[ ! -f database/1Cv8.1CD || ! -f tests.epf ]]; then
  echo 'Полностью распакуйте VoltMarket-1C.zip и запустите файл из распакованной папки.'
  exit 1
fi
client=""
for root in /Applications "$HOME/Applications"; do
  [[ -d "$root" ]] || continue
  for name in 1cv8ct 1cv8c 1cv8t 1cv8; do
    while IFS= read -r path; do
      if [[ -x "$path" ]]; then client="$path"; break; fi
    done < <(find "$root" -type f -name "$name" -path '*8.3*' 2>/dev/null | LC_ALL=C sort -r)
    [[ -z "$client" ]] || break
  done
  [[ -z "$client" ]] || break
done
if [[ -z "$client" ]]; then
  echo 'Нужна установленная платформа 1С 8.3.27. Можно также открыть базу вручную по инструкции в архиве.'
  echo 'https://online.1c.ru/catalog/free/learning.php'
  exit 1
fi
exec "$client" ENTERPRISE /F "$PWD/database" /N 'Администратор' /Lru /Execute "$PWD/tests.epf"
