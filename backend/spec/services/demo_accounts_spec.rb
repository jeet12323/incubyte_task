require "rails_helper"

RSpec.describe DemoAccounts do
  it "creates an HR manager and a viewer who can sign in with the demo password" do
    described_class.ensure!

    expect(User.find_by(email: "hr@acme.test").authenticate(DemoAccounts::PASSWORD)).to be_hr_manager
    expect(User.find_by(email: "viewer@acme.test").authenticate(DemoAccounts::PASSWORD)).to be_viewer
  end

  it "is safe to run again and doesn't reset a changed password" do
    described_class.ensure!
    User.find_by(email: "hr@acme.test").update!(password: "a-new-password-123")

    expect { described_class.ensure! }.not_to change(User, :count)
    expect(User.find_by(email: "hr@acme.test").authenticate("a-new-password-123")).to be_truthy
  end
end
