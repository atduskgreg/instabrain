require 'dm-core'
require 'dm-timestamps'
require 'instapaper'

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_IVORY_URL'] || 'postgres://localhost/instabrain')

class BadInstapaperCredentials < Exception; end

class Article
    include DataMapper::Resource
    property :id, Serial

    property :instapaper_id, String
    property :title, Text
    property :url, Text
    property :body, Text
    property :last_synced_at, DateTime 

    belongs_to :user

    def self.import_bookmark( mark, user ) # this is a Hashie::Rash
      existing_marks = self.all(:instapaper_id => mark.bookmark_id)
      
      if existing_marks.empty?
        article = Article.new
        article.instapaper_id = mark.bookmark_id
        article.title = mark.title
        article.url = mark.url
        article.user_id = user.id
        article.save

        return article
      else 
        return existing_marks[0]
      end
    end

    def fetch_body!
      user.configure_instapaper

      self.body = Instapaper.text(self.instapaper_id)
      self.last_synced_at = DateTime.now
      self.save
    end
end

class User
  include DataMapper::Resource
  
  property :id, Serial
  property :username, String
  property :oauth_token, String
  property :oauth_token_secret, String

  has n, :articles

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