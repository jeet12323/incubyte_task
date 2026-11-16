# The signed-in user as the frontend sees it. Never includes the password digest.
module UserSerializer
  module_function

  def call(user)
    { id: user.id, name: user.name, email: user.email, role: user.role, can_edit: user.can_edit? }
  end
end
