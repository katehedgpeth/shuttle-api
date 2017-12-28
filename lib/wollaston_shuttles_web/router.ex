defmodule WollastonShuttlesWeb.Router do
  use WollastonShuttlesWeb, :router

  pipeline :browser do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
    plug :allow_origin
    # plug :protect_from_forgery
    # plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WollastonShuttlesWeb do
    pipe_through :browser # Use the default browser stack

    get "/schedules", SchedulesController, :index
    get "/vehicles", VehiclesController, :index
    get "/shapes", ShapesController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", WollastonShuttlesWeb do
  #   pipe_through :api
  # end
  def allow_origin(conn, _) do
    [origin] = get_req_header(conn, "origin")
    conn
    |> put_resp_header("access-control-allow-origin", origin)
  end
end
