require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require './models'

get "/" do
	erb :signup
end

post "/users" do
	credentials = {:username => params[:username], :password => params[:password]}
	begin
		user = User.find_or_create(credentials)
		redirect to("/users/#{user.id}")
	rescue BadInstapaperCredentials => e
		redirect to("/")
	end
end

get "/users/:id" do
	@user = User.get params[:id]
	erb :user
end