require "ejabberd_rest/errors"

module EjabberdRest
  class Client
    attr_accessor :http_adapter, :mod_rest_url

    DEFAULT_MOD_REST_URL = "http://localhost:5285"

    def initialize(attributes={})
      @mod_rest_url = attributes[:url] || DEFAULT_MOD_REST_URL
      @http_adapter = attributes[:http_adapter] || :net_http
    end

    def add_user(username, domain, password)
      rbody = post("/rest", body: "register #{username} #{domain} #{password}")

      if rbody.include?("successfully registered")
        true
      else
        if rbody.include?("already registered")
          raise Error::UserAlreadyRegistered
        else
          false
        end
      end
    end

    def delete_user(username, domain)
      post("/rest", body: "unregister #{username} #{domain}")
    end

  private

    def connection
      connection = Faraday.new(@mod_rest_url) do |builder|
        builder.request  :url_encoded
        builder.response :logger

        builder.adapter @http_adapter
      end
    end

    def post(path, options)
      response = connection.send(:post, path) do |request|
        request.body = options[:body] if options[:body]
      end

      response.body
    end
  end
end