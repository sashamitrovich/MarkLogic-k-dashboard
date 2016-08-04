xquery version "1.0-ml";
import module namespace hb = "http://marklogic.com/rss/handelsblatt" 
  at "/lib/handelsblatt.xqy";
return hb:fetch()
