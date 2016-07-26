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
    for $item in $org-doc/*:channel/*:item

    (: duplicate original map, to return multiple ones:)
    let $new-content := map:map(document{$content}/*)
    let $new-uri :=
      map:put($new-content, "uri", concat(, $item/*:guid, ".xml"))
    let $new-value :=
      map:put($new-content, "value",
        document {
          element item {
            $item/@*,
            $item/*
          }
        }
      )
    return
      $new-content
};