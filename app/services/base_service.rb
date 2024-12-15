# frozen_string_literal: true

# app/services/base_service.rb
class BaseService
  def self.call(*, &)
    new(*, &).call
  end

  def initialize(*args); end
end
