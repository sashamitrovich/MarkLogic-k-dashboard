xquery version "1.0-ml";

module namespace twitter = "http://marklogic.com/twitter";

import module namespace oa="http://marklogic.com/ns/oauth" at "/lib/oauth.xqy";

declare function twitter:api(
  $request-type as xs:string,
  $request-url as xs:string,
  $screen-name as xs:string,
  $number-of-tweets as xs:integer
) as document-node() {

  let $service :=
     <oa:service-provider realm="http://twitter.com">
       <oa:request-token>
         <oa:uri>http://twitter.com/oauth/request_token</oa:uri>
         <oa:method>GET</oa:method>
       </oa:request-token>
       <oa:user-authorization>
         <oa:uri>http://twitter.com/oauth/authorize</oa:uri>
       </oa:user-authorization>
       <oa:user-authentication>
         <oa:uri>http://twitter.com/oauth/authenticate</oa:uri>
         <oa:additional-params>force_login=true</oa:additional-params>
       </oa:user-authentication>
       <oa:access-token>
         <oa:uri>http://twitter.com/oauth/access_token</oa:uri>
         <oa:method>POST</oa:method>
       </oa:access-token>
       <oa:signature-methods>
         <oa:method>HMAC-SHA1</oa:method>
       </oa:signature-methods>
       <oa:oauth-version>1.0</oa:oauth-version>
       <oa:authentication>
         <oa:consumer-key>Z8zFrPjCg2vJDNphMX1jOzkks</oa:consumer-key>
         <oa:consumer-key-secret>F6gdjXDEc1s25rudfq03ZddUY2y9vAaa6w4unZFLFLxF40DIXB</oa:consumer-key-secret>
       </oa:authentication>
     </oa:service-provider>


  let $access-token := "741260955200409601-Lc4aExO4i27x4fwOidEKOgPy4g6bLJc"
  let $access-token-secret := "nqT647LIR8Guk3hOyEkdZkQhgBcf2hSNE1vqhoMJkIWvF"
  let $options:=
    <oa:options>
       <screen_name>{ $screen-name }</screen_name>
       <count>{ $number-of-tweets }</count>
       <page>1</page>
    </oa:options>
  let $tweets := oa:signed-request($service,
                    $request-type, $request-url,
                    $options, $access-token, $access-token-secret)
  return $tweets
};

