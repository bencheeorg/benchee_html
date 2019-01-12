var RUN_TIME_AXIS_TITLE = "Run Time in nanoseconds";

var drawGraph = function(node, data, layout) {
  Plotly.newPlot(node, data, layout, {
    displaylogo: false,
    modeBarButtonsToRemove: ['sendDataToCloud']
  });
};

var ipsComparisonData = function(scenarios) {
  return [
    {
      type: "bar",
      x: scenarios.map(function(scenario) { return scenario["name"]; }),
      y: scenarios.map(function(scenario) { return scenario["run_time_statistics"]["ips"]; }),
      error_y: {
        type: "data",
        array: scenarios.map(function(scenario) { return scenario["run_time_statistics"]["std_dev_ips"]; }),
        visible: true
      }
    }
  ];
};

var boxPlotData = function(runTimes, sortOrder) {
  return scenarios.map(function(scenario) {
    return {
      name: scenario["name"],
      y: scenario["run_times"],
      type: "box"
    };
  });
};

window.drawIpsComparisonChart = function(scenarios, inputHeadline) {
  var ipsNode = document.getElementById("ips-comparison");
  var layout = {
    title: "Average Iterations per Second" + inputHeadline,
    yaxis: { title: "Iterations per Second" }
  };
  drawGraph(ipsNode, ipsComparisonData(scenarios), layout);
};

window.drawComparisonBoxPlot = function(scenarios, inputHeadline) {
  var boxNode = document.getElementById("box-plot");
  var layout = {
    title: "Run Time Boxplot" + inputHeadline,
    yaxis: { title: RUN_TIME_AXIS_TITLE }
  };
  drawGraph(boxNode, boxPlotData(scenarios), layout);
};

const rawChartLayout = function(title, y_axis_title, statistics) {
  var minY = statistics.minimum * 0.9;
  var maxY = statistics.maximum;

  return {
    title: title,
    yaxis: { title: y_axis_title, range: [minY, maxY] },
    xaxis: { title: "Sample number"},
    annotations: [{ x: 0, y: minY, text: parseInt(minY), showarrow: false, xref: "x", yref: "y", xshift: -10 }]
  };
}

const barChart = function(data) {
  return [
    {
      y: data,
      type: "bar"
    }
  ];
};

window.drawRawRunTimeChart = function(scenario, inputHeadline) {
  var layout = rawChartLayout(
    scenario.name + " Raw Run Times" + inputHeadline,
    RUN_TIME_AXIS_TITLE,
    scenario.run_time_statistics
  )
  
  drawGraph(
    document.getElementById("raw-run-times"),
    barChart(scenario.run_times),
    layout
  );
};

window.drawRawMemoryChart = function(scenario, inputHeadline) {
  var layout = rawChartLayout(
    scenario.name + " Raw Memory Usages" + inputHeadline,
    "Raw Memory Usages in Bytes",
    scenario.memory_usage_statistics
  )
  
  drawGraph(
    document.getElementById("raw-memory"),
    barChart(scenario.memory_usages),
    layout
  );
};

var histogramData = function(data) {
  return [
    {
      type: "histogram",
      x: data
    }
  ];
};

window.drawRunTimeHistogram = function(scenario, inputHeadline) {
  var layout = {
    title: scenario.name + " Run Times Histogram" + inputHeadline,
    xaxis: { title: "Raw run time buckets in nanoseconds" },
    yaxis: { title: "Occurences in sample" }
  };

  drawGraph(
    document.getElementById("run-times-histogram"),
    histogramData(scenario.run_times),
    layout
  );
};

window.drawMemoryHistogram = function(scenario, inputHeadline) {
  var layout = {
    title: scenario.name + " Memory Histogram" + inputHeadline,
    xaxis: { title: "Raw memory usage buckets in bytes" },
    yaxis: { title: "Occurences in sample" }
  };

  drawGraph(
    document.getElementById("memory-histogram"),
    histogramData(scenario.memory_usages),
    layout
  );
};

window.toggleSystemDataInfo = function() {
  var systemDataNode = document.getElementById("system-info");
  var newState = (systemDataNode.style.display === 'block') ? 'none' : 'block';
  
  systemDataNode.style.display = newState;
};
