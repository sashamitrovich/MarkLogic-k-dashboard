#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the private variables in deploy/lib/server_config.rb
#
# any public method you create here can be called from the command line. See
# the examples below for more information.
#
class ServerConfig

def test()
  @logger.info(@properties["ml.content-db"])
end

def load_tweets()
  r = execute_query(%Q{
    import module namespace tweets = "http://marklogic.com/tweets" at "/lib/tweets.xqy";
    
    (tweets:get-status-tweets("Bankenverband",200),
        tweets:get-status-tweets("ECB",200))
    },
    { :app_name => @properties['ml.app-name'] }
  )
  r.body = parse_json r.body
  logger.info r.body
end

def load_hb()
  r = execute_query(%Q{
    import module namespace hb = "http://marklogic.com/rss/hb" at "/lib/hb.xqy";
    hb:fetch()
    },
    { :app_name => @properties['ml.app-name'] }
  )
  r.body = parse_json r.body
  logger.info r.body

end

def load_finanzen()
  r = execute_query(%Q{
    import module namespace finanzen = "http://marklogic.com/rss/finanzen.net" 
      at "/lib/finanzen.xqy";
    finanzen:fetch()
    },
    { :app_name => @properties['ml.app-name'] }
  )
  r.body = parse_json r.body
  logger.info r.body
end

def load_stock_price()
  r = execute_query(%Q{
    import module namespace util = "http://marklogic.com/utilities" at "/lib/util.xqy";
    import module namespace mem = "http://xqdev.com/in-mem-update" at "/lib/in-mem-update.xqy";

    declare namespace x= "xdmp:http";

    let $docs:= fn:collection("code")
    for $doc in $docs
      let $request:=fn:concat("https://www.quandl.com/api/v3/datasets/FSE/",$doc//Symbol, "_X.csv?api_key=yigbEs6PAybUcxg6Lz_A&amp;start_date=2016-07-25")
      let $response:=xdmp:http-get($request)
      return if ($response//x:code=200) then      
        let $quote:= $response[2]
        let $prices:=util:parse-price-csv($quote)   
        return if(fn:count($prices)>1) then
          let $newDoc:=document {
            element stock {
              $doc/@*,
              $doc/stock/*,
              element type {"stock"},       
              element source {"Quandl"},
               for $price at $pos in $prices
                  let $empty:= fn:empty($price/Change/text())
                  let $change:= if($empty) then 0 else $price/Change/text()
                  let $close:=$price/Close/text()
                  let $open:=($close - $change)
                  let $percent:=($change * 100) div $open
                  return
                  if ($pos = 1) then element price-latest { $price/*, element Percent { $percent } }
                  else element price { $price/*, element Percent { $percent } }   
              }
          }
          let $newUri:=fn:concat($newDoc//Symbol)
          let $diff:= round-half-to-even(($newDoc//Close)[1]-($newDoc//Close)[8],2)
          let $week-change-percent:=round-half-to-even(($diff * 100) div ($newDoc//Close)[1], 2)
          let $week-change-percent-element:=element week-change-percent {$week-change-percent}
          let $week-change:=element week-change { $diff }
          let $newDoc:=mem:node-insert-after($newDoc/stock/source,$week-change-percent-element)
          return xdmp:document-insert($newUri, $newDoc,(),("data","stock-price"))
        else 
          xdmp:log(concat("skipping ", $doc//Symbol))
      else
        xdmp:log(concat("skipping ", $doc//Symbol))
    },
    { :app_name => @properties['ml.app-name'] }
  )
  r.body = parse_json r.body
  logger.info r.body
end
  #
  # You can easily "override" existing methods with your own implementations.
  # In ruby this is called monkey patching
  #
  # first you would rename the original method
  # alias_method :original_deploy_modules, :deploy_modules

  # then you would define your new method
  # def deploy_modules
  #   # do your stuff here
  #   # ...

  #   # you can optionally call the original
  #   original_deploy_modules
  # end

  #
  # you can define your own methods and call them from the command line
  # just like other roxy commands
  # ml local my_custom_method
  #
  # def my_custom_method()
  #   # since we are monkey patching we have access to the private methods
  #   # in ServerConfig
  #   @logger.info(@properties["ml.content-db"])
  # end

  #
  # to create a method that doesn't require an environment (local, prod, etc)
  # you woudl define a class method
  # ml my_static_method
  #
  # def self.my_static_method()
  #   # This method is static and thus cannot access private variables
  #   # but it can be called without an environment
  # end
end

#
# Uncomment, and adjust below code to get help about your app_specific
# commands included into Roxy help. (ml -h)
#

#class Help
#  def self.app_specific
#    <<-DOC.strip_heredoc
#
#      App-specific commands:
#        example       Installs app-specific alerting
#    DOC
#  end
#
#  def self.example
#    <<-DOC.strip_heredoc
#      Usage: ml {env} example [args] [options]
#      
#      Runs a special example task against given environment.
#      
#      Arguments:
#        this    Do this
#        that    Do that
#        
#      Options:
#        --whatever=value
#    DOC
#  end
#end
