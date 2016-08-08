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

  let $doc:= object-node {
    "dayWinner": object-node {
      "name": $day-winner/stock/Name/text(),
      "symbol": $day-winner/stock/Symbol/text(),
      "weekChange": $day-winner/stock/week-change-percent/text(),
      "dayChange": $day-winner/stock/price-latest/Percent/text()
    },
    "dayLooser": object-node {
      "name": $day-looser/stock/Name/text(),
      "symbol": $day-looser/stock/Symbol/text(),
      "weekChange": $day-looser/stock/week-change-percent/text(),
      "dayChange": $day-looser/stock/price-latest/Percent/text()
    },
    "weekWinner": object-node {
      "name": $week-winner/stock/Name/text(),
      "symbol": $week-winner/stock/Symbol/text(),
      "weekChange": $week-winner/stock/week-change-percent/text(),
      "dayChange": $week-winner/stock/price-latest/Percent/text()
    },
    "weekLooser": object-node {
      "name": $week-looser/stock/Name/text(),
      "symbol": $week-looser/stock/Symbol/text(),
      "weekChange": $week-looser/stock/week-change-percent/text(),
      "dayChange": $week-looser/stock/price-latest/Percent/text()
    }
  }
  return (map:put($context,"output-types","application/json"),document {  $doc})
};
