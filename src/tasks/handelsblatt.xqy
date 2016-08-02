xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";

let $request:="http://www.handelsblatt.com/contentexport/feed/wirtschaft"
let $options:=
  <options xmlns="xdmp:document-get">
    <encoding>utf-8</encoding>
  </options>
let $response:= xdmp:http-get($request, $options)
let $pubDate:= current-dateTime()
let $picture:="[Fn], [D01] [MNn] [Y] [H01]:[m01]:[s01] [Z]"
let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))
for $item in $response[2]//item
  return
    let $last-part := fn:tokenize($item/*:guid, "/")[last()]
    let $guid := fn:substring-before($last-part,".")    
    let $newUri:=fn:concat("/nachricht/handelsblatt/", $guid, ".xml")
    let $newDoc:=document {
      element item {
        $item/@*,
        $item/* except $item/pubDate,
        element type { "rss" },
        element pubDate {xdmp:parse-dateTime($picture,$item/pubDate)}
      }
    }
    return xdmp:document-insert($newUri,$newDoc,$permissions,("data","rss","handelsblatt"))