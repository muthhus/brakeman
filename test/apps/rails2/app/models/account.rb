class Account < ActiveRecord::Base
  validates_format_of :name, :with => /^[a-zA-Z]+$/
end
