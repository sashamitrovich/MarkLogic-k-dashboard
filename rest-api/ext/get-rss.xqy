xquery version "1.0-ml";

module namespace rss = "http://marklogic.com/rest-api/resource/rss";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace rapi="http://marklogic.com/rest-api";

import module namespace rsslib = "http://marklogic.com/rss" at "/lib/rss.xqy";

declare %rapi:transaction-mode("update") function  rss:put(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
) as document-node()?
{
  let $log:=xdmp:log("Fetching rss content via REST API extenstion")
  return rsslib:fetch-all()
};