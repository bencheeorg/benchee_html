## unreleased

### Features

* uses the `unit_scaling` option from benchee and scales units accordingly
* automatically open the report in a web browser after creation is finished

## 0.3.1 2017-05-07

### Bugfixes

* use new benchee_json release to circumvent faulty typespec

## 0.3.0 2017-05-07

Benchee 0.8.0 compatibility, typesepcs, just Elixir 1.3+ and add missing applications.

## 0.2.0 2017-04-23

This release splits up the resulting HTML into multiple files, so that it isn't just one long HTML file and also for performance as drawing the graphs with lots of data points seems to be quite taxing on the browser.

### Features

* Instead of one huge HTML multiple files are generated:
  * An index page
  * a job comparison page per input
  * a detail view page per job per input
