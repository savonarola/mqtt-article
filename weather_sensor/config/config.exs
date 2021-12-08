import Config

config :weather_sensor, :emqtt,
  host: '127.0.0.1',
  port: 1883,
  clientid: "weather_sensor",
  clean_start: false,
  name: :emqtt

config :weather_sensor, :interval, 1000
