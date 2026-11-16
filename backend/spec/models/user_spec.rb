require "rails_helper"

RSpec.describe User do
  it "is valid from the factory" do
    expect(build(:user)).to be_valid
  end

  it "normalizes the email so sign-in is case-insensitive" do
    user = create(:user, email: "  Priya@ACME.test ")

    expect(user.email).to eq("priya@acme.test")
  end

  it "requires a unique email regardless of case" do
    create(:user, email: "priya@acme.test")

    duplicate = build(:user, email: "PRIYA@acme.test")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "requires a password of at least 10 characters" do
    user = build(:user, password: "short")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "never stores the plain password" do
    user = create(:user, password: "correct-horse-battery")

    expect(user.password_digest).not_to include("correct-horse-battery")
    expect(user.authenticate("correct-horse-battery")).to eq(user)
    expect(user.authenticate("wrong-password")).to be(false)
  end

  it "rejects an unknown role" do
    user = build(:user, role: "superuser")

    expect(user).not_to be_valid
    expect(user.errors[:role]).to be_present
  end

  it "lets only HR managers edit" do
    expect(build(:user).can_edit?).to be(true)
    expect(build(:user, :viewer).can_edit?).to be(false)
  end
end
