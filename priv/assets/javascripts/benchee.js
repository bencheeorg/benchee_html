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
  Plotly.newPlot(node, data, layout, { displaylogo: false });
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

var ipsComparisonData = function(statistics, sortOrder) {
  var names = [];
  var ips = [];
  var errors = [];
  sortOrder.forEach(function(name) {
    names.push(name);
    ips.push(statistics[name]["ips"]);
    errors.push(statistics[name]["std_dev_ips"]);
  });

  var data = [
    {
      type: "bar",
      x: names,
      y: ips,
      error_y: {
        type: "data",
        array: errors,
        visible: true
      }
    }
  ];

  return data;
};

var boxPlotData = function(runTimes, sortOrder) {
  var data = sortOrder.map(function(name) {
    return {
      name: name,
      y: runTimes[name],
      type: "box"
    };
  });

  return data;
};

window.drawIpsComparisonChart = function(statistics, sortOrder, inputHeadline) {
  var ipsNode = document.getElementById("ips-comparison");
  var layout = {
    title: "Average Iterations per Second" + inputHeadline,
    yaxis: { title: "Iterations per Second" }
  };
  drawGraph(ipsNode, ipsComparisonData(statistics, sortOrder), layout);
};

window.drawComparisonBoxPlot = function(runTimes, sortOrder, inputHeadline) {
  var boxNode = document.getElementById("box-plot");
  var layout = {
    title: "Run Time Boxplot" + inputHeadline,
    yaxis: { title: RUN_TIME_AXIS_TITLE }
  };
  drawGraph(boxNode, boxPlotData(runTimes, sortOrder), layout);
};

window.drawRawRunTimeCharts = function(runTimes, inputHeadline) {
  var runTimeNodes = document.getElementsByClassName("raw-run-times");
  var runTimesNodesArray = Array.from(runTimeNodes); // Oh JavaScript
  runTimesNodesArray.forEach(function(node) {
    var jobName = node.getAttribute("data-job-name");
    var runTimeData = runTimes[jobName];
    var layout = {
      title: jobName + " Raw Run Times" + inputHeadline,
      yaxis: { title: RUN_TIME_AXIS_TITLE },
      xaxis: { title: "Sample number"}
    };
    drawGraph(node, rawRunTimeData(runTimeData), layout);
  });
};

window.drawRunTimeHistograms = function(runTimes, inputHeadline) {
  var runTimeHistogramNodes = document.getElementsByClassName("sorted-run-times");
  var runTimeHistogramNodesArray = Array.from(runTimeHistogramNodes); // Oh JavaScript
  runTimeHistogramNodesArray.forEach(function(node) {
    var jobName = node.getAttribute("data-job-name");
    var runTimeData = runTimes[jobName];
    var layout = {
      title: jobName + " Run Times Histogram" + inputHeadline,
      xaxis: { title: "Raw run time buckets in microseconds" },
      yaxis: { title: "Occurences in sample" }
    };
    drawGraph(node, runtimeHistogramData(runTimeData), layout);
  });
};
