defmodule WeatherDashboardWeb.Router do
  use WeatherDashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {WeatherDashboardWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WeatherDashboardWeb do
    pipe_through :browser

    live "/", TemperatureLive.Index
  end

  # Other scopes may use custom stacks.
  # scope "/api", WeatherDashboardWeb do
  #   pipe_through :api
  # end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
