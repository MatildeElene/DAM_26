# Jydsk Asyl: Assignment 3, DAM26

This repository contains the data-processing and analysis workflow for Assignment 3
in Digital Archives and Methods (DAM26). The project examines digitized and
crowdsourced patient registers from the psychiatric institution in Risskov,
focusing on records from the separately maintained women's and men's series,
1889–1913.

## Data Source and License

The historical source material originates from the Danish National Archives
(Rigsarkivet), *Psykiatrisk Hospital Risskov: Protokol over optagne patienter*.

The analysis uses publicly available crowdsourced transcriptions of the digitized
registers. The original archival material and transcriptions remain subject to
the terms and conditions specified by Rigsarkivet.

[Add Rigsarkivet source/license information here.]

## Repository Structure

```text
assignment3/
├── data/
│   ├── raw_data/                  # Computationally extracted transcriptions
│   └── tidy_data/                 # Cleaned and structured datasets used for analysis
│
├── out/
│   ├── figures/                   # Figures generated during analysis
│   └── digitized_comparison/      # Material used for validation against digitized records
│
├── src/
│   ├── scrape_data.Rmd            # Extracts crowdsourced transcriptions
│   └── clean_and_analyze.Rmd      # Data cleaning, validation, and statistical analysis
│
├── requirements.txt               # Required R packages
└── README.md                      # Project documentation
```

## Extraction Logic example (women)
*Example for the women's series:*

Women 1889–1913
207 scanned pages total

Page 1 ─ front matter ┐
Page 2 ─ front matter ├─ exclude from patient extraction
Page 3 ─ patient data ┘ ← START
Page 4 ─ patient data
...
Page 207
```

**Descriptive overview following initial scraping and file structuring:**
Women: 1984 patient records
Men: 2013 patient records
Total: 3997 patient records

Women pages containing patient records: 199 
Men pages containing patient records: 203 
Unique patient numbers: 3977 

## Analysis
**Pre filtering: Raw datasets **
- LOOK 
- make sure evertyhing fits in the date format (find package from class)

**After filtering: Tidy datasets**
- filter out duplicates: only unique IDs 
- save as CSV files in 


