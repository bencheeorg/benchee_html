list_10k = 1..10_000 |> Enum.to_list() |> Enum.shuffle()
list_30k = 1..30_000 |> Enum.to_list() |> Enum.shuffle()
list_50k = 1..50_000 |> Enum.to_list() |> Enum.shuffle()
list_70k = 1..70_000 |> Enum.to_list() |> Enum.shuffle()
list_90k = 1..90_000 |> Enum.to_list() |> Enum.shuffle()
list_100k = 1..100_000 |> Enum.to_list() |> Enum.shuffle()

Benchee.run(
  %{
    "10k" => fn -> Enum.sort(list_10k) end,
    "30k" => fn -> Enum.sort(list_30k) end,
    "50k" => fn -> Enum.sort(list_50k) end,
    "70k" => fn -> Enum.sort(list_70k) end,
    "90k" => fn -> Enum.sort(list_90k) end,
    "100k" => fn -> Enum.sort(list_100k) end
  },
  time: 2,
  warmup: 0,
  unit_scaling: :largest,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.HTML, file: "samples_output/many.html"}
  ]
)
