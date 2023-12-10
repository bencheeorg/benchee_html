list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [
    fn suite -> Benchee.Formatters.HTML.sequential_output(suite, auto_open: false) end
  ],
  time: 0.05,
  memory_time: 0.05,
  warmup: 0.01
)
