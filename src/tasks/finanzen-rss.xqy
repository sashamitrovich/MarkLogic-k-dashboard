xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";

let $request:="http://www.finanzen.net/index/DAX/RSS"
let $options:=
  <options xmlns="xdmp:document-get">
    <encoding>iso-8859-1</encoding>
  </options>
let $response:= xdmp:http-get($request,$options)
let $pubDate:= current-dateTime()
let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))
for $item in $response[2]//item
  return
(:     let $last-part := fn:tokenize($item/*:guid, "/")[last()] :)
(:    let $guid := fn:substring-before($last-part,".") :)
    let $newUri:=fn:concat(fn:substring-after($item/guid/text(),".net"),".xml")
    let $newDoc:=document {
      element item {
        $item/@*,
        $item/*,
        element type { "rss" },
        element pubDate {$pubDate}
      }
    }
    return xdmp:document-insert($newUri,$newDoc,$permissions,("data","rss","finanzen.net"))
