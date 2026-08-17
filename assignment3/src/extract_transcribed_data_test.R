library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(tidyr)
library(readr)
library(tibble)

url <- "https://cs.rigsarkivet.dk/picture/view-values/1533175"

page <- read_html(url)

# Get all visible page text
page_text <- page %>%
  html_element("body") %>%
  html_text2()

fields <- c(
  "Løbenr",
  "Navn",
  "Køn",
  "Stand og stilling",
  "Hjemsted",
  "Alder ved indlæggelsen",
  "Fødselsdato",
  "Trosbekendelse",
  "Ægtestandsforhold",
  "Naar ankommen",
  "Hvorfra ankommen",
  "Diagnose ved indlæggelsen",
  "Varighed ved indlæggelsen",
  "Journalnummer",
  "Forplejnings og betalingsklasse",
  "Anfaldets nr.",
  "Anmærkninger",
  "Familiedisposition",
  "Afgået nr.",
  "Afgået naar",
  "I hvad tilstand",
  "Hvorhen",
  "Ældre nr.",
  "Genindlagt under nr.",
  "Indtasters bemærkninger"
) # manually checked that these fields are correct. 

# isolating the patient-record portion of the page:
patient_text <- page_text %>%
  str_extract(
    regex(
      "Optagne patienter.*?(?=« Forrige billede|Næste billede|Skjul dokument)",
      dotall = TRUE
    )
  )

#fragmenting patients: 
patient_blocks <- patient_text %>%
  str_split("(?=Optagne patienter\\s+Løbenr)") %>%
  .[[1]] %>%
  str_trim() %>%
  discard(~ .x == "")

length(patient_blocks)

# using regular expressions "find a field label, then capture everything after it until the next known field label."
field_pattern <- paste(
  str_replace_all(fields, "([.?+*^$(){}|\\[\\]\\\\])", "\\\\\\1"),
  collapse = "|"
)
parse_patient <- function(block) {
  
  block <- block %>%
    str_remove("^Optagne patienter\\s*") %>%
    str_squish()
  
  result <- map_dfr(seq_along(fields), function(i) {
    
    field <- fields[i]
    
    field_escaped <- str_replace_all(
      field,
      "([.?+*^$(){}|\\[\\]\\\\])",
      "\\\\\\1"
    )
    
    if (i < length(fields)) {
      
      next_fields <- fields[(i + 1):length(fields)]
      
      next_pattern <- paste(
        str_replace_all(
          next_fields,
          "([.?+*^$(){}|\\[\\]\\\\])",
          "\\\\\\1"
        ),
        collapse = "|"
      )
      
      pattern <- paste0(
        field_escaped,
        "\\s*(.*?)(?=\\s+(?:",
        next_pattern,
        ")(?:\\s+|$)|$)"
      )
      
    } else {
      
      pattern <- paste0(
        field_escaped,
        "\\s*(.*)$"
      )
    }
    
    value <- str_match(
      block,
      regex(pattern, dotall = TRUE)
    )[, 2]
    
    tibble(
      field = field,
      value = str_squish(value)
    )
  })
  
  result %>%
    pivot_wider(
      names_from = field,
      values_from = value
    )
}

#testing on one patient only
test_patient <- parse_patient(patient_blocks[[1]])
glimpse(test_patient)

# parsing all patients on the page

patients <- patient_blocks %>%
  map_dfr(parse_patient)

glimpse(patients)

#adding provenacne and image ID extracted from the HTML
crowd_id <- str_extract(url, "\\d+$")
html_source <- page %>%
  as.character()

archive_image_id <- html_source %>%
  str_match('SA_GUIDs"\\s*:\\s*\\["(\\d+)"\\]') %>%
  .[, 2]

archive_image_id

patients <- patients %>%
  mutate(
    crowd_id = crowd_id,
    archive_image_id = archive_image_id,
    transcription_url = url,
    archive_image_api = paste0(
      "https://api.rigsarkivet.dk/ao/v1/images/",
      archive_image_id
    ),
    .before = 1
  )

#saving to a CSV file: 
write_csv(
  patients,
  file.path("..", "data", "raw", "risskov_test_page.csv")
)
