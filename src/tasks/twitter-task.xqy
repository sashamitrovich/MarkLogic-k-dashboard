import module namespace tweets = "http://marklogic.com/tweets" at "/lib/tweets.xqy";

  let $num-of-tweets:=200
  let $doc:=doc("/config/sources.json")
  for $name in $doc/twitter
    return tweets:get-status-tweets($name ,$num-of-tweets)
