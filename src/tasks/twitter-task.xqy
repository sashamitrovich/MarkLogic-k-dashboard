import module namespace tweets = "http://marklogic.com/tweets" at "/lib/tweets.xqy";
    
    (tweets:get-status-tweets("Bankenverband",200),
        tweets:get-status-tweets("ECB",200),
        tweets:get-status-tweets("IIF",200),
        tweets:get-status-tweets("bundesbank",200))