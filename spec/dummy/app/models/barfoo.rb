class Barfoo < ActiveRecord::Base
  include AbleToFailOnPurpose

  validates :favorite_food, length: { maximum: 15 }
end
