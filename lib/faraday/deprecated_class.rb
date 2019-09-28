# frozen_string_literal: true

module Faraday
  # @param old_klass [String] Old Namespaced Class
  # @param new_klass [Class] New Class that the caller should use instead
  #
  # @return [Class] A modified version of new_klass that warns on
  #   usage about deprecation.
  module DeprecatedClass
    def self.proxy_class(old_klass, new_klass)
      Class.new(new_klass).tap do |k|
        k.send(:define_method, :initialize) do |*args, &block|
          @old_klass = old_klass
          @new_klass = new_klass
          warn
          super(*args, &block)
        end

        k.send(:define_method, :warn) do
          puts(
            "DEPRECATION WARNING: #{@old_klass} is deprecated! " \
            "Use #{@new_klass} instead."
          )
        end
      end
    end
  end
end
