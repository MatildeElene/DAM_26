# Jydsk Asyl: Assignment 3, DAM26

This repository contains the data-processing and analysis workflow for Assignment 3
in Digital Archives and Methods (DAM26). The project examines digitized and
crowdsourced patient registers from the psychiatric institution in Risskov,
focusing on records from the separately maintained women's and men's series,
1889–1913.

## Data Source and License

The historical source material originates from the Danish National Archives
(Rigsarkivet), *Psykiatrisk Hospital Risskov: Protokol over optagne patienter*.

The project uses publicly accessible digitized archival records and crowdsourced transcriptions made available through Rigsarkivet. According to Rigsarkivet, individual images from Arkivalieronline may be downloaded for private or professional research, while larger-scale downloading requires permission from Rigsarkivet.

Permission to use the data for the present project was additionally obtained directly from Rigsarkivet via email. This permission applies specifically to the present research project and does not constitute a general license for redistribution.

The original archival material and crowdsourced transcriptions are not relicensed by this repository. Users should consult Rigsarkivet's current terms and obtain any necessary permissions before reusing or redistributing the source material.

[Rigsarkivet: Betingelser for download](https://www.rigsarkivet.dk/arkivalieronline/)

## Repository Structure

```text
assignment3/
├── data/
│   ├── raw_data/                  # Computationally extracted transcriptions
│   ├── tidy_data/                 # Cleaned and structured datasets
│   └── analysis_data/             # Final dataset used for analysis
│
├── out/
│   ├── figures/                   # Figures generated during analysis
│   └── digitized_comparison/      # Material used for validation against digitized records
│
├── src/
│   ├── scrape_data.R              # Extracts crowdsourced transcriptions
│   ├── data_cleaning.Rmd          # Data cleaning and validation extraction
│   └── analysis.Rmd               # Statistical analyses
│
├── supplementary_materials/       # Includes transcription conventions given by Rigsarkivet
│
├── requirements.txt               # Required R packages
└── README.md                      # Project documentation
```

## Extraction Logic example
*Example for the women's series:*

```text
Women 1889–1913
207 scanned pages total

Page 1 ─ front matter ┐
Page 2 ─ front matter ├─ exclude from patient extraction
Page 3 ─ patient data ┘ ← START
Page 4 ─ patient data
Page 207
```

## Extracted Data

Initial extraction and concatenation produced:

| Series | Patient records | Archival pages |
|--------|----------------:|---------------:|
| Women  | 1,984           | 199            |
| Men    | 2,013           | 203            |
| **Total** | **3,997**    | **402**        |

Following data validation, cleaning, and duplicate assessment, the final analytical sample comprised **3,977 unique patient records**.
