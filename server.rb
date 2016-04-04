require "sinatra"

get "/" do
  erb :index
end

get "/twitch" do
  erb :twitch, locals: { params: params, request: request }
end
