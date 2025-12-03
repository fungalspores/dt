#!/usr/bin/env bash
set -euo pipefail

# Универсальный скрипт для сборки обоих файлов:
#   - geoip-refilter-only.dat (только geoip:refilter)
#   - geosite-refilter-ruinside-ads.dat (geosite:refilter,
#       geosite:ru-available-only-inside, geosite:category-ads-all)
#
# Запуск один раз:
#   ./build_all_refilter_dat.sh
#
# Запуск в режиме бесконечного цикла раз в 6 часов:
#   ./build_all_refilter_dat.sh --loop

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/output"

run_once() {
  echo "======================"
  echo "⏱  Запуск сборки refilter .dat файлов: $(date)"
  echo "======================"

  (
    cd "${PROJECT_DIR}"
    ./build_refilter_dat.sh
    ./build_geosite_dat.sh
  )

  echo
  echo "📂 Готовые файлы лежат в ${OUTPUT_DIR}:"
  echo "  - geoip-refilter-only.dat"
  echo "  - geosite-refilter-ruinside-ads.dat"
}

if [[ "${1-}" == "--loop" ]]; then
  # Бесконечный цикл с паузой 6 часов (21600 секунд)
  while true; do
    run_once
    echo
    echo "💤 Ожидание 6 часов до следующей пересборки..."
    sleep 21600
  done
else
  run_once
fi
