require 'dm-core'
require 'dm-timestamps'
require 'instapaper'

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_IVORY_URL'] || 'postgres://localhost/instabrain')

class BadInstapaperCredentials < Exception; end

class User
  include DataMapper::Resource
  
  property :id, Serial
  property :username, String
  property :oauth_token, String
  property :oauth_token_secret, String

  def self.find_or_create(credentials)
    Instapaper.configure do |config|
      config.consumer_key = ENV['INSTABRAIN_CONSUMER_KEY']
      config.consumer_secret = ENV['INSTABRAIN_CONSUMER_SECRET']
    end
  
    result = Instapaper.access_token(credentials[:username], credentials[:password])

    if result.keys.include?("error")
      raise BadInstapaperCredentials
    end

    already_exists = User.all(:username => credentials[:username])

    if !already_exists.empty?
      return already_exists[0]
    else 

    return User.create :username => credentials[:username],
                       :oauth_token => result["oauth_token"],
                       :oauth_token_secret => result["oauth_token_secret"]
    end
  end

  def configure_instapaper
    Instapaper.configure do |config|
      config.consumer_key = ENV['INSTABRAIN_CONSUMER_KEY']
      config.consumer_secret = ENV['INSTABRAIN_CONSUMER_SECRET']
      config.oauth_token = oauth_token
      config.oauth_token_secret = oauth_token_secret
    end 
  end

  def bookmarks
    configure_instapaper

    Instapaper.bookmarks
  end

end

DataMapper.finalize