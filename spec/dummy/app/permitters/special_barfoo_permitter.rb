class SpecialBarfooPermitter < ActionController::Permitter
  permit :id, :favorite_food
end
