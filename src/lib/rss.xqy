xquery version "1.0-ml";
module namespace rss="http://marklogic.com/rss";

declare function rss:fetch($request as xs:string, $encoding as xs:string) {

  let $options:=
  <options xmlns="xdmp:document-get">
    <encoding>{$encoding}</encoding>
    <format xmlns="xdmp:document-get">xml</format>
  </options>
  let $response:= xdmp:http-get($request, $options)
  let $pubDate:= current-dateTime()
  let $picture:="[Fn], [D01] [MNn] [Y] [H01]:[m01]:[s01] [Z]"
  let $source_name:=fn:tokenize(fn:tokenize(fn:tokenize($request, "//")[2],"/")[1],"\.")[2]
  let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))
  for $item in $response[2]//item
    return
      let $last-part := fn:tokenize($item/guid, "/")[last()]
      let $guid :=  $last-part (: fn:substring-before($last-part,".")     :)
      let $newUri:=fn:concat("/nachricht/",$source_name,"/", $guid, ".xml")
      let $newDoc:=document {
        element item {
        element original {
          $item/@*,
          $item/*
        },
        element envelope {
          element type { "rss" },
          element date_time {$pubDate},
          element source { rss:capitalize-first($source_name)}
        }
      }
    }
    return
(:    ( $newUri, $newDoc) :)
    xdmp:document-insert($newUri,$newDoc,$permissions,("data","data/rss"))
};

declare function rss:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
