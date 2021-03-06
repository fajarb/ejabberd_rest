require "ejabberd_rest/errors"
require "securerandom"

module EjabberdRest
  class Client
    attr_accessor :debug, :max_concurrency, :mod_rest_url

    DEFAULT_MOD_REST_URL = "http://localhost:5285"

    def initialize(url=DEFAULT_MOD_REST_URL, options={})
      manager = Typhoeus::Hydra.new(max_concurrency: options[:max_concurrency] || 25)

      @connection = Faraday.new(url, parallel_manager: manager) do |builder|
        builder.request  :url_encoded
        builder.response :logger if options[:debug]
        builder.adapter  :typhoeus
        builder.options.timeout = options[:timeout] || 3
        builder.options.open_timeout = options[:open_timeout] || 1
      end
    end

    def add_user(username, domain, password)
      response = post("/rest", body: "register #{username} #{domain} #{password}")

      if response.status >= 400
        raise Error::RequestFailed, "HTTP Status: #{response.status}"
      else
        if response.body.include?("successfully registered")
          true
        else
          if response.body.include?("already registered")
            raise Error::UserAlreadyRegistered
          else
            raise Error::UnknownError, response.body
          end
        end
      end
    end

    def delete_user(username, domain)
      post("/rest", body: "unregister #{username} #{domain}")
    end

    def post_stanza(stanza)
      post("/rest", body: stanza)
    end

    def post_all_stanzas(stanzas)
      @connection.in_parallel do
        stanzas.each do |stanza|
          post_stanza(stanza)
        end
      end
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

      post_stanza(stanza)
    end

    def pubsub_item_stanza(from_jid, host, node, message)
      stanza =  "<iq type='set' from='#{from_jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<publish node='#{node}'>"
      stanza <<       "<item id='#{SecureRandom.uuid}'>"
      stanza <<         "#{message}"
      stanza <<       "</item>"
      stanza <<     "</publish>"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      stanza
    end

    def pubsub_publish(from_jid, host, node, message)
      post_stanza(pubsub_item_stanza(from_jid, host, node, message))
    end

    def pubsub_publish_all_items(from_jid, host, node, items)
      @connection.in_parallel do
        items.each do |item|
          pubsub_publish(from_jid, host, node, item)
        end
      end
    end

    def subscribe_stanza(jid, pubsub_service, node, resource)
      stanza =  "<iq type='set' from='#{jid}' to='#{pubsub_service}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<subscribe node='#{node}' jid='#{jid}/#{resource}' />"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      stanza
    end

    def pubsub_subscribe(jid, pubsub_service, node, resource)
      post_stanza(subscribe_stanza(jid, pubsub_service, node, resource))
    end

    def pubsub_subscribe_all_resources(jid, pubsub_service, node, resources)
      @connection.in_parallel do
        resources.each do |r|
          pubsub_subscribe(jid, pubsub_service, node, r)
        end
      end
    end

    def unsubscribe_stanza(jid, pubsub_service, node, resource)
      stanza =  "<iq type='set' from='#{jid}' to='#{pubsub_service}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<unsubscribe node='#{node}' jid='#{jid}/#{resource}' />"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      stanza
    end

    def pubsub_unsubscribe(jid, pubsub_service, node, resource)
      post_stanza(unsubscribe_stanza(jid, pubsub_service, node, resource))
    end

    def pubsub_unsubscribe_all_resources(jid, pubsub_service, node, resources)
      @connection.in_parallel do
        resources.each do |r|
          pubsub_unsubscribe(jid, pubsub_service, node, r)
        end
      end
    end


  private

    def post(path, options={})
      @connection.post do |req|
        req.url path
        req.body = options[:body] if options[:body]
      end
    end

  end
end