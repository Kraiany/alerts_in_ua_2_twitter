require 'sequel'
require 'sqlite3'
require 'pg'

if database_url = ENV['DATABASE_URL']
  $db = Sequel.connect(database_url)
else
  $db = Sequel.sqlite
end
$db.create_table?(:alerts) do
  primary_key :id
  String :location_title
  String :location_type
  DateTime :started_at
  DateTime :finished_at
  DateTime :updated_at
  String :alert_type
  String :location_uid
  String :location_oblast
  String :location_raion
  String :notes
  TrueClass :calculated
  String :state
end
