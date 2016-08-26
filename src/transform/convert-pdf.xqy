
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

  return (

    $content
    ,map:new((map:entry("uri",substring-before($uri,".pdf") || ".xhtml"),map:entry("value",$filter)))
  )
  
};