defmodule WeatherDashboardWeb.TemperatureLive.Index do
  use WeatherDashboardWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    reports = []
    emqtt_opts = Application.get_env(:weather_dashboard, :emqtt)
    {:ok, pid} = :emqtt.start_link(emqtt_opts)
    {:ok, _} = :emqtt.connect(pid)
    # Listen reports
    {:ok, _, _} = :emqtt.subscribe(pid, "reports/#")
    {:ok, assign(socket,
      reports: reports,
      pid: pid,
      plot: nil,
      interval: nil
    )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("set-interval", %{"interval" => interval_s}, socket) do
    case Integer.parse(interval_s) do
      {interval, ""} ->
        id = Application.get_env(:weather_dashboard, :sensor_id)
        # Send command to device
        topic = "commands/#{id}/set_interval"
        :ok = :emqtt.publish(
          socket.assigns[:pid],
          topic,
          interval_s,
          retain: true
        )
        {:noreply, assign(socket, interval: interval)}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(name, data, socket) do
    Logger.info("handle_event: #{inspect([name, data])}")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:publish, packet}, socket) do
    handle_publish(parse_topic(packet), packet, socket)
  end

  defp handle_publish(["reports", id, "temperature"], %{payload: payload}, socket) do
    if id == Application.get_env(:weather_dashboard, :sensor_id) do
      report = :erlang.binary_to_term(payload)
      {reports, plot} = update_reports(report, socket)
      {:noreply, assign(socket, reports: reports, plot: plot)}
    else
      {:noreply, socket}
    end
  end

  defp update_reports({ts, val}, socket) do
    new_report = {DateTime.from_unix!(ts, :millisecond), val}
    now = DateTime.utc_now()
    deadline = DateTime.add(DateTime.utc_now(), - 2 * Application.get_env(:weather_dashboard, :timespan), :second)
    reports =
      [new_report | socket.assigns[:reports]]
      |> Enum.filter(fn {dt, _} -> DateTime.compare(dt, deadline) == :gt end)
      |> Enum.sort()

    {reports, plot(reports, deadline, now)}
  end

  defp parse_topic(%{topic: topic}) do
    String.split(topic, "/", trim: true)
  end

  defp plot(reports, deadline, now) do
    x_scale =
      Contex.TimeScale.new()
      |> Contex.TimeScale.domain(deadline, now)
      |> Contex.TimeScale.interval_count(10)

    y_scale =
      Contex.ContinuousLinearScale.new()
      |> Contex.ContinuousLinearScale.domain(0, 30)

    options = [
      smoothed: false,
      custom_x_scale: x_scale,
      custom_y_scale: y_scale,
      custom_x_formatter: &x_formatter/1,
      axis_label_rotation: 45
    ]

    reports
    |> Enum.map(fn {dt, val} -> [dt, val] end)
    |> Contex.Dataset.new()
    |> Contex.Plot.new(Contex.LinePlot, 600, 250, options)
    |> Contex.Plot.to_svg()
  end

  defp x_formatter(datetime) do
    datetime
    |> Calendar.strftime("%H:%M:%S")
  end

end
