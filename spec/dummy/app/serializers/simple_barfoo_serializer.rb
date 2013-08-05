class SimpleBarfooSerializer < ActiveModel::Serializer
  attributes :id, :favorite_food
  has_many :foobars
end
