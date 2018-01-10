xquery version "1.0-ml";
module namespace nttdemo = "http://marklogic.com/ntt-demo";

declare function nttdemo:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{
  let $org-uri := map:get($content, "uri")
  let $org-doc := map:get($content, "value")

   let $new-doc:=document {
     element item {
          element original {
                      $org-doc/@*,
                      $org-doc/*
                     },
                       element envelope {
                       element type { "xml" },
                       element date_time {fn:current-dateTime() },
                       element source { "ntt" }
                     }
                   }
  }

  let $_ := map:put($content, 'value', $new-doc)

    return
      $content
};

