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

def load_stock_price()
  r = execute_query(%Q{
    xquery version "1.0-ml";
    import module namespace util = "http://marklogic.com/utilities" at "/lib/util.xqy";

    let $docs:=fn:collection("code")
    for $doc in $docs
    return
      let $request:=fn:concat("https://www.quandl.com/api/v3/datasets/FSE/",$doc//Symbol, "_X.csv?api_key=yigbEs6PAybUcxg6Lz_A&amp;start_date=2016-07-25")
      let $quote:= xdmp:http-get($request)[2]
      let $prices:=util:parse-price-csv($quote)
      for $price in $prices
        let $newDoc:= document { 
          element stock {
            $doc/@*,
            $doc/stock/*,
            element type {"stock"},
            element price {
            $price/*
            }
          }
        }
        let $newUri:=fn:concat($newDoc/stock/Symbol,"-",$newDoc/stock/price/Date)
        return xdmp:document-insert($newUri, $newDoc,(),("data","stock-price"))
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
