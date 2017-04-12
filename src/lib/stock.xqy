xquery version "1.0-ml";
module namespace stock = "http://www.marklogic.com/stock";

import module namespace util = "http://marklogic.com/utilities" at "/lib/util.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/lib/in-mem-update.xqy";

declare namespace x= "xdmp:http";

declare function stock:get-day-winner () {
    let $path:="/stock/price-latest/Percent"
    let $max:=cts:max(cts:path-reference($path))
    let $docs:=cts:search(fn:collection("data/stock-price"),cts:path-range-query($path, "=", $max ))
    return $docs[1]
};

declare function stock:get-week-winner () {
    let $path:="/stock/week-change-percent"
    let $max:=cts:max(cts:path-reference($path))
    let $docs:=cts:search(fn:collection("data/stock-price"),cts:path-range-query($path, "=", $max) )
    return $docs[1]
};

declare function stock:get-day-looser () {
    let $path:="/stock/price-latest/Percent"
    let $min:=cts:min(cts:path-reference($path))
    let $docs:=cts:search(fn:collection("data/stock-price"),cts:path-range-query($path, "=", $min) )
    return $docs[1]
};

declare function stock:get-week-looser () {
    let $path:="/stock/week-change-percent"
    let $min:=cts:min(cts:path-reference($path))
    let $docs:=cts:search(fn:collection("data/stock-price"),cts:path-range-query($path, "=", $min) )
    return $docs[1]
};

declare function stock:fetch-prices () {

    let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))
    let $docs:= fn:collection("code")
    let $options:=<options xmlns="xdmp:http">
       <verify-cert>false</verify-cert>
    </options>
    for $doc in $docs
      let $request:=fn:concat("https://www.quandl.com/api/v3/datasets/FSE/",$doc//Symbol, "_X.csv?api_key=yigbEs6PAybUcxg6Lz_A&amp;start_date=2016-07-25")
      let $response:=xdmp:http-get($request, $options)
      return if ($response//x:code=200) then
        let $quote:= $response[2]
        let $prices:=util:parse-price-csv($quote)
        return if(fn:count($prices)>1) then
          let $newDoc:=document {
            element stock {
              $doc/@*,
              $doc/stock/*,
              element type {"stock"},
              element source {"Quandl"},
               for $price at $pos in $prices
                  let $empty:= fn:empty($price/Change/text())
                  let $change:= if($empty) then 0 else $price/Change/text()
                  let $close:=$price/Close/text()
                  let $open:=($close - $change)
                  let $percent:=round-half-to-even(($change * 100) div $open,2)
                  return
                  if ($pos = 1) then element price-latest { $price/*, element Percent { $percent } }
                  else element price { $price/*, element Percent { $percent } }
              }
          }
          let $newUri:=fn:concat($newDoc//Symbol)

          let $diff:=  if(($newDoc//Close)[8]) then(round-half-to-even(($newDoc//Close)[1]-($newDoc//Close)[8],2)) else (0)  
          let $week-change-percent:=round-half-to-even(($diff * 100) div ($newDoc//Close)[1], 2)
          let $week-change-percent-element:=element week-change-percent {$week-change-percent}
          let $week-change:=element week-change { $diff }
          let $newDoc:=mem:node-insert-after($newDoc/stock/source,$week-change-percent-element)
          return xdmp:document-insert($newUri, $newDoc,$permissions,("data","data/stock-price"))
        else
          xdmp:log(concat("skipping ", $doc//Symbol))
      else
        xdmp:log(concat("skipping ", $doc//Symbol))
};
