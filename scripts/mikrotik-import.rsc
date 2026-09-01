# Наполнение address-list роутера MikroTik из списков этого проекта.
#
# ⛔ ЭТОТ СКРИПТ НЕ РАБОТАЕТ НА РЕАЛЬНОМ ОБЪЁМЕ. Проверено на hAP ac2 (RouterOS
# 7.20.7) 01.09.2026: [/file get ... contents] возвращает ПУСТУЮ строку для
# файла 135 КБ — RouterOS отдаёт содержимое только небольших файлов. Скрипт при
# этом отрабатывает без ошибки и добавляет НОЛЬ записей, то есть молча делает
# вид, что сработал. Оставлен здесь как предупреждение.
#
# РАБОЧИЙ СПОСОБ — готовые файлы команд в каталоге import/ и штатный /import:
#
#   /tool fetch url="https://raw.githubusercontent.com/Alexceus-dev/routing-lists/main/import/geo-ru.rsc" dst-path=geo-ru.rsc mode=https
#   /import file-name=geo-ru.rsc
#
# ВНИМАНИЕ, ПАМЯТЬ. Замер на hAP ac2 (256 МБ): 7274 записи заняли 22 МБ.
# Полный набор RU+CN — 14163 записи, около 42 МБ. Перед импортом посмотрите
# свободную память: /system resource print
#
# ВНИМАНИЕ, УДАЛЕНИЕ. Снимать список одной командой на тысячах записей нельзя:
# процессор роутера уходит в полку на минуты, и сеть в это время не
# обслуживается. Удаляйте частями, по 500 штук:
#   :for i from=1 to=30 do={ /ip firewall address-list remove [:pick [find list=GEO_RU] 0 500] }

:local base "https://raw.githubusercontent.com/Alexceus-dev/routing-lists/main/lists/"

:foreach f in={"ru-ipv4.txt";"cn-ipv4.txt"} do={
  :log info ("routing-lists: качаю " . $f)
  /tool fetch url=($base . $f) dst-path=("routing-" . $f) mode=https
  :local data [/file get [find name=("routing-" . $f)] contents]
  :local len [:len $data]
  :if ($len = 0) do={
    :log error ("routing-lists: contents пуст — файл слишком велик для чтения скриптом, используйте import/*.rsc")
  }
  :local pos 0
  :while ($pos < $len) do={
    :local nl [:find $data "\n" $pos]
    :if ([:typeof $nl] = "nil") do={ :set nl $len }
    :local line [:pick $data $pos $nl]
    :if ([:len $line] > 6) do={
      :do { /ip firewall address-list add list=GEO_DIRECT address=$line } on-error={}
    }
    :set pos ($nl + 1)
  }
  /file remove [find name=("routing-" . $f)]
}
