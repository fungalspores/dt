#!/usr/bin/env bash
set -euo pipefail

# Проект для сборки своих geoip/geosite .dat с нужными тегами.
# Запуск: ./build_refilter_dat.sh
# Требования: git, go, curl/wget.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIRD_PARTY_DIR="${PROJECT_DIR}/third_party"
INPUT_DIR="${PROJECT_DIR}/input"
OUTPUT_DIR="${PROJECT_DIR}/output"

mkdir -p "${THIRD_PARTY_DIR}" "${INPUT_DIR}" "${OUTPUT_DIR}"

clone_repo() {
  local url="$1"; shift
  local dir="$1"; shift

  if [[ -d "${dir}/.git" ]]; then
    echo "🔄 Репозиторий уже существует, обновляю: ${dir}"
    git -C "${dir}" pull --ff-only || true
  else
    echo "⬇️ Клонирую ${url} в ${dir}"
    git clone --depth=1 "${url}" "${dir}"
  fi
}

# 1. Клонируем/обновляем geoip (CLI для работы с geoip.dat)
GEOIP_REPO_DIR="${THIRD_PARTY_DIR}/geoip"
clone_repo "https://github.com/v2fly/geoip.git" "${GEOIP_REPO_DIR}"

# 2. Скачиваем исходный geoip.dat с тегом geoip:refilter
#    (по умолчанию — из Re-filter-lists releases; при желании можно
#    поменять URL на свой в файле input/geoip_source_url.txt)
GEOIP_SOURCE_URL_FILE="${INPUT_DIR}/geoip_source_url.txt"
if [[ ! -f "${GEOIP_SOURCE_URL_FILE}" ]]; then
  cat >"${GEOIP_SOURCE_URL_FILE}" <<'EOF'
https://github.com/1andrevich/Re-filter-lists/releases/latest/download/geoip.dat
EOF
fi

GEOIP_SOURCE_URL="$(head -n1 "${GEOIP_SOURCE_URL_FILE}")"
GEOIP_SOURCE_PATH="${INPUT_DIR}/geoip_refilter_source.dat"

echo "⬇️ Скачиваю исходный geoip.dat из ${GEOIP_SOURCE_URL}" 
if command -v curl >/dev/null 2>&1; then
  curl -L -o "${GEOIP_SOURCE_PATH}" "${GEOIP_SOURCE_URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "${GEOIP_SOURCE_PATH}" "${GEOIP_SOURCE_URL}"
else
  echo "❌ Нужен curl или wget для скачивания файлов" >&2
  exit 1
fi

# 3. Готовим конфиг для geoip CLI, который оставит только geoip:refilter
GEOIP_CONFIG="${PROJECT_DIR}/geoip_config_refilter.json"
cat >"${GEOIP_CONFIG}" <<EOF
{
  "input": [
    {
      "type": "v2rayGeoIPDat",
      "action": "add",
      "args": {
        "uri": "${GEOIP_SOURCE_PATH}",
        "wantedList": ["refilter"]
      }
    }
  ],
  "output": [
    {
      "type": "v2rayGeoIPDat",
      "action": "output",
      "args": {
        "outputDir": "${OUTPUT_DIR}",
        "outputName": "geoip-refilter-only.dat",
        "wantedList": ["refilter"]
      }
    }
  ]
}
EOF

# 4. Собираем geoip.dat с geoip:refilter
echo "⚙️ Собираю geoip-refilter-only.dat с помощью v2fly/geoip"
(
  cd "${GEOIP_REPO_DIR}"
  go run ./ -c "${GEOIP_CONFIG}"
)

echo "✅ Готово: ${OUTPUT_DIR}/geoip-refilter-only.dat (только geoip:refilter)"

echo
echo "ℹ️ Часть с geosite (geosite:refilter, ru-available-only-inside, category-ads-all)"
echo "   зависит от генератора доменных списков (domain-list-community / russia-blocked-geosite)"
echo "   и требует отдельной конфигурации. Каркас можно добавить дополнительно." 

echo
echo "🎉 Скрипт завершён. Файлы лежат в ${OUTPUT_DIR}. Можешь класть их в git."
