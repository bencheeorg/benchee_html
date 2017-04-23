## 0.2.0 2017-04-23

This release splits up the resulting HTML into multiple files, so that it isn't just one long HTML file and also for performance as drawing the graphs with lots of data points seems to be quite taxing on the browser.

### Features

* Instead of one huge HTML multiple files are generated:
  * An index page
  * a job comparison page per input
  * a detail view page per job per input
