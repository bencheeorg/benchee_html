var RUN_TIME_AXIS_TITLE = "Run Time in microseconds";

var eachProperty = function(object, fun) {
  for (var property in object) {
    if (object.hasOwnProperty(property)) {
      fun(property, object)
    }
  }
};

var runtimeHistogramData = function(runTimeData) {
  var data = [
    {
      type: 'histogram',
      x: runTimeData
    }
  ];

  return data;
};

var drawGraph = function(node, data, layout) {
  Plotly.newPlot(node, data, layout, { displaylogo: false });
};

var rawRunTimeData = function(runTimeData) {

  var data = [
    {
      y: runTimeData,
      type: 'bar'
    }
  ];

  return data;
};

var ipsComparisonData = function(statistics) {
  var names = [];
  var ips = [];
  var errors = [];
  for (var name in statistics) {
    if (statistics.hasOwnProperty(name)) {
      names.push(name);
      ips.push(statistics[name]['ips']);
      errors.push(statistics[name]['std_dev_ips']);
    }
  };

  var data = [
    {
      type: 'bar',
      x: names,
      y: ips,
      error_y: {
        type: 'data',
        array: errors,
        visible: true
      }
    }
  ];

  return data;
};

var boxPlotData = function(runTimes) {
  data = []
  eachProperty(runTimes, function(name, runTime) {
    data.push({
      name: name,
      y: runTime[name],
      type: 'box'
    })
  });

  return data;
};

window.drawIpsComparisonChart = function(statistics) {
  var ipsNode = document.getElementById("ips-comparison");
  var layout = {
    title: "Iterations per Second",
    yaxis: { title: "Iterations per Second" }
  };
  drawGraph(ipsNode, ipsComparisonData(statistics), layout);
};

window.drawComparisonBoxPlot = function(runTimes) {
  var boxNode = document.getElementById("box-plot");
  var layout = {
    title: "Run Time Boxplot",
    yaxis: { title: RUN_TIME_AXIS_TITLE }
  };
  drawGraph(boxNode, boxPlotData(runTimes), layout);
};

window.drawRawRunTimeCharts = function(runTimes) {
  var runTimeNodes = document.getElementsByClassName("raw-run-times");
  var runTimesNodesArray = Array.from(runTimeNodes); // Oh JavaScript
  runTimesNodesArray.forEach(function(node) {
    var jobName = node.getAttribute("data-job-name");
    var runTimeData = runTimes[jobName];
    var layout = {
      title: jobName + " Raw Run Times",
      yaxis: { title: RUN_TIME_AXIS_TITLE },
      xaxis: { title: "Sample number"}
    };
    drawGraph(node, rawRunTimeData(runTimeData), layout);
  });
};

window.drawRunTimeHistograms = function(runTimes) {
  var runTimeHistogramNodes = document.getElementsByClassName("sorted-run-times");
  var runTimeHistogramNodesArray = Array.from(runTimeHistogramNodes); // Oh JavaScript
  runTimeHistogramNodesArray.forEach(function(node) {
    var jobName = node.getAttribute("data-job-name");
    var runTimeData = runTimes[jobName];
    var layout = {
      title: jobName + " Run Times Histogram",
      xaxis: { title: "Raw run time bucket" },
      yaxis: { title: "Occurences in sample" }
    };
    drawGraph(node, runtimeHistogramData(runTimeData), layout);
  });
};
