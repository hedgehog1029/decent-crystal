get "/api" do |ctx|
    next {decentVersion: "0.1.0"}.to_json
end

get "/api/settings" do |ctx|
    {settings: ctx.settings}.to_json
end

post "/api/settings" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin
    results = {} of String => String

    if ctx.params.json.has_key?("name")
        ctx.settings.name = ctx.params.json["name"].as(String)
        results["name"] = "updated"
    end

    if ctx.params.json.has_key?("authorizationMessage")
        ctx.settings.authorizationMessage = ctx.params.json["authorizationMessage"].as(String)
        results["authorizationMessage"] = "updated"
    end

    {results: results}.to_json
end

get "/api/properties" do |ctx|
    {properties: ctx.decent_config}.to_json
end
