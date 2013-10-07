class Foobar < ActiveRecord::Base
  include AbleToFailOnPurpose
  belongs_to :bar
  belongs_to :foo
  belongs_to :barfoo
  belongs_to :foobar

  accepts_nested_attributes_for :foo
end
