# dt – refilter geoip/geosite builder

Небольшой проект для автоматической сборки двух `.dat` файлов:

- `output/geoip-refilter-only.dat` — только список `geoip:refilter` из исходного `geoip.dat`
- `output/geosite-refilter-ruinside-ads.dat` — только списки
  `geosite:refilter`, `geosite:ru-available-only-inside`,
  `geosite:category-ads-all` из исходного `geosite.dat`

## Локальный запуск

```bash
# один раз собрать оба файла
./build_all_refilter_dat.sh

# или по отдельности
./build_refilter_dat.sh
./build_geosite_dat.sh
```

## Автосборка и релизы на GitHub

В репозитории уже есть workflow
`.github/workflows/build-and-release.yml`, который:

- каждые 6 часов (cron: `0 */6 * * *`) запускает сборку
- создаёт/обновляет release с тегом `latest`
- добавляет туда `geoip-refilter-only.dat` и `geosite-refilter-ruinside-ads.dat`

Чтобы это заработало на GitHub:

1. Инициализируйте git прямо в этой папке и привяжите репозиторий:

   ```bash
   cd refilter_dat_project
   git init
   git add .
   git commit -m "Initial import of refilter builder"
   git branch -M main
   git remote add origin git@github.com:fungalspores/dt.git
   git push -u origin main
   ```

2. Зайдите на страницу Actions репозитория `fungalspores/dt` и убедитесь,
   что workflow `Build and release refilter dat files` включён.

После этого GitHub Actions будет каждые 6 часов собирать новые `.dat` и
обновлять release `latest` с актуальными файлами.