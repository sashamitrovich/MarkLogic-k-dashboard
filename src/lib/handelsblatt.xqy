xquery version "1.0-ml";

module namespace hb="http://marklogic.com/rss/handelsblatt";

declare function hb:fetch() {
   let $request:="http://www.handelsblatt.com/contentexport/feed/wirtschaft"
let $options:=
  <options xmlns="xdmp:document-get">
    <encoding>utf-8</encoding>
  </options>
let $response:= xdmp:http-get($request, $options)
let $pubDate:= current-dateTime()
let $picture:="[Fn], [D01] [MNn] [Y] [H01]:[m01]:[s01] [Z]"
let $source_name:="Handelsblatt"
let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))
for $item in $response[2]//item
  return
      let $last-part := fn:tokenize($item/*:guid, "/")[last()]
    let $guid := fn:substring-before($last-part,".")    
    let $newUri:=fn:concat("/nachricht/",$source_name,"/", $guid, ".xml")
    let $newDoc:=document {
      element item {
        element source {
          $item/@*,
          $item/*
        },
        element envelope {
          element type { "rss" },
          element date_time {xdmp:parse-dateTime($picture,$item/pubDate)},
          element source { $source_name }
        }
      }
    }
    return xdmp:document-insert($newUri,$newDoc,$permissions,("data","rss",$source_name)) 

};