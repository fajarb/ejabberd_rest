require "ejabberd_rest/errors"
require "securerandom"

module EjabberdRest
  class Client
    attr_accessor :debug, :max_concurrency, :mod_rest_url

    DEFAULT_MOD_REST_URL = "http://localhost:5285"

    def initialize(attributes={})
      mod_rest_url = attributes[:url] || DEFAULT_MOD_REST_URL
      debug        = attributes[:debug] || false
      max_concurrency = attributes[:max_concurrency] || 100

      manager = Typhoeus::Hydra.new(max_concurrency: 100)
      @connection = Faraday.new(mod_rest_url, parallel_manager: manager) do |builder|
        builder.request  :url_encoded
        builder.response :logger if debug
        builder.adapter  :typhoeus
      end
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

    def post_stanza(stanza)
      post("/rest", body: stanza)
    end

    def modify_affiliations(from_jid, host, node, affiliations = {})
      stanza =  "<iq type='set' from='#{from_jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>"
      stanza <<     "<affiliations node='#{node}'>"
      affiliations.each do |k,v|
        stanza <<     "<affiliation jid='#{k}' affiliation='#{v}' />"
      end
      stanza <<     "</affiliations>"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
    end

    def pubsub_delete_node(from_jid, host, node)
      stanza =  "<iq type='set' from='#{from_jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>"
      stanza <<     "<delete node='#{node}'/>"
      stanza <<   "</pubsub>"
      stanza << "</iq>"
    end

    def pubsub_publish(from_jid, host, node, message)
      stanza =  "<iq type='set' from='#{from_jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<publish node='#{node}'>"
      stanza <<       "<item id='#{SecureRandom.uuid}'>"
      stanza <<         "#{message}"
      stanza <<       "</item>"
      stanza <<     "</publish>"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
    end

    def pubsub_subscribe_all_resources(jid, pubsub_service, node, resources)
      @connection.in_parallel do
        resources.each do |r|
          post("/rest", body: subscribe_stanza(jid, pubsub_service, node, r))
        end
      end
    end

    def pubsub_unsubscribe(jid, host, node, resource)
      stanza =  "<iq type='set' from='#{jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<unsubscribe node='#{node}' jid='#{jid}/#{resource}' />"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
    end

    def subscribe_stanza(jid, pubsub_service, node, resource)
      stanza =  "<iq type='set' from='#{jid}' to='#{pubsub_service}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<subscribe node='#{node}' jid='#{jid}/#{resource}' />"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      stanza
    end


  private

    def post(path, options={})
      @connection.post do |req|
        req.url path
        req.options[:timeout] = 60
        req.body = options[:body] if options[:body]
      end
    end

  end
end