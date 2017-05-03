xquery version "1.0-ml";
module namespace finanzen="http://marklogic.com/rss/finanzen.net";

declare function finanzen:fetch() {

let $request:="http://www.finanzen.net/index/DAX/RSS"
let $options:=
  <options xmlns="xdmp:document-get">
    <encoding>iso-8859-1</encoding>
  </options>
let $response:= xdmp:http-get($request,$options)
let $pubDate:= current-dateTime()
let $source_name:="Finanzen.net"
let $permissions:=(xdmp:permission("k-dashboard-role", "read"),
        xdmp:permission("k-dashboard-role", "update"))
for $item in $response[2]//item
  return
(:     let $last-part := fn:tokenize($item/*:guid, "/")[last()] :)
(:    let $guid := fn:substring-before($last-part,".") :)
    let $newUri:=fn:concat("/nachricht/",$source_name,"/",fn:substring-after($item/guid/text(),".net"),".xml")
    let $newDoc:=document {
      element item {  
        element source {
          $item/@*,
          $item/*
        },
        element envelope {
          element type { "rss" },
          element date_time {$pubDate},
          element source { $source_name }
        }
      }
    }
    return xdmp:document-insert($newUri,$newDoc,$permissions,("data","data/rss"))
};