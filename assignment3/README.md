# Jydsk Asyl: Assignment 3, DAM26

This repository contains the data-processing and analysis workflow for Assignment 3
in Digital Archives and Methods (DAM26). The project examines digitized and
crowdsourced patient registers from the psychiatric institution in Risskov,
focusing on records from the separately maintained women's and men's series,
1889–1913.

## License

The original code produced for this project is licensed under the [MIT License](LICENSE).

The MIT License applies only to original software and code produced for this project. It does not apply to archival images, crowdsourced transcriptions, or other source material originating from the Danish National Archives (Rigsarkivet).

Permission to use the data for the present project was obtained directly from Rigsarkivet. Researchers wishing to reuse or redistribute the underlying source material should consult Rigsarkivet and obtain any necessary permissions.

See [Rigsarkivet: Betingelser for download](https://www.rigsarkivet.dk/arkivalieronline/).


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

Page 1   ─ front matter ┐
Page 2   ─ front matter ┘ ← excluded from patient extraction
Page 3   ─ patient data    ← START
Page 4   ─ patient data
...
Page 205 ─ patient data    ← END
Page 206 ─ back matter  ┐
Page 207 ─ back matter  ┘ ← excluded from patient extraction
```

## Extracted Data

Initial extraction and concatenation produced:

| Series | Patient records | Archival pages |
|--------|----------------:|---------------:|
| Women  | 1,984           | 199            |
| Men    | 2,013           | 203            |
| **Total** | **3,997**    | **402**        |

Following data validation, cleaning, and duplicate assessment, the final analytical sample comprised **3,977 unique patient records**.
