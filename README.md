
# Alert_In_UA Twitter Notifier

https://alerts.in.ua/

## Requirements

* Alerts in UA API key: https://alerts.in.ua/
  * Fill out the form to get your API key
* Twitter Secrets: https://developer.twitter.com/
  * Create a new app (v2)
  * Make sure `User authentication settings` are configured
  * Save API Key and Secret
* Generate User's Access Token
  * `TWITTER_CONSUMER_KEY= TWITTER_CONSUMER_SECRET= bin/generate_access_token`
  * Follow on-screen instructions
* Save `TWITTER_ACCESS_TOKEN` and `TWITTER_ACCESS_SECRET` values
* Database: sqlite or postgres. Set `DATABASE_URL` See `db.rb` for more
  * Sqlite: `DATABASE_URL='sqlite://alerts.db'`
  * Postgres: `DATABASE_URL='postgres://user:password@host:port/database_name'`

## Tweeting Updates

```
export ALERTS_IN_UA_TOKEN= 
export TWITTER_CONSUMER_KEY= 
export TWITTER_CONSUMER_SECRET= 
export TWITTER_ACCESS_TOKEN= 
export TWITTER_ACCESS_SECRET= 

bin/alert_twitter
```

