module AbleToFailOnPurpose
  extend ActiveSupport::Concern
  included do
    before_save :possibly_fail
    before_destroy :possibly_fail
  end
  
  def possibly_fail
    if $error_to_raise_on_next_save_or_destroy_only != nil
      raiseable_obj = $error_to_raise_on_next_save_or_destroy_only
      # reset so will only happen once
      $error_to_raise_on_next_save_or_destroy_only = nil
      raise raiseable_obj
    end
  end
end
