defmodule WeatherDashboardWeb.TemperatureLiveTest do
  use WeatherDashboardWeb.ConnCase

  import Phoenix.LiveViewTest
  import WeatherDashboard.MeasurementsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_temperature(_) do
    temperature = temperature_fixture()
    %{temperature: temperature}
  end

  describe "Index" do
    setup [:create_temperature]

    test "lists all temperatures", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.temperature_index_path(conn, :index))

      assert html =~ "Listing Temperatures"
    end

    test "saves new temperature", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.temperature_index_path(conn, :index))

      assert index_live |> element("a", "New Temperature") |> render_click() =~
               "New Temperature"

      assert_patch(index_live, Routes.temperature_index_path(conn, :new))

      assert index_live
             |> form("#temperature-form", temperature: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#temperature-form", temperature: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.temperature_index_path(conn, :index))

      assert html =~ "Temperature created successfully"
    end

    test "updates temperature in listing", %{conn: conn, temperature: temperature} do
      {:ok, index_live, _html} = live(conn, Routes.temperature_index_path(conn, :index))

      assert index_live |> element("#temperature-#{temperature.id} a", "Edit") |> render_click() =~
               "Edit Temperature"

      assert_patch(index_live, Routes.temperature_index_path(conn, :edit, temperature))

      assert index_live
             |> form("#temperature-form", temperature: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#temperature-form", temperature: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.temperature_index_path(conn, :index))

      assert html =~ "Temperature updated successfully"
    end

    test "deletes temperature in listing", %{conn: conn, temperature: temperature} do
      {:ok, index_live, _html} = live(conn, Routes.temperature_index_path(conn, :index))

      assert index_live |> element("#temperature-#{temperature.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#temperature-#{temperature.id}")
    end
  end

  describe "Show" do
    setup [:create_temperature]

    test "displays temperature", %{conn: conn, temperature: temperature} do
      {:ok, _show_live, html} = live(conn, Routes.temperature_show_path(conn, :show, temperature))

      assert html =~ "Show Temperature"
    end

    test "updates temperature within modal", %{conn: conn, temperature: temperature} do
      {:ok, show_live, _html} = live(conn, Routes.temperature_show_path(conn, :show, temperature))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Temperature"

      assert_patch(show_live, Routes.temperature_show_path(conn, :edit, temperature))

      assert show_live
             |> form("#temperature-form", temperature: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#temperature-form", temperature: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.temperature_show_path(conn, :show, temperature))

      assert html =~ "Temperature updated successfully"
    end
  end
end
