xquery version "1.0-ml";

module namespace swl = "http://marklogic.com/rest-api/resource/swl";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace roxy = "http://marklogic.com/roxy";

import module namespace stock="http://www.marklogic.com/stock" at "/lib/stock.xqy";


(:
 : To add parameters to the functions, specify them in the params annotations.
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") ext:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :)

(:
 :)
declare
function swl:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
 let $day-winner:=stock:get-day-winner()
  let $day-looser:=stock:get-day-looser()
  let $week-winner:=stock:get-week-winner()
  let $week-looser:=stock:get-week-looser()
  let $doc:= document {
    element stats {
      element day-winner {
        $day-winner/stock/* except //price
      },
      element day-looser {
        $day-looser/stock/* except //price
      },
       element week-winner {
        $week-winner/stock/* except //price
      },
      element week-looser {
        $week-looser/stock/* except //price
      }
    }
  }
  return $doc
};