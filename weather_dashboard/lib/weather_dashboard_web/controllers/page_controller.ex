defmodule WeatherDashboardWeb.PageController do
  use WeatherDashboardWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
