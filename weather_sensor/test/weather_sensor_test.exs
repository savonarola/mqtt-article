defmodule WeatherSensorTest do
  use ExUnit.Case
  doctest WeatherSensor

  test "greets the world" do
    assert WeatherSensor.hello() == :world
  end
end
