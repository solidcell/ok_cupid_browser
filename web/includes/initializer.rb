root_path = "#{File.expand_path(File.dirname(__FILE__))}/.."

require "#{root_path}/lib/database.rb"
require "#{root_path}/lib/ok_cupid.rb"

# -- Custom Modifications

class Object
  def blank?
    self.nil? || self.empty?
  end
end

# a handy debug method that only prints in non production environments
def puts msg
  super("DEBUG:: #{msg}") unless ENV['SIN_VERBOSE']
end