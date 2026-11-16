# An HR staff member who can sign in. Managers change salary data; viewers can only read it.
class User < ApplicationRecord
  has_secure_password

  enum :role, { hr_manager: "hr_manager", viewer: "viewer" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 10 }, allow_nil: true

  def can_edit?
    hr_manager?
  end
end
