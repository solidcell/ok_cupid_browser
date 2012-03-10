require 'rubygems'
require 'bundler'
require 'date'
require 'time'

Bundler.require

if ENV['MODE'] == "dev"
  require "sinatra/reloader"
else
  FileUtils.mkdir_p 'log' unless File.exists?('log')
  log = File.new("log/sinatra.log", "a")
  $stdout.reopen(log)
  $stderr.reopen(log)
end

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

require "#{ROOT_PATH}/web/okcupid_browser"
run OKCBrowser
