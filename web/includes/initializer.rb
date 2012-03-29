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
  super("DEBUG:: #{msg}") unless ENV['SIN_NONVERBOSE']
end
