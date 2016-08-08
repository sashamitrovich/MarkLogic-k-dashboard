xquery version "1.0-ml";
module namespace stock = "http://www.marklogic.com/stock";

declare function stock:get-day-winner () {
    let $path:="/stock/price-latest/Percent"
    let $max:=xs:float(cts:max(cts:path-reference($path)))
    let $docs:=cts:search(fn:collection("stock-price"),cts:path-range-query($path, "=", xs:untypedAtomic($max) ))
    return $docs[1]
};

declare function stock:get-week-winner () {
    let $path:="/stock/week-change-percent"
    let $max:=xs:float(cts:max(cts:path-reference($path)))
    let $docs:=cts:search(fn:collection("stock-price"),cts:path-range-query($path, "=", xs:untypedAtomic($max) ))
    return $docs[1]
};

declare function stock:get-day-looser () {
    let $path:="/stock/price-latest/Percent"
    let $min:=xs:float(cts:min(cts:path-reference($path)))
    let $docs:=cts:search(fn:collection("stock-price"),cts:path-range-query($path, "=", xs:untypedAtomic($min) ))
    return $docs[1]
};

declare function stock:get-week-looser () {
    let $path:="/stock/week-change-percent"
    let $min:=xs:float(cts:min(cts:path-reference($path)))
    let $docs:=cts:search(fn:collection("stock-price"),cts:path-range-query($path, "=", xs:untypedAtomic($min) ))
    return $docs[1]
};

