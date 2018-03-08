module Decent
    class Client
        @session : Decent::Session?

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
            send {evt: "pingdata"}
        end

        def on_message(message : String)
            payload = JSON.parse(message)
            event = payload["evt"].as_s

            if event == "pongdata"
                session_id = payload["data"]["sessionID"].as_i
                @session = Repo.get(Decent::Session, session_id)
            end
        end
    end

    class SocketHolder
        def initialize
            @clients = [] of Client
        end

        def new_socket(socket : HTTP::WebSocket)
            client = Client.new socket
            @clients << client
        end

        def broadcast(message : Object)
            text = message.to_json

            @clients.each do |c|
                c.send(text)
            end
        end
    end
end
