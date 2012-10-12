ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :foobars do |t|
    t.string :foo_id
    t.datetime :foo_date
    t.datetime :bar_date
  end
end
