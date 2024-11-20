# frozen_string_literal: true

class Currency < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
