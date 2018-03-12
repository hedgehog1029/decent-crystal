module Decent
    class Client
        @session_id : String?

        def initialize(@socket : HTTP::WebSocket)
            @socket.on_message(&->self.on_message(String))

            spawn do
                self.ping
                sleep 10.seconds
            end
        end

        getter session

        def send(msg : String)
            @socket.send(msg)
        end

        def send(msg : Object)
            send msg.to_json
        end

        def ping
            send({evt: "pingdata"})
        end

        def on_message(message : String)
            payload = JSON.parse(message)
            event = payload["evt"].as_s

            if event == "pongdata"
                @session_id = payload["data"]["sessionID"].as_s?
            end

            nil
        end
    end

    class SocketHolder
        def initialize
            @clients = [] of Client
        end

        def new_socket(socket : HTTP::WebSocket)
            client = Client.new socket
            @clients << client

            socket.on_close {
                c = @clients.find { |s| s == socket }
                @clients.delete(c) unless c.nil?
            }
        end

        def broadcast(evt : String, **data)
            text = {evt: evt, data: data}.to_json

            @clients.each do |c|
                c.send(text)
            end
        end
    end
end
