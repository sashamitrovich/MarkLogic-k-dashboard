xquery version "1.0-ml";
module namespace tweets = "http://marklogic.com/tweets";
import module namespace twitter = "http://marklogic.com/twitter" at "/lib/twitter.xqy";



(: fetches a certain number ($num-of-tweets) of status tweets for the given $screen-name and saves each tweet as separate doc into ML :)
declare function tweets:get-status-tweets(
  $screen-name as xs:string,
  $num-of-tweets as xs:integer
)
{

let $permissions:=(xdmp:permission("kpmg-dashboard-role", "read"),
        xdmp:permission("kpmg-dashboard-role", "update"))
let $response:=twitter:api("GET","https://api.twitter.com/1.1/statuses/user_timeline.json",$screen-name, $num-of-tweets)
let $picture:="[Fn] [MNn] [D01] [H01]:[m01]:[s01] [Z] [Y]"
let $tweets:=$response/array-node()/object-node()

for $tweet in $tweets
  let $uri:=fn:concat("/twitter/",$screen-name,"/",$tweet/id_str,".json")
  let $title:=$tweet/text
  let $urls:=$tweet/entities/urls/url
  (:   let $title:=local:add-link($title, $urls) :)
  let $meta-node:=object-node {
    "type" : "tweet",
    "date_time":xdmp:parse-dateTime($picture,$tweet/created_at),
    "link":fn:concat("http://www.twitter.com/",$tweet/user/screen_name,"/status/",$tweet/id_str),
    "tags": array-node { $tweet//hashtags/text },
    "title":$title,
    "source":$screen-name
  }
  let $doc:=object-node { "source" :$tweet , "envelope":$meta-node }
    return (:  ($uri,$doc) :)
      xdmp:document-insert($uri,$doc,$permissions,("data/twitter","data"))
};
