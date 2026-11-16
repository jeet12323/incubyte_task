# Sign-in accounts for the hosted demo. The data is fictional, so the password is published on the
# login page for reviewers. A real deployment would use the company's SSO and create no demo accounts.
module DemoAccounts
  PASSWORD = "acme-demo-2026".freeze
  ACCOUNTS = [
    { name: "Hannah Reed (HR Manager)", email: "hr@acme.test", role: "hr_manager" },
    { name: "Victor Shah (Viewer)", email: "viewer@acme.test", role: "viewer" }
  ].freeze

  module_function

  # Creates any missing demo account. Existing accounts are left alone, so it is safe on every deploy.
  def ensure!
    ACCOUNTS.each do |attributes|
      User.find_or_create_by!(email: attributes[:email]) do |user|
        user.assign_attributes(attributes.merge(password: PASSWORD))
      end
    end
  end
end
