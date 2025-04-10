class JsonWebToken
  SECRET_KEY = ENV["JWT_SECRET"]

  def self.decode(token)
    decoded_value = JWT.decode token, SECRET_KEY
    HashWithIndifferentAccess.new(decoded_value)
  rescue
    nil
  end
end
