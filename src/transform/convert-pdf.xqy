
xquery version "1.0-ml";
module namespace demo = "http://marklogic.com/demo";

declare function demo:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{

  let $uri := map:get($content, "uri")
  let $doc := map:get($content, "value")
  let $filter := xdmp:document-filter($doc)

  let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))

  let $newDoc := document {
    element item {
      element source {$filter/node()},
        element envelope {
          element source {"internal"},
          element type {"pdf"}
        }
     }
    }

  return (
    $content
    ,xdmp:document-insert(fn:substring-before($uri,".pdf") || ".xml",$newDoc,$permissions,("data","data/pdf"))
  )

};
