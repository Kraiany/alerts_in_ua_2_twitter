require 'oauth'
require 'json'
require 'typhoeus'
require 'twitter'
require 'oauth/request_proxy/typhoeus_request'

class AlertInUa2Twitter
  class Tweeter
    CREATE_TWEET_URL = "https://api.twitter.com/2/tweets"
    attr_reader :consumer_key, :consumer_secret, :access_token

    def initialize(key, secret, access_token = nil, access_secret = nil)
      @consumer_key = key
      @consumer_secret = secret
      if access_token && access_secret
        @access_token = OAuth::AccessToken.new(consumer, access_token, access_secret)
      end
    end

    def get_access_token
      # PIN-based OAuth flow - Step 1
      request_token = get_request_token
      # PIN-based OAuth flow - Step 2
      pin = get_user_authorization(request_token)
      # PIN-based OAuth flow - Step 3
      @access_token = obtain_access_token(consumer, request_token, pin)
      puts "TWITTER_ACCESS_TOKEN=#{@access_token.token}"
      puts "TWITTER_ACCESS_SECRET=#{@access_token.secret}"
      @access_token
    end

    def payload(message, media_id = nil)
      pl = {"text": message}
      pl.merge!({"media": {"media_ids": [media_id]}}) if media_id
      pl
    end

    def consumer
      @consumer ||= OAuth::Consumer.new(consumer_key, consumer_secret,
                                          :site => 'https://api.twitter.com',
                                          :authorize_path => '/oauth/authenticate',
                                          :debug_output => false)
    end

    def get_request_token
      consumer.get_request_token()
    end

    def get_user_authorization(request_token)
      puts "Follow this URL to have a user authorize your app: #{request_token.authorize_url()}"
      puts "Enter PIN: "
      gets.strip
    end

    def obtain_access_token(consumer, request_token, pin)
      token = request_token.token
      token_secret = request_token.secret
      hash = { :oauth_token => token, :oauth_token_secret => token_secret }
      request_token  = OAuth::RequestToken.from_hash(consumer, hash)

      request_token.get_access_token({:oauth_verifier => pin})
    end

    def create_tweet(message, image_path = nil)
      media_id = (image_path ? upload_photo_to_twitter(image_path) : nil)
      options = {
          :method => :post,
          headers: {
            "User-Agent": "AlertInUa2Twitter #{VERSION}",
            "content-type": "application/json"
          },
          body: JSON.dump(payload(message, media_id))
      }
      request = Typhoeus::Request.new(CREATE_TWEET_URL, options)
      oauth_helper = OAuth::Client::Helper.new(request, {
        consumer: consumer, token: access_token, request_uri: CREATE_TWEET_URL
      })
      request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
      result = request.run
      raise "Not successful (#{result.response_code}) #{result.body}" if result.response_code != 201
      result
    end

    def upload_photo_to_twitter(file_path)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = @consumer_key
        config.consumer_secret     = @consumer_secret
        config.access_token        = @access_token.token
        config.access_token_secret = @access_token.secret
      end

      begin
        media = client.send(:upload, File.new(file_path))
        puts "Image uploaded to Twitter: #{media.inspect}"
        return media.fetch(:media_id_string, nil)
      rescue Exception => e
        puts "An error occurred while uploading the photo to Twitter: #{e.message}"
        return nil
      end
    end
  end
end
