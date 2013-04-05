ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :foobars do |t|
    t.string :foo_id
    t.string :bar_id
    t.datetime :foo_date
    t.datetime :bar_date
  end

  create_table :barfoos do |t|
    t.string :status
    t.string :favorite_drink
    t.string :favorite_food
  end

  create_table :users do |t|
    t.string :role
  end
end
