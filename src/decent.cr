require "kemal"
require "sqlite3"
require "crecto"
require "json"
require "yaml"
require "openssl"
require "./decent/*"

add_handler Decent::ApiHandler.new
add_handler Decent::OptionsHandler.new
add_handler Decent::SessionHandler.new

get "/" do |ctx|
    index = File.join(Kemal.config.public_folder, "index.html")
    send_file ctx, index
end

ws "/" do |socket, ctx|
    ctx.sockets.new_socket(socket)
end

# == TEMPORARY PATCH ==

class HTTP::Server::Response
  class Output
    # original definition since Crystal 0.35.0
    def close
      return if closed?

      unless response.wrote_headers?
        response.content_length = @out_count
      end

      ensure_headers_written

      super

      if @chunked
        @io << "0\r\n\r\n"
        @io.flush
      end
    end

    # patch from https://github.com/kemalcr/kemal/pull/576
    def close
      # ameba:disable Style/NegatedConditionsInUnless
      unless response.wrote_headers? && !response.headers.has_key?("Content-Range")
        response.content_length = @out_count
      end

      ensure_headers_written

      previous_def
    end
  end
end

module Kemal
    class WebSocketHandler
        def call(context : HTTP::Server::Context)
            return call_next(context) unless context.ws_route_found? && websocket_upgrade_request?(context)
            context.websocket.call(context)
        end
    end
end

# == TEMPORARY PATCH END ==

require "./decent/routes/*"

# Kemal.config.logging = false
Kemal.config.port = 4040
Kemal.run
