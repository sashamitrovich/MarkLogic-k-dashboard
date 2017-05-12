xquery version "1.0-ml";

module namespace tweets = "http://marklogic.com/rest-api/resource/tweets";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace roxy = "http://marklogic.com/roxy";

import module namespace tweetslib = "http://marklogic.com/tweets" at "/lib/tweets.xqy";

declare function tweets:put(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
) as document-node()?
{
  let $log:=xdmp:log("Fetching Twitter content via REST API extenstion")
  let $num-of-tweets:=200
  let $doc:=doc("/config/sources.json")
  for $name in $doc/twitter
    return tweetslib:get-status-tweets($name ,$num-of-tweets)
};

