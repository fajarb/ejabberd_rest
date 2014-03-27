require "ejabberd_rest/errors"
require "securerandom"

module EjabberdRest
  class Client
    attr_accessor :debug, :http_adapter, :mod_rest_url

    DEFAULT_MOD_REST_URL = "http://localhost:5285"

    def initialize(attributes={})
      @mod_rest_url = attributes[:url] || DEFAULT_MOD_REST_URL
      @http_adapter = attributes[:http_adapter] || :net_http
      @debug        = attributes[:debug] || false
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

    def create_one_to_one_node(from_jid, host, node)
      stanza =  "<iq type='set' from='#{from_jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<create node='#{node}'/>"
      stanza <<     "<configure>"
      stanza <<       "<x xmlns='jabber:x:data' type='submit'>"
      stanza <<         "<field var='FORM_TYPE' type='hidden'>"
      stanza <<           "<value>http://jabber.org/protocol/pubsub#node_config</value>"
      stanza <<         "</field>"
      stanza <<         "<field var='pubsub#access_model'><value>whitelist</value></field>"
      stanza <<         "<field var='pubsub#persist_items'><value>1</value></field>"
      stanza <<         "<field var='pubsub#notify_sub'><value>1</value></field>"
      stanza <<         "<field var='pubsub#title'><value>Untitled</value></field>"
      stanza <<         "<field var='pubsub#notification_type'><value>normal</value></field>"
      stanza <<         "<field var='pubsub#send_last_published_item'><value>never</value></field>"
      stanza <<       "</x>"
      stanza <<     "</configure>"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
    end

    def create_multiuser_node(from_jid, host, node)
      stanza =  "<iq type='set' from='#{from_jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<create node='#{node}'/>"
      stanza <<     "<configure>"
      stanza <<       "<x xmlns='jabber:x:data' type='submit'>"
      stanza <<         "<field var='FORM_TYPE' type='hidden'>"
      stanza <<           "<value>http://jabber.org/protocol/pubsub#node_config</value>"
      stanza <<         "</field>"
      stanza <<         "<field var='pubsub#publish_model'><value>open</value></field>"
      stanza <<         "<field var='pubsub#persist_items'><value>1</value></field>"
      stanza <<         "<field var='pubsub#notify_sub'><value>1</value></field>"
      stanza <<         "<field var='pubsub#title'><value>Untitled</value></field>"
      stanza <<         "<field var='pubsub#notification_type'><value>normal</value></field>"
      stanza <<         "<field var='pubsub#send_last_published_item'><value>never</value></field>"
      stanza <<       "</x>"
      stanza <<     "</configure>"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
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

    def pubsub_subscribe(jid, host, node, resource)
      stanza =  "<iq type='set' from='#{jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<subscribe node='#{node}' jid='#{jid}/#{resource}' />"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
    end

    def pubsub_unsubscribe(jid, host, node, resource)
      stanza =  "<iq type='set' from='#{jid}' to='#{host}' id='#{SecureRandom.uuid}'>"
      stanza <<   "<pubsub xmlns='http://jabber.org/protocol/pubsub'>"
      stanza <<     "<unsubscribe node='#{node}' jid='#{jid}/#{resource}' />"
      stanza <<   "</pubsub>"
      stanza << "</iq>"

      post_stanza(stanza)
    end

  private

    def connection
      connection = Faraday.new(@mod_rest_url) do |builder|
        builder.request  :url_encoded
        builder.response :logger if @debug

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