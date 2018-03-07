module Decent
    class ApiHandler < Kemal::Handler
        def call(ctx)
            if ctx.request.path.starts_with?("/api")
                ctx.response.content_type = "application/json"

                begin
                    return call_next(ctx)
                rescue ex : Decent::ApiException
                    res = {error: ex}.to_json
                rescue ex : Exception
                    error = {code: "UNKNOWN", message: ex.message}
                    res = {error: error}.to_json
                end

                ctx.response.status_code = 500
                ctx.response.print res
                ctx.response.close
            end

            return call_next(ctx)
        end
    end

    class SessionHandler < Kemal::Handler
        def call(ctx)
            session_id = ctx.params.json["sessionID"]? ||
                ctx.params.query["sessionID"]? ||
                ctx.request.headers["X-Session-ID"]?

            ctx.set("session_id", session_id.as(String))
        end
    end
end
