xquery version "1.0-ml";

module namespace oc = "http://marklogic.com/opencalais";

declare namespace rdf  ="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $memcache as map:map := map:map();

declare variable $cache-root as xs:string := "/opencalais-cache/";

declare function oc:setCacheRoot($new-root as xs:string) as empty-sequence() {
  xdmp:set($cache-root, $new-root)
};

declare function oc:enrich($uri as xs:string, $data as node(), $license as xs:string) as element(rdf:RDF)? {
  oc:enrich($uri, $data, $license, ())
};

declare function oc:enrich($uri as xs:string, $data as node(), $license as xs:string, $language as xs:string?) as element(rdf:RDF)? {
  let $rdf := oc:getFromCache($uri)
  return
  if ($rdf) then (
    xdmp:log(concat("Pulled ", $uri, " from cache")),
    $rdf
  ) else
    let $rdf := oc:get($uri, $data, $license, $language)
    return
    if ($rdf) then (
      xdmp:log(concat("Retrieved ", $uri, " from OpenCalais")),
      oc:putInCache($uri, $rdf),
      $rdf
    ) else (
      xdmp:log(concat("Failed to retrieve ", $uri, " from OpenCalais"))
    )
};

declare function oc:persistCache() {
  oc:persistCache(xdmp:default-permissions(), xdmp:default-collections())
};

declare function oc:persistCache($document-permissions, $collections) {
  for $uri in map:keys($memcache)
  return (
    xdmp:log(concat("Persisting ", $uri, " to database..")),
    xdmp:document-insert($uri, map:get($memcache, $uri), $document-permissions, $collections)
  )
};

declare private function oc:get($uri as xs:string, $data as node(), $license as xs:string, $language as xs:string?) as element(rdf:RDF)? {
  let $response :=
    try {
      xdmp:http-post("https://api.thomsonreuters.com/permid/calais",
      <options xmlns="xdmp:http">
        <timeout>600</timeout>
        <headers>
          <x-ag-access-token>{$license}</x-ag-access-token>
          {
            if ($language) then
              <x-calais-language>{$language}</x-calais-language>
            else ()
          }
          <content-type>text/raw</content-type>
          <outputFormat>xml/rdf</outputFormat>
        </headers>
        <data>{xdmp:quote($data)}</data>
        <format xmlns="xdmp:document-get">xml</format>
      </options>
      )
    } catch ($e) {
      $e
    }
  return
    (: check for errors :)
    if (number($response[1]//*:code) ge 400) then (
      if (contains($response[2], "403 Developer Over Qps")) then (
        xdmp:log(concat("Rate limit exceeded for ", $uri, ", trying again in 2 sec..")),
        xdmp:sleep(2000),
        oc:get($uri, $data, $license, $language)
      ) else if (not($language = "English") and contains($response[2], "Calais continues to expand its list of supported languages")) then (
        xdmp:log(concat("Unrecognized language ", $language, " for ", $uri, ", trying again with English..")),
        xdmp:sleep(500),
        oc:get($uri, $data, $license, "English")
      ) else (
        xdmp:log(($uri, $data, $license, $language, $response))
      )
    ) else (
      $response[2]/rdf:RDF
    )
};

declare private function oc:getFromCache($uri as xs:string) as element(rdf:RDF)? {
  let $uri := concat($cache-root, encode-for-uri(encode-for-uri($uri)), ".xml")
  let $inmem := map:get($memcache, $uri)
  return
  if ($inmem) then
    $inmem
  else
    doc($uri)/rdf:RDF
};

declare private function oc:putInCache($uri as xs:string, $rdf as element(rdf:RDF)) as empty-sequence() {
  let $uri := concat($cache-root, encode-for-uri(encode-for-uri($uri)), ".xml")
  return
    map:put($memcache, $uri, $rdf)
};

