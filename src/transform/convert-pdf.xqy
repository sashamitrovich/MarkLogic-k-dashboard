
xquery version "1.0-ml";
module namespace demo = "http://marklogic.com/demo";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare function demo:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{

  let $uri := map:get($content, "uri")
  let $doc := map:get($content, "value")
  let $filter := xdmp:document-filter($doc)
  let $elem := $filter//html:meta[contains(@name, 'xmp_xmp_ModifyDate')]

  let $potentialDate:=fn:data($elem/@content)
  let $empty:= fn:empty( $potentialDate)

  let $pubDate := if($empty) then current-dateTime() else $potentialDate
  let $log:=xdmp:log($pubDate)

  let $permissions:=(xdmp:permission("k-dashboard-role", "read"),
        xdmp:permission("k-dashboard-role", "update"))

  let $text:= $filter//html:body/html:p

  let $doc:=fn:doc("/stop-words/domain/stop-words-custom.txt")
  let $stop-words-custom:=fn:tokenize($doc,"\n")
  let $map-stop-words-custom := map:new((
    for $w in $stop-words-custom
    return map:entry($w, 1)
  ))

  let $terms:=
    cts:distinctive-terms(text{$text/lower-case(.)},<options xmlns="cts:distinctive-terms" xmlns:db="http://marklogic.com/xdmp/database">
      <max-terms>100</max-terms>
      <db:stemmed-searches>decompounding</db:stemmed-searches>
      <db:trailing-wildcard-searches>false</db:trailing-wildcard-searches>
    </options>)/cts:term[cts:word-query/cts:option='unwildcarded']/string-join(.//cts:text, " ")

  let $newDoc := document {
    element item {
      element source {$filter/node()},
        element envelope {
          element source {"internal"},
          element type {"pdf"},
          element date_time {$pubDate},
          element tags {
            for $term in $terms
            return if(fn:not(map:contains($map-stop-words-custom,$term))) then element term {$term} else ()
          }
        }
     }
    }

  return (
    $content
    ,xdmp:document-insert(fn:substring-before($uri,".pdf") || ".xml",$newDoc,$permissions,("data","data/pdf"))
  )

};
