get "/api/sessions" do |ctx|
    session = sessions.ensure(ctx)

    list = sessions.get_all_user_sessions(session.user_id)
    {sessions: list}.to_json
end

post "/api/sessions" do |ctx|
    user = ctx.params.json["username"].as(String)
    pass = ctx.params.json["pass"].as(String)

    result = sessions.login(user, pass)

    if result.nil?
        raise Decent::NotFoundException.new("The username or password is incorrect.")
    else
        {sessionID: result.id}.to_json
    end
end

get "/api/sessions/:id" do |ctx|
    session_id = ctx.params.url["id"].as(String)

    session = Decent::Session.retrieve(sessions.db, session_id)

    {session: session, user: session.user}.to_json
end

delete "/api/sessions/:id" do |ctx|
    session_id = ctx.params.url["id"].as(String)

    session = Decent::Session.retrieve(sessions.db, session_id)
    session.delete

    {}.to_json
end
