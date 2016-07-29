xquery version "1.0-ml";
module namespace demo = "http://marklogic.com/demo";

import module namespace mem = "http://xqdev.com/in-mem-update" at "/lib/in-mem-update.xqy";

declare function demo:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{
  let $doc := map:get($content, "value")/node()
   
  (: duplicate original map, to return multiple ones:)
  let $new-content := map:map(document{$content}/*)
  let $newSymbol:=
    <Symbol>
      {fn:substring-before(fn:substring-after($doc/Symbol,"/"),"_")}
    </Symbol>
  let $newName:=
    <Name>
      {fn:normalize-space(fn:substring-before($doc/Name,"("))}
    </Name>
  let $newDoc:=document {
    element stock {
      $newName,
      $newSymbol
      }
  }
  (: let $new-value :=
      map:put($new-content, "value", mem:node-replace($doc/Symbol, $newSymbol)) :)
       let $new-value :=
      map:put($new-content, "value", $newDoc/node())
  return $new-content
    
};