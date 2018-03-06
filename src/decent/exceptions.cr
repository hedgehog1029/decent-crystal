module Decent
    class ApiException < Exception
        def initialize(@code : String, message : String)
            super message
        end

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "code", @code
                builder.field "message", @message
            end
        end

        getter code
    end

    class NotFoundException < ApiException
        def initialize(message : String)
            super "NOT_FOUND", message
        end
    end

    class NotYoursException < ApiException
        def initialize(message : String)
            super "NOT_YOURS", message
        end
    end

    class MustBeAdminException < ApiException
        def initialize(message : String)
            super "MUST_BE_ADMIN", message
        end
    end

    class AlreadyPerformedException < ApiException
        def initialize(message : String)
            super "ALREADY_PERFORMED", message
        end
    end

    class IncompleteParametersException < ApiException
        def initialize(message : String)
            super "INCOMPLETE_PARAMETERS", message
        end
    end

    class InvalidParameterException < ApiException
        def initialize(message : String)
            super "INVALID_PARAMETER_TYPE", message
        end
    end
end
