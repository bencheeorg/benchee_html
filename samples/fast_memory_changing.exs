# random by design so that memory actually changes
# this has too wide of a range and too small of a sample size, don't do this at home
Benchee.run(
  %{
    "Enum.to_list" => fn range -> Enum.to_list(range) end,
    "Enum.into" => fn range -> Enum.into(range, []) end
  },
  formatters: [
    {Benchee.Formatters.HTML, file: "samples_output/memory_changing.html"},
    {Benchee.Formatters.Console, extended_statistics: true}
  ],
  before_each: fn _ -> 0..(:rand.uniform(1_000) + 1000) end,
  warmup: 0,
  time: 0.1,
  memory_time: 0.1
)
