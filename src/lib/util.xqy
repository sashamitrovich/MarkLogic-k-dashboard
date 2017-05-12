xquery version "1.0-ml";

module namespace util = "http://marklogic.com/utilities";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace html = "http://www.w3.org/1999/xhtml";

(: parses a stock price CSV from Qandl and creates a document per line :)
(: example CSV: https://www.quandl.com/api/v3/datasets/FSE/SAP_X.csv :)
declare function util:parse-price-csv-from-uri(
  $uri as xs:string

) as node()*
{

  let $doc:=doc($uri)
  return util:parse-price-csv($doc)
};

declare function util:filter-pdf($uri) 
{

  let $doc:=doc($uri)
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

  let $newUri:= fn:substring-before($uri,".pdf") || ".xml"

  return (
    xdmp:log(fn:concat('*****Document ', $newUri, ' was created.*****')),
    xdmp:document-insert($newUri,$newDoc,$permissions,("data","data/pdf","pdf"))
  )
    
};

declare function util:parse-price-csv(
  $doc as document-node()
) as node()*
{
let $lines:=fn:tokenize($doc,"\n")
  let $header:=fn:tokenize(fn:replace($lines[1]," ",""),",")
  let $lines := fn:remove($lines,1) (: remove the header, we parsed it :)
  let $lines := fn:remove($lines,fn:count($lines)) (: remove the last, it's empty :)
  for $line in $lines
  return
    <stock-price>
    {
      let $columns:=fn:tokenize($line,",")
      let $picture:="[Y0001]-[M01]-[D01]"
      for $columnheader at $pos in $header
      return if(fn:replace($columnheader," ","")="Date")
        then element {fn:replace($columnheader," ","")} {xdmp:parse-dateTime($picture,$columns[$pos]) }
        else element {fn:replace($columnheader," ","")} {if($columns[$pos]="") then 0 else $columns[$pos]}
    }
    </stock-price>
};
