class Bar < ActiveRecord::Base
  has_many :foo
  belongs_to :foobar
end
