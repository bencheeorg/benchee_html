# BencheeHTML [![Build Status](https://travis-ci.org/PragTob/benchee_html.svg?branch=master)](https://travis-ci.org/PragTob/benchee_html)

Formatter for [benchee](github.com/PragTob/benchee) to produce some standalone HTML with nice graphs, a data table etc. from your benchee benchmarking results :) Also allows you to export PNG images, the graphs are also somewhat explorable thanks to [plotly.js](https://plot.ly/javascript/)!

To get a taste of what this is like you can check out an [online example report](http://www.pragtob.info/benchee/tco_detailed_big_(1_million).html) or look at this png exported chart of iterations per second including standard deviation:

![ips](http://www.pragtob.info/benchee/images/ips.png)

It not only generates HTML but also assets and into the same folder. You can just take it and drop it on your server, github pages or public dropbox directory if you want it to be accessible to someone else :)

## Installation

Add `benchee_html` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:benchee_html, "~> 0.1.0", only: :dev}]
end
```

## Usage

Just use it as a formatter for [benchee](github.com/PragTob/benchee) and tell it through `html: [file: "your_file.html"]` where the html report should be written to.

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
},
  formatters: [
    &Benchee.Formatters.HTML.output/1,
    &Benchee.Formatters.Console.output/1
  ],
  html: [file: "samples_output/my.html"],
)
```

Of course it also works with multiple inputs, in that case one file per input is generated:

```elixir
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

```

When you hover the graphs in the HTML report, quite some plotly.js controls and links appear with which you can navigate in the graph and more.

Be aware, that currently when too many samples are recorded (> 100_000 usually) rendering might break as plotly can't handle all that data. See [this issue](https://github.com/PragTob/benchee_html/issues/3) on how to quick fix it and what could be done in the future.

## PNG image export/download

When you hover the graph the controls appear and the left most of those is a camera and says "Download plot as png" - and it does what you'd expect. Refer to the image below if you need more guidance :)

![download](http://www.pragtob.info/benchee/images/download.png)


## A look at graphs

In the wiki there is a page [providing an overview of the differnt chart types benchee_html produces](https://github.com/PragTob/benchee_html/wiki/Chart-Types).

For the ones that just want to scroll through, here they are once more.

### IPS Bar Chart

![ips](http://www.pragtob.info/benchee/images/ips.png)

### Run Time Boxplot

![boxplot](http://www.pragtob.info/benchee/images/boxplot.png)

### Run Time Histogram

![histo](http://www.pragtob.info/benchee/images/histogram.png)


### Raw run times

![raw_run_times](http://www.pragtob.info/benchee/images/raw_run_times.png)
