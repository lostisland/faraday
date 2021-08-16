# frozen_string_literal: true

# emulates ActiveSupport::SafeBuffer#gsub
FakeSafeBuffer = Struct.new(:string) do
  def to_s
    self
  end

  def gsub(regex)
    string.gsub(regex) do
      match, = Regexp.last_match(0), '' =~ /a/
      yield(match)
    end
  end
end
