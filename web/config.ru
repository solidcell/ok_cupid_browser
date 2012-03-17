require 'rubygems'
require 'bundler'
require 'date'
require 'time'

Bundler.require

if ENV['SIN_MODE'] == "production"
  FileUtils.mkdir_p 'log' unless File.exists?('log')
  log = File.new("log/sinatra.log", "a")
  $stdout.reopen(log)
  $stderr.reopen(log)
else
  require "sinatra/reloader"
end

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

require "#{ROOT_PATH}/okcupid_browser"
run OKCBrowser