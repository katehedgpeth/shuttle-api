defmodule WollastonShuttlesWeb.PageController do
  use WollastonShuttlesWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
