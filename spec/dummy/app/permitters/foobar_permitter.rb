class FoobarPermitter < ActionController::Permitter
  permit :id, :foo_id
end
