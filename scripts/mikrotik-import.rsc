# Наполнение address-list роутера MikroTik из списков этого проекта.
#
# ВНИМАНИЕ, ПАМЯТЬ. Замер на плате hAP ac2 (256 МБ): 7274 записи заняли 22 МБ.
# Полный набор RU+CN — 14163 записи, около 42 МБ. Перед импортом посмотрите
# свободную память: /system resource print
#
# ВНИМАНИЕ, УДАЛЕНИЕ. Снимать список одной командой на тысячах записей нельзя:
# процессор роутера уходит в полку на минуты, и сеть в это время не
# обслуживается. Удаляйте частями, по 500 штук:
#   :for i from=1 to=30 do={ /ip firewall address-list remove [:pick [find list=GEO_DIRECT] 0 500] }

:local base "https://raw.githubusercontent.com/Alexceus-dev/routing-lists/main/lists/"

:foreach f in={"ru-ipv4.txt";"cn-ipv4.txt"} do={
  :log info ("routing-lists: качаю " . $f)
  /tool fetch url=($base . $f) dst-path=("routing-" . $f) mode=https
  :local data [/file get [find name=("routing-" . $f)] contents]
  :local len [:len $data]
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
:log info ("routing-lists: в GEO_DIRECT записей " . [:len [/ip firewall address-list find list=GEO_DIRECT]])
