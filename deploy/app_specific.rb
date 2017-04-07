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

  let $num-of-tweets:=200
  let $doc:=doc("/config/sources.json")
  for $name in $doc/twitter
    return tweets:get-status-tweets($name ,$num-of-tweets)

    },
    { :app_name => @properties['ml.app-name'] }
  )
  r.body = parse_json r.body
  logger.info r.body
end

def load_rss()
  r = execute_query(%Q{
    xquery version "1.0-ml";
    import module namespace rss = "http://marklogic.com/rss" at "/lib/rss.xqy";

    let $sources:=doc("/config/sources.json")
    for $rss-source in $sources/rss
      return ($rss-source, rss:fetch($rss-source/link, $rss-source/encoding))

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
    xquery version "1.0-ml";

    import module namespace stock = "http://www.marklogic.com/stock" at "/lib/stock.xqy";
    stock:fetch-prices()
    },
    { :app_name => @properties['ml.app-name'] }
  )
  r.body = parse_json r.body
  logger.info r.body
end


  # Show-casing some useful overrides, as well as adjusting some module doc permissions
  alias_method :original_deploy_modules, :deploy_modules
  alias_method :original_deploy_rest, :deploy_rest
  alias_method :original_deploy, :deploy
  alias_method :original_clean, :clean

  # Integrate deploy_packages into the Roxy deploy command
  def deploy
    what = ARGV.shift

    case what
      when 'packages'
        deploy_packages
      else
        ARGV.unshift what
        original_deploy
    end
  end

  def deploy_modules
    # Uncomment deploy_packages if you would like to use MLPM to deploy MLPM packages, and
    # include MLPM deploy in deploy modules to make sure MLPM depencencies are loaded first.

    # Note: you can also move mlpm.json into src/ext/ and deploy plain modules (not REST extensions) that way.

    #deploy_packages
    original_deploy_modules
  end

  def deploy_packages
    password_prompt
    system %Q!mlpm deploy -u #{ @ml_username } \
                          -p #{ @ml_password } \
                          -H #{ @properties['ml.server'] } \
                          -P #{ @properties['ml.app-port'] }!
    change_permissions(@properties["ml.modules-db"])
  end

  def deploy_rest
    original_deploy_rest
    change_permissions(@properties["ml.modules-db"])
end

# Permissions need to be changed for executable code that was not deployed via Roxy directly,
  # to make sure users with app-role can read and execute it. Typically applies to artifacts
  # installed via REST api, which only applies permissions for rest roles. Effectively also includes
  # MLPM, which uses REST api for deployment. It often also applies to artifacts installed with
  # custom code (via app_specific for instance), like alerts.
  def change_permissions(where)
    logger.info "Changing permissions in #{where} for:"
    r = execute_query(
      %Q{
        xquery version "1.0-ml";
        let $new-permissions := (
          xdmp:permission("#{@properties["ml.app-name"]}-role", "read"),
          xdmp:permission("#{@properties["ml.app-name"]}-role", "update"),
          xdmp:permission("#{@properties["ml.app-name"]}-role", "execute")
        )
        let $uris :=
          if (fn:contains(xdmp:database-name(xdmp:database()), "content")) then
            (: This is to make sure all alert files are accessible :)
            cts:uri-match("*alert*")
          else
            (: This is to make sure all triggers, schemas, modules and REST extensions are accessible :)
            cts:uris()
        let $fixes :=
          for $uri in $uris
          let $existing-permissions := xdmp:document-get-permissions($uri)

          (: Only apply new permissions if really necessary (gives better logging too):)
          where not(ends-with($uri, "/"))
            and count($existing-permissions[fn:string(.) = $new-permissions/fn:string(.)]) ne 3

          return (
            "  " || $uri,
            xdmp:document-set-permissions($uri, $new-permissions)
          )
        return
          if ($fixes) then
            $fixes
          else
            "  no changes needed.."
      },
      { :db_name => where }
    )
    r.body = parse_json r.body
    logger.info r.body
    logger.info ""
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
  def execute_query_8(query, properties = {})
    if properties[:app_name] != nil && properties[:app_name] != @properties["ml.app-name"]
      raise ExitException.new("Executing queries with an app_name (currently) not supported with ML8+")
    end

    headers = {
      "Content-Type" => "application/x-www-form-urlencoded"
    }

    params = {
      :locale => LOCALE,
      :tzoffset => "-18000"
    }

    port = @qconsole_port
    if properties[:app_name] != nil
      params[:xquery] = %Q{
        xquery version "1.0-ml";
        let $query := <query><![CDATA[#{query}]]></query>
        return xdmp:eval(
          string($query),
          (),
          <options xmlns="xdmp:eval">
            <database>{xdmp:database("#{@properties["ml.content-db"]}")}</database>
            <modules>{xdmp:database("#{@properties["ml.modules-db"]}")}</modules>
          </options>
        )
      }
    else
      params[:xquery] = query
    end
    if properties[:db_name] != nil
      params[:database] = properties[:db_name]
    end

    r = go "#{@protocol}://#{@hostname}:#{port}/v1/eval", "post", headers, params

    raise ExitException.new(JSON.pretty_generate(JSON.parse(r.body))) if r.body.match(/\{"error"/)

    r
  end


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
