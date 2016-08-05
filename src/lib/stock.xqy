xquery version "1.0-ml";
declare namespace stock = "http://www.marklogic.com/stock";

declare function stock:get-winner () {

let $path:="/stock/price-latest/Change"
let $max:=xs:float(cts:max(cts:path-reference($path)))
let $docs:=cts:search(fn:collection("stock-price"),cts:path-range-query($path, "=", xs:untypedAtomic($max) ))
return $docs[1]
};

declare function stock:get-looser () {

let $path:="/stock/price-latest/Change"
let $min:=xs:float(cts:min(cts:path-reference($path)))
let $docs:=cts:search(fn:collection("stock-price"),cts:path-range-query($path, "=", xs:untypedAtomic($min) ))
return $docs[1]
};