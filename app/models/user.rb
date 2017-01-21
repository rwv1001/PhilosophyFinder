class User < ApplicationRecord
  has_secure_password(validations: false)
  has_many :domain_crawlers

  validates_uniqueness_of :email, unless: :guest?
  validates_presence_of :password, :on => :create, unless: :guest?

  before_create { generate_token(:auth_token) }
  def self.new_guest
    logger.info "*** calling self.new_guest"
    new_guest_user = User.new
    new_guest_user.guest = true
    new_guest_user.save!


    return new_guest_user

  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end
end
