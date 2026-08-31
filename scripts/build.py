#!/usr/bin/env python3
"""Сборка списков маршрутизации: российские и китайские сети, домены прямого пути.

ЗАЧЕМ. Клиенту VPN нужно знать, что вести напрямую, а что в туннель. Готовые
списки в интернете либо огромны (полная геобаза — 19 МБ), либо непрозрачны.
Здесь список собирается из открытых реестров, лежит текстом и виден глазами.

ИСТОЧНИКИ (оба — публичные выгрузки региональных интернет-реестров):
  * ipverse/rir-ip — агрегированные префиксы по странам, обновляется ежедневно;
  * antifilter.download — реестр заблокированного в РФ (для обратной задачи).

ВЫХОД — `lists/`:
  ru-ipv4.txt   российские сети, по одной на строку
  cn-ipv4.txt   китайские сети
  direct-domains.txt  домены, которые всегда идут напрямую

Файлы намеренно плоские: их читает и человек, и роутер, и телефон.
"""

from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LISTS = ROOT / "lists"

SOURCES = {
    "ru-ipv4.txt": "https://raw.githubusercontent.com/ipverse/rir-ip/master/country/ru/ipv4-aggregated.txt",
    "cn-ipv4.txt": "https://raw.githubusercontent.com/ipverse/rir-ip/master/country/cn/ipv4-aggregated.txt",
}

# Домены прямого пути. Российские и китайские сервисы ломаются при заходе с
# зарубежного адреса — банки просят подтверждение, маркетплейсы отдают капчу.
DIRECT_DOMAINS = """\
# Российские сервисы
yandex.ru
ya.ru
vk.com
mail.ru
sber.ru
sberbank.ru
tinkoff.ru
alfabank.ru
gosuslugi.ru
nalog.ru
wildberries.ru
ozon.ru
moysklad.ru
avito.ru
2gis.ru
rutube.ru
kinopoisk.ru
# Китайские сервисы
alibaba.com
aliexpress.com
alipay.com
taobao.com
1688.com
alicdn.com
aliyun.com
qq.com
weixin.qq.com
wechat.com
baidu.com
bilibili.com
# По решению владельца — прямым путём
reddit.com
redd.it
redditstatic.com
redditmedia.com
"""


def fetch(url: str) -> list[str]:
    """Строки-префиксы из выгрузки реестра; комментарии и пустые строки отброшены."""
    with urllib.request.urlopen(url, timeout=120) as response:
        body = response.read().decode()
    return [line.strip() for line in body.splitlines() if line[:1].isdigit()]


def main() -> int:
    LISTS.mkdir(exist_ok=True)
    total = 0
    for name, url in SOURCES.items():
        prefixes = fetch(url)
        if not prefixes:
            print(f"пусто по {name} — источник не отдал ни одного префикса", file=sys.stderr)
            return 1
        (LISTS / name).write_text("\n".join(prefixes) + "\n", encoding="utf-8")
        print(f"{name}: {len(prefixes)} префиксов")
        total += len(prefixes)
    (LISTS / "direct-domains.txt").write_text(DIRECT_DOMAINS, encoding="utf-8")
    domains = [d for d in DIRECT_DOMAINS.splitlines() if d and not d.startswith("#")]
    print(f"direct-domains.txt: {len(domains)} доменов")
    print(f"итого префиксов: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
