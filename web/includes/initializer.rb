unless defined? ROOT_PATH
  ROOT_PATH = "#{File.expand_path(File.dirname(__FILE__))}/../"
end # define this if we are not running in config.ru

require "#{ROOT_PATH}/lib/database.rb"
require "#{ROOT_PATH}/lib/ok_cupid.rb"

# -- Custom Modifications

class Object
  def blank?
    self.nil? || self.empty?
  end
end

# a handy debug method that only prints in non production environments
def puts msg
  super("DEBUG:: #{msg}") if ENV['SIN_VERBOSE']
end
