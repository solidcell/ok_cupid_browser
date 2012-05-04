require 'sqlite3'
require "#{File.expand_path(File.dirname(__FILE__))}/../includes/initializer.rb"

class Database
  attr_accessor :db_connection

  def puts msg
    super(msg) if ENV['SIN_VERBOSE'] && ENV['SIN_VERBOSE'].to_i > 1
  end

  def initialize(existing_connection = nil)
    self.db_connection = existing_connection ||
      SQLite3::Database.new( "#{ROOT_PATH}/db/okcupid.db" )
  end

  def execute query, prepared_params = []
    puts "Query: #{query}"
    puts "Prepared Params: #{prepared_params}"

    result = nil
    begin
      result = if prepared_params && prepared_params.any?
        self.db_connection.execute(query,*prepared_params)
      else
        self.db_connection.execute(query)
      end
    rescue Exception => e
      puts "Failed to execute against db #{query}, #{prepared_params.inspect} -> #{e}"
    end

    result || false
  end

  def migrate!
    [
      "CREATE TABLE IF NOT EXISTS profiles (
        username varchar(128) NOT NULL PRIMARY KEY,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        location Varchar(128) DEFAULT NULL,
        sex Varchar(16),
        age INTEGER,
        orientation Varchar(64),
        body_type Varchar(64),
        status Varchar(64) )",
      "CREATE TABLE IF NOT EXISTS pictures (
        username varchar(128) NOT NULL,
        size varchar(32) NOT NULL,
        url varchar(256) NOT NULL)",
      "CREATE TABLE IF NOT EXISTS raw_profiles (
        username varchar(128) NOT NULL,
        page TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
        "CREATE TABLE IF NOT EXISTS hidden_profiles (
          username varchar(128) NOT NULL,
          profiles text NOT NULL)",
          "CREATE TABLE IF NOT EXISTS registered_users (
            username varchar(128) NOT NULL)",
      "PRAGMA encoding = 'UTF-8'"
    ].each { |query| execute query }
  end
end

if ARGV.any? && "setup" == ARGV[0]
  puts "Setting up database ..."
  Database.new.migrate!
  puts "Completed!"
end
