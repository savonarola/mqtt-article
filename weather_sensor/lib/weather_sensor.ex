defmodule WeatherSensor do
  @moduledoc false

  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    interval = Application.get_env(:weather_sensor, :interval)
    emqtt_opts = Application.get_env(:weather_sensor, :emqtt)
    report_topic = "/reports/#{emqtt_opts[:clientid]}/temperature"
    {:ok, pid} = :emqtt.start_link(emqtt_opts)

    timer = :erlang.start_timer(interval, self(), :tick)
    {:ok,
      %{
        interval: interval,
        timer: timer,
        report_topic: report_topic,
        pid: pid
      },
      {:continue, :start_emqtt}}
  end

  def handle_continue(:start_emqtt, %{pid: pid} = st) do
    {:ok, _} = :emqtt.connect(pid)
    
    emqtt_opts = Application.get_env(:weather_sensor, :emqtt)
    clientid = emqtt_opts[:clientid]
    {:ok, _, _} = :emqtt.subscribe(pid, {"/commands/#{clientid}/set_interval", 1})
    {:noreply, st}
  end

  def handle_info({:timeout, _ref, :tick}, %{report_topic: topic, pid: pid} = st) do
    report_temperature(pid, topic)
    {:noreply, ensure_timer(st)}
  end

  def handle_info({:publish, publish}, st) do
    IO.inspect(publish)
    handle_publish(parse_topic(publish), publish, st)
  end

  defp handle_publish(["commands", _, "set_interval"], %{payload: payload}, st) do
    new_interval = String.to_integer(payload)
    {:noreply, %{st | interval: new_interval}}
  end

  defp handle_publish(_, _, st) do
    {:noreply, st}
  end

  defp ensure_timer(%{timer: timer, interval: interval} = st) do
    :erlang.cancel_timer(timer)
    new_timer = :erlang.start_timer(interval, self(), :tick)
    %{st | timer: new_timer}
  end

  defp parse_topic(%{topic: topic}) do
    String.split(topic, "/", trim: true)
  end

  defp report_temperature(pid, topic) do
    temperature = 10.0 + 2.0 * :rand.normal()
    message = {:os.system_time(:millisecond), temperature}
    payload = :erlang.term_to_binary(message)
    :emqtt.publish(pid, topic, payload)
  end
end

