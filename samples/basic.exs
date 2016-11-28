# It is possible to use multiple formatters so that you have both the Console
# output and a csv file.
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(
  %{
    formatters: [
      &Benchee.Formatters.PlotlyJS.output/1,
      &Benchee.Formatters.Console.output/1
    ],
    plotly_js: %{file: "samples_output/my.html"},
    time: 2,
    warmup: 0
  },
  %{
    "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
  })
