# It is possible to use multiple formatters so that you have both the Console
# output and a csv file.
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn(list) -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn(list) -> list |> Enum.map(map_fun) |> List.flatten end
},
  formatters: [
    &Benchee.Formatters.HTML.output/1,
    &Benchee.Formatters.Console.output/1
  ],
  html: [file: "samples_output/my.html"],
  time: 7,
  warmup: 3,
  inputs: %{
    "Smaller List" => Enum.to_list(1..1_000),
    "Bigger List"  => Enum.to_list(1..100_000),
  }
)
