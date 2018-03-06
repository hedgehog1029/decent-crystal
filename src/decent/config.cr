module Decent
    class Config
        YAML.mapping(
            useSecure: Bool,
            useAuthorization: Bool
        )

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "useSecure", @useSecure
                builder.field "useAuthorization", @useAuthorization
            end
        end
    end
end
