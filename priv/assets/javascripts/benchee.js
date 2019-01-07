var RUN_TIME_AXIS_TITLE = "Run Time in microseconds";

var runtimeHistogramData = function(runTimeData) {
  var data = [
    {
      type: "histogram",
      x: runTimeData
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

var rawRunTimeData = function(runTimeData) {

  var data = [
    {
      y: runTimeData,
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

window.drawRawRunTimeCharts = function(runTimes, inputHeadline, statistics) {
  var runTimeNode = document.getElementById("raw-run-times");
  var jobName = runTimeNode.getAttribute("data-job-name");
  var minY = statistics.minimum * 0.9;
  var maxY = statistics.maximum;
  var layout = {
    title: jobName + " Raw Run Times" + inputHeadline,
    yaxis: { title: RUN_TIME_AXIS_TITLE, range: [minY, maxY] },
    xaxis: { title: "Sample number"},
    annotations: [{ x: 0, y: minY, text: parseInt(minY), showarrow: false, xref: "x", yref: "y", xshift: -10 }]
  };
  drawGraph(runTimeNode, rawRunTimeData(runTimes), layout);
};

window.drawRunTimeHistograms = function(runTimes, inputHeadline) {
  var runTimeHistogramNode = document.getElementById("sorted-run-times");
  var jobName = runTimeHistogramNode.getAttribute("data-job-name");
  var layout = {
    title: jobName + " Run Times Histogram" + inputHeadline,
    xaxis: { title: "Raw run time buckets in microseconds" },
    yaxis: { title: "Occurences in sample" }
  };
  drawGraph(runTimeHistogramNode, runtimeHistogramData(runTimes), layout);
};

window.toggleSystemDataInfo = function() {
  var systemDataNode = document.getElementById("system-info");
  var newState = (systemDataNode.style.display === 'block') ? 'none' : 'block';
  
  systemDataNode.style.display = newState;
};
