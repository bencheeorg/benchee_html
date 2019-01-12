var RUN_TIME_AXIS_TITLE = "Run Time in microseconds";

var runtimeHistogramData = function(runTimeData) {
  var data = [
    {
      type: "histogram",
      x: scenario.run_times
    }
  ];

  return data;
};

var drawGraph = function(node, data, layout) {
  Plotly.newPlot(node, data, layout, {
    displaylogo: false,
    modeBarButtonsToRemove: ['sendDataToCloud']
  });
};

var rawRunTimeData = function(scenario) {

  var data = [
    {
      y: scenario.run_times,
      type: "bar"
    }
  ];

  return data;
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

window.drawRawRunTimeCharts = function(scenario, inputHeadline) {
  var runTimeNode = document.getElementById("raw-run-times");
  var minY = scenario.run_time_statistics.minimum * 0.9;
  var maxY = scenario.run_time_statistics.maximum;
  var layout = {
    title: scenario.name + " Raw Run Times" + inputHeadline,
    yaxis: { title: RUN_TIME_AXIS_TITLE, range: [minY, maxY] },
    xaxis: { title: "Sample number"},
    annotations: [{ x: 0, y: minY, text: parseInt(minY), showarrow: false, xref: "x", yref: "y", xshift: -10 }]
  };
  drawGraph(runTimeNode, rawRunTimeData(scenario), layout);
};

window.drawRunTimeHistograms = function(scenario, inputHeadline) {
  var runTimeHistogramNode = document.getElementById("sorted-run-times");
  var layout = {
    title: scenario.name + " Run Times Histogram" + inputHeadline,
    xaxis: { title: "Raw run time buckets in microseconds" },
    yaxis: { title: "Occurences in sample" }
  };
  drawGraph(runTimeHistogramNode, runtimeHistogramData(scenario), layout);
};

window.toggleSystemDataInfo = function() {
  var systemDataNode = document.getElementById("system-info");
  var newState = (systemDataNode.style.display === 'block') ? 'none' : 'block';
  
  systemDataNode.style.display = newState;
};
