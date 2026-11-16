# Signs in through the real endpoint, so request specs exercise the same session cookie the browser uses.
module AuthHelpers
  def sign_in(user = create(:user))
    post "/api/v1/session", params: { email: user.email, password: user.password }
    raise "sign-in failed: #{response.body}" unless response.status == 201

    user
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
