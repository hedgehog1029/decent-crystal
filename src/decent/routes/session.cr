get "/api/sessions" do |ctx|
    session = ctx.ensure_session

    list = ctx.sessions.get_all_user_sessions(session.user_id)
    {sessions: list}.to_json
end

post "/api/sessions" do |ctx|
    user = ctx.params.json["username"].as(String)
    pass = ctx.params.json["pass"].as(String)

    result = ctx.sessions.login(user, pass)

    if result.nil?
        raise Decent::NotFoundException.new("The username or password is incorrect.")
    else
        {sessionID: result.id}.to_json
    end
end

get "/api/sessions/:id" do |ctx|
    session_id = ctx.params.url["id"].as(String)

    session = Decent::Session.retrieve(ctx.db, session_id)

    {session: session, user: session.user}.to_json
end

delete "/api/sessions/:id" do |ctx|
    session_id = ctx.params.url["id"].as(String)

    session = Decent::Session.retrieve(ctx.db, session_id)
    session.delete

    Decent.empty_json
end
