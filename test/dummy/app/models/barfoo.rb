class Barfoo < ActiveRecord::Base
  include AbleToFailOnPurpose
  has_many :foobars
  has_one :foo
  validates :favorite_food, length: { maximum: 15 }
end
