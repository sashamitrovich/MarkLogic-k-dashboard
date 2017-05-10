xquery version "1.0-ml";

module namespace util = "http://marklogic.com/utilities";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: parses a stock price CSV from Qandl and creates a document per line :)
(: example CSV: https://www.quandl.com/api/v3/datasets/FSE/SAP_X.csv :)
declare function util:parse-price-csv-from-uri(
  $uri as xs:string

) as node()*
{

  let $doc:=doc($uri)
  return util:parse-price-csv($doc)
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

declare function util:filter-pdf(
  $uri as xs:string

) as node()*
{
  
};
