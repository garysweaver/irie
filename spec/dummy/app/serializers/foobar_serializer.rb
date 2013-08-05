class FoobarSerializer < ActiveModel::Serializer
  attributes :id, :foo_date, :bar_date
  has_one :foo
  has_one :bar
end
