# Serves the built React app for client-side routes (e.g. /employees, /insights) so deep links
# and page refreshes work. Static assets are served directly from public/ by Rails.
class SpaController < ActionController::API
  def index
    index_file = Rails.public_path.join("index.html")
    if index_file.exist?
      send_file index_file, type: "text/html", disposition: "inline"
    else
      render plain: "Frontend not built. Run the Vite dev server or build it into backend/public.",
             status: :not_found
    end
  end
end
