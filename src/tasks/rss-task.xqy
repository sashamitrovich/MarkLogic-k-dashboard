import module namespace rss = "http://marklogic.com/rss" at "/lib/rss.xqy";

let $log:=xdmp:log("Executing rss task")
let $sources:=doc("/config/sources.json")
for $rss-source in $sources/rss
  return rss:fetch($rss-source/link, $rss-source/encoding)
