# It is possible to use multiple formatters so that you have both the Console
# output and an HTML file.
list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [{Benchee.Formatters.HTML, auto_open: false}],
  time: 0.05,
  memory_time: 0.05,
  warmup: 0.01
)
