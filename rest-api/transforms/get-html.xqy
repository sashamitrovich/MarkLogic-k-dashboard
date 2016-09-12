xquery version "1.0-ml";
module namespace trans = "http://marklogic.com/rest-api/transform/get-html";

declare namespace html = "http://www.w3.org/1999/xhtml";

declare function trans:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node()
) as document-node()
{
  let $qtext := map:get($params, "q")
  let $new-content:=$content/item/source/node()
  let $base-uri := map:get($context, "uri")
  let $tmp:=map:put($context,'output-type', xdmp:uri-content-type($base-uri))
  let $new-content:=cts:highlight($new-content, $qtext, <mark>{$cts:text}</mark>)
  return document { $new-content }
};
