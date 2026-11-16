require "rails_helper"

RSpec.describe "Sessions API", type: :request do
  let(:json) { response.parsed_body }
  let!(:user) { create(:user, name: "Priya HR", email: "priya@acme.test", password: "correct-horse-battery") }

  it "signs in with the right email and password and returns the user" do
    post "/api/v1/session", params: { email: "PRIYA@acme.test", password: "correct-horse-battery" }

    expect(response).to have_http_status(:created)
    expect(json["data"]).to eq("id" => user.id, "name" => "Priya HR", "email" => "priya@acme.test",
                               "role" => "hr_manager", "can_edit" => true)
    expect(json["data"]).not_to have_key("password_digest")
  end

  it "rejects a wrong password with the same message as an unknown email" do
    post "/api/v1/session", params: { email: "priya@acme.test", password: "wrong-password" }
    wrong_password = json["error"]
    post "/api/v1/session", params: { email: "nobody@acme.test", password: "wrong-password" }

    expect(response).to have_http_status(:unauthorized)
    expect(json["error"]).to eq(wrong_password)
  end

  it "returns the current user while signed in" do
    sign_in(user)

    get "/api/v1/session"

    expect(response).to have_http_status(:ok)
    expect(json["data"]["email"]).to eq("priya@acme.test")
  end

  it "returns 401 when not signed in" do
    get "/api/v1/session"

    expect(response).to have_http_status(:unauthorized)
  end

  it "signs out" do
    sign_in(user)

    delete "/api/v1/session"
    expect(response).to have_http_status(:no_content)

    get "/api/v1/employees"
    expect(response).to have_http_status(:unauthorized)
  end

  it "sets an httpOnly, SameSite=Lax session cookie" do
    sign_in(user)

    cookie = Array(response.headers["Set-Cookie"]).join("\n")
    expect(cookie).to match(/_acme_salaries_session=/)
    expect(cookie).to match(/httponly/i)
    expect(cookie).to match(/samesite=lax/i)
  end
end
