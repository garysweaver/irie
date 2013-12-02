# example of a custom extension
::Irie.register_extension :boolean_params, '::Example::BooleanParams'

::Irie.configure do
  COMMON_EXTENSIONS = [:nil_params, :boolean_params]
  self.autoincludes.keys.each {|k| self.autoincludes[k] += COMMON_EXTENSIONS }
end
