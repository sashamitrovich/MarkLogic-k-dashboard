xquery version "1.0-ml";
module namespace rss="http://marklogic.com/rss/hb";

declare function rss:fetch() {
   let $request:="http://www.handelsblatt.com/contentexport/feed/wirtschaft"
let $options:=
  <options xmlns="xdmp:document-get">
    <encoding>auto</encoding>
  </options>
let $response:= xdmp:http-get($request, $options)
let $picture:="[Fn], [D01] [MNn] [Y] [H01]:[m01]:[s01] [Z]"
let $source_name:=$response[2]/rss/channel/title/text()
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
    return xdmp:document-insert($newUri,$newDoc,$permissions,("data","data/rss")) 

};