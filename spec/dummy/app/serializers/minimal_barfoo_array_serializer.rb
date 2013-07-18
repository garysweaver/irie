class MinimalBarfooArraySerializer < ActiveModel::ArraySerializer
  self.root = false
end
