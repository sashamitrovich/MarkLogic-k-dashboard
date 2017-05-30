import module namespace rss = "http://marklogic.com/rss" at "/lib/rss.xqy";

let $log:=xdmp:log("Executing rss task")
return rss:fetch-all()
