module Actionizer
  module Actions
    module Common
      module Autoincluding

      private
        def autoinclude_extensions_for(action_sym)
          Array.wrap(Actionizer.autoincludes[action_sym]).reject{|k,v| k.blank? || v.blank?}.each do |obj|
            case obj
            when Symbol
              begin
                puts "#{self} autoincluding #{Actionizer.available_extensions[obj.to_sym]}"
                include Actionizer.available_extensions[obj.to_sym].constantize
              rescue NameError => e
                raise "Could not resolve extension module. Check Actionizer/self.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
              end
            when String
              begin
                puts "#{self} autoincluding #{obj}"
                include obj.constantize
              rescue NameError => e
                raise "Could not resolve extension module: #{obj}. Error: \n#{e.message}\n\n#{e.backtrace.join("\n")}"
              end
            else
              puts "#{self} autoincluding #{obj}"
              include obj
            end
          end
        end
      end
    end
  end
end
