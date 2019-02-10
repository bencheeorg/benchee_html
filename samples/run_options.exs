list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
},
  formatters: [
    {Benchee.Formatters.HTML, file: "output/my.html", auto_open: false, inline_assets: true},
    Benchee.Formatters.Console
  ],
  formatter_options: [
    html: [file: "output/my.html", auto_open: false, inline_assets: true]
  ]
)
