xquery version "1.0-ml";
module namespace stock = "http://www.marklogic.com/stock";

import module namespace util = "http://marklogic.com/utilities" at "/lib/util.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/lib/in-mem-update.xqy";

declare namespace x= "xdmp:http";

declare function stock:get-day-winner () {
    let $path:="/stock/price-latest/Percent"
    let $max:=cts:max(cts:path-reference($path))
    
    let $order:=cts:index-order(cts:path-reference($path),"descending")
    
    let $dateQuery:=cts:path-range-query("/stock/price-latest/Date", ">=",
fn:current-dateTime()- xs:dayTimeDuration("P7D"))
    let $docs:=cts:search(fn:collection("data/stock-price"),$dateQuery,$order)

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
   let $order:=cts:index-order(cts:path-reference($path),"ascending")
    
    let $dateQuery:=cts:path-range-query("/stock/price-latest/Date", ">=",
fn:current-dateTime()- xs:dayTimeDuration("P7D"))
    let $docs:=cts:search(fn:collection("data/stock-price"),$dateQuery,$order)
    return $docs[1]
};

declare function stock:get-week-looser () {
    let $path:="/stock/week-change-percent"
    let $min:=cts:min(cts:path-reference($path))
    let $docs:=cts:search(fn:collection("data/stock-price"),cts:path-range-query($path, "=", $min) )
    return $docs[1]
};

declare function stock:fetch-prices () {

    let $permissions:=(xdmp:permission("k-dashboard-role", "read"),
        xdmp:permission("k-dashboard-role", "update"))
    let $docs:= fn:collection("code")
    let $options:=<options xmlns="xdmp:http">
       <verify-cert>false</verify-cert>
    </options>
    let $a1:="https://www.quandl.com/api/v3/datasets.xml?database_code=FSE&amp;per_page=100&amp;sort_by=id&amp;page=1&amp;api_key=yigbEs6PAybUcxg6Lz_A"
    let $a2:="https://www.quandl.com/api/v3/datasets.xml?database_code=FSE&amp;per_page=100&amp;sort_by=id&amp;page=2&amp;pi_key=yigbEs6PAybUcxg6Lz_A"

    let $response1:=xdmp:http-get($a1, $options)
    let $response2:=xdmp:http-get($a2, $options)
    let $datasets:=($response1[2]//dataset,$response2[2]//dataset)
    for $dataset in $datasets
        let $doc:=document { 
        element stock {
        element Name {$dataset/name/text()},
        element Symbol {fn:replace($dataset/dataset-code, "_X", "")},
        element Description {$dataset/description/text()}
        }}

        let $request:=fn:concat("https://www.quandl.com/api/v3/datasets/FSE/",$doc//Symbol, "_X.csv?api_key=yigbEs6PAybUcxg6Lz_A&amp;start_date=2018-02-01")
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
                    (: let $change:= fn:round-half-to-even((fn:number($price//Close/text())-fn:number($price//Open/text())),2) :)
                    let $close:=$price/Close/text()
                    (: let $open:=($close - $change) :)
                    let $open:=$prices[$pos+1]/Close/text()
                    let $change:=fn:round-half-to-even((fn:number($close)-fn:number($open)),2)
                    let $percent:=round-half-to-even(($change * 100) div $open,2)
                    let $fixpercent := if ($open eq 0) then 0 else $percent
                    let $price:=mem:node-replace($price//Change,element Change {$change})
                    return
                    if ($pos = 1) then element price-latest { $price/*, element Percent { $fixpercent } }
                    else element price { $price/*, element Percent { $percent } }
                }
            }
            let $newUri:=fn:concat($newDoc//Symbol)

            let $diff:=  if(($newDoc//Close)[6]) then(round-half-to-even(($newDoc//Close)[1]-($newDoc//Close)[6],2)) else (0)  
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
