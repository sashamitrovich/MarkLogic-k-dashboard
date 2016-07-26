xquery version "1.0-ml";
module namespace demo = "http://marklogic.com/demo";

declare function demo:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{
  let $org-uri := map:get($content, "uri")
  let $org-doc := map:get($content, "value")
  return
    for $item in $org-doc//*:item

    (: duplicate original map, to return multiple ones:)
    let $new-content := map:map(document{$content}/*)
    
    let $last-part := fn:tokenize($item/*:guid, "/")[last()]
    let $guid := fn:substring-before($last-part,".")

    let $new-uri :=
      map:put($new-content, "uri", concat( $guid, ".xml"))
    let $new-value :=
      map:put($new-content, "value",
        document {
          element item {
            $item/@*,
            $item/*,
            <type>rss</type>
          }
        }
      )
    return
      $new-content
};