package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/v2fly/v2ray-core/v5/app/router/routercommon"
	"google.golang.org/protobuf/proto"
)

// Простая утилита: читает geosite.dat, оставляет только указанные списки
// (countryCode) и пишет урезанный geosite.dat.
func main() {
	inputPath := flag.String("in", "", "Путь к исходному geosite.dat")
	outputPath := flag.String("out", "", "Путь для сохранения отфильтрованного geosite.dat")
	listsFlag := flag.String("lists", "", "Список нужных списков через запятую (например: refilter,ru-available-only-inside,category-ads-all)")

	flag.Parse()

	if *inputPath == "" || *outputPath == "" || *listsFlag == "" {
		log.Fatalf("нужно указать -in, -out и -lists")
	}

	wanted := make(map[string]struct{})
	for _, name := range strings.Split(*listsFlag, ",") {
		name = strings.TrimSpace(name)
		if name == "" {
			continue
		}
		wanted[name] = struct{}{}
		wanted[strings.ToLower(name)] = struct{}{}
	}

	data, err := os.ReadFile(*inputPath)
	if err != nil {
		log.Fatalf("не удалось прочитать входной файл %s: %v", *inputPath, err)
	}

	var src routercommon.GeoSiteList
	if err := proto.Unmarshal(data, &src); err != nil {
		log.Fatalf("не удалось распарсить geosite.dat как protobuf GeoSiteList: %v", err)
	}

	var dst routercommon.GeoSiteList
	for _, entry := range src.Entry {
		if entry == nil {
			continue
		}
		code := strings.TrimSpace(entry.CountryCode)
		if _, ok := wanted[code]; ok {
			dst.Entry = append(dst.Entry, entry)
			continue
		}
		if _, ok := wanted[strings.ToLower(code)]; ok {
			dst.Entry = append(dst.Entry, entry)
		}
	}

	if len(dst.Entry) == 0 {
		log.Fatalf("после фильтрации не осталось ни одного списка; возможно, в исходном geosite.dat нет запрошенных тегов (%s)", *listsFlag)
	}

	outData, err := proto.Marshal(&dst)
	if err != nil {
		log.Fatalf("не удалось сериализовать результат: %v", err)
	}

	if err := os.WriteFile(*outputPath, outData, 0o644); err != nil {
		log.Fatalf("не удалось записать файл %s: %v", *outputPath, err)
	}

	fmt.Printf("✅ Успешно создан отфильтрованный geosite.dat: %s\n", *outputPath)
}
