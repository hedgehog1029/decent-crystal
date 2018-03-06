module Decent
    class ServerSettings
        JSON.mapping(
            name: String,
            authorizationMessage: String
        )

        def initialize(@name : String, @authorizationMessage : String)
        end
    end
end
