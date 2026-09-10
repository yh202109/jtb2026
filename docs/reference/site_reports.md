# Mock study-site reports

Twenty-four invented rows of free-text site comments, used by the
examples and by the documentation site in `doc/`. The wording is chosen
to make the difference between the two searches visible: several rows
describe nausea without using the word, one row misspells *headache*,
and "device issue" rows talk about pens, pumps and autoinjectors rather
than devices.

## Usage

``` r
site_reports
```

## Format

A `data.frame` with 24 rows and 9 columns:

- report_id:

  Report identifier, `R001` to `R024`.

- site:

  Study site name.

- subject:

  Subject identifier.

- visit:

  Scheduled visit label.

- term:

  Coded event term.

- comment:

  Free-text note – the interesting column to search.

- severity:

  `Mild`, `Moderate` or `Severe`.

- outcome:

  Reported outcome.

- report_date:

  Date of the report.

## Source

Invented for this package; see `data-raw/site_reports.R`.

## Details

Nothing in this table comes from a real study, a real site or a real
person.

## Examples

``` r
str(site_reports)
#> 'data.frame':    24 obs. of  9 variables:
#>  $ report_id  : chr  "R001" "R002" "R003" "R004" ...
#>  $ site       : chr  "Boston" "Boston" "Boston" "Boston" ...
#>  $ subject    : chr  "S-1001" "S-1002" "S-1003" "S-1004" ...
#>  $ visit      : chr  "Week 2" "Week 2" "Week 4" "Week 8" ...
#>  $ term       : chr  "Headache" "Nausea" "Fatigue" "Rash" ...
#>  $ comment    : chr  "Subject reported a dull headache starting two hours after the morning dose; resolved without treatment." "Subject felt queasy through the afternoon and skipped the evening meal." "Reported feeling unusually tired all week and needing an extra nap each day." "Small itchy patch on the left forearm, no spreading noted at review." ...
#>  $ severity   : chr  "Mild" "Moderate" "Mild" "Mild" ...
#>  $ outcome    : chr  "Recovered" "Recovered" "Ongoing" "Recovered" ...
#>  $ report_date: Date, format: "2026-01-06" "2026-01-07" ...
table(site_reports$term)
#> 
#>            Device issue               Dizziness                Dyspnoea 
#>                       3                       2                       1 
#>                 Fatigue                Headache Injection site reaction 
#>                       3                       4                       2 
#>                  Nausea      Protocol deviation                 Pyrexia 
#>                       4                       2                       1 
#>                    Rash 
#>                       2 
```
