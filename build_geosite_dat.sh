#!/usr/bin/env bash
set -euo pipefail

# Скрипт для сборки собственного geosite.dat только с нужными списками:
#   - geosite:refilter
#   - geosite:ru-available-only-inside
#
# Запуск из корня проекта или из самой папки:
#   ./refilter_dat_project/build_geosite_dat.sh
# или
#   cd refilter_dat_project && ./build_geosite_dat.sh

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${PROJECT_DIR}/input"
OUTPUT_DIR="${PROJECT_DIR}/output"

mkdir -p "${INPUT_DIR}" "${OUTPUT_DIR}"

# 1. URL исходного geosite.dat. По умолчанию берём из russia-blocked-geosite,
#    где уже есть нужные списки (refilter, ru-available-only-inside и др.).
#    При желании можно поменять URL в файле ниже.
GEOSITE_SOURCE_URL_FILE="${INPUT_DIR}/geosite_source_url.txt"
if [[ ! -f "${GEOSITE_SOURCE_URL_FILE}" ]]; then
  cat >"${GEOSITE_SOURCE_URL_FILE}" <<'EOF'
https://raw.githubusercontent.com/runetfreedom/russia-blocked-geosite/release/geosite.dat
EOF
fi

GEOSITE_SOURCE_URL="$(head -n1 "${GEOSITE_SOURCE_URL_FILE}")"
GEOSITE_SOURCE_PATH="${INPUT_DIR}/geosite_source.dat"

echo "⬇️ Скачиваю исходный geosite.dat из ${GEOSITE_SOURCE_URL}"
if command -v curl >/dev/null 2>&1; then
  curl -L -o "${GEOSITE_SOURCE_PATH}" "${GEOSITE_SOURCE_URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "${GEOSITE_SOURCE_PATH}" "${GEOSITE_SOURCE_URL}"
else
  echo "❌ Нужен curl или wget для скачивания файлов" >&2
  exit 1
fi

# 2. Запускаем Go‑утилиту, которая вырежет только нужные списки
FILTERED_OUTPUT_PATH="${OUTPUT_DIR}/geosite-refilter-ruinside-ads.dat"

echo "⚙️ Фильтрую geosite.dat (оставляю refilter, ru-available-only-inside)"
(
  cd "${PROJECT_DIR}"
  go run ./cmd/filter_geosite \
    -in "${GEOSITE_SOURCE_PATH}" \
    -out "${FILTERED_OUTPUT_PATH}" \
    -lists "refilter,ru-available-only-inside"
)

echo "✅ Готово: ${FILTERED_OUTPUT_PATH} (только нужные списки geosite:*)"

echo
echo "🎉 Скрипт завершён. Файлы лежат в ${OUTPUT_DIR}. Можешь класть их в git."
