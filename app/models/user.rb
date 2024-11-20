class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy

  validates :full_name, presence: true, length: { minimum: 10, maximum: 50 }
  validates :email, presence: true, uniqueness: true
end
