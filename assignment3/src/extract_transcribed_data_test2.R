library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(tidyr)
library(readr)
library(tibble)

# defining all fields exactly as they are presented in the transcription:
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

#fragmenting patients: (parsing one patient block)
parse_patient <- function(block) {
  block <- block %>%
    str_remove("^Optagne patienter\\s*") %>%
    str_squish()
  
  # using regular expressions "find a field label, then capture everything after it until the next known field label."
  result <- map_dfr(seq_along(fields), function(i) {
    field <- fields[i]
    field_escaped <- str_replace_all(field, "([.?+*^$(){}|\\[\\]\\\\])", "\\\\\\1")
    
    if (i < length(fields)) {
      next_fields <- fields[(i + 1):length(fields)]
      
      next_pattern <- paste(
        str_replace_all(next_fields, "([.?+*^$(){}|\\[\\]\\\\])", "\\\\\\1"),
       collapse = "|"
        
      )
      pattern <- paste0(field_escaped,
                        "\\s*(.*?)(?=\\s+(?:",
                        next_pattern,
                        ")(?:\\s+|$)|$)")
    } else {
      pattern <- paste0(field_escaped, "\\s*(.*)$")
    }
    value <- str_match(block, regex(pattern, dotall = TRUE))[, 2]
    tibble(field = field, value = str_squish(value))
  })
  result %>%
    pivot_wider(names_from = field, values_from = value)
}

# Function for finding the next transcription page
get_next_url <- function(url) {
  page <- read_html(url)
  links <- page %>%
    html_elements("a")
  link_table <- tibble(text = html_text2(links), href = html_attr(links, "href"))
  next_href <- link_table %>%
    filter(str_detect(text, "Næste billede")) %>%
    pull(href)
  if (length(next_href) == 0) {
    return(NA_character_)
  }
  url_absolute(next_href[1], "https://cs.rigsarkivet.dk")
  
}

#defining first test page*
test_url <- "https://cs.rigsarkivet.dk/picture/view-values/1533175"
# Downloading HTML*
page <- read_html(test_url)
# extracting visible page text*
page_text <- page %>%
  html_element("body") %>%
  html_text2()

#isolating patient-record portion of page
patient_text <- page_text %>%
  str_extract(
    regex(
      "Optagne patienter.*?(?=« Forrige billede|Næste billede|Skjul dokument)",
      dotall = TRUE
    )
  )

#splitting into patient blocks:
patient_blocks <- patient_text %>%
  str_split("(?=Optagne patienter\\s+Løbenr)") %>%
  .[[1]] %>%
  str_trim() %>%
  discard(~ .x == "")
cat("Number of patient records found:", length(patient_blocks), "\n")

# parsing all patients on page:
patients <- patient_blocks %>%
  map_dfr(parse_patient)
glimpse(patients)

# extracting provenance information:
crowd_id <- str_extract(test_url, "\\d+$")
html_source <- page %>%
  as.character()
archive_image_id <- html_source %>%
  str_match('SA_GUIDs"\\s*:\\s*\\["(\\d+)"\\]') %>%
  .[, 2]
cat("Crowdsourcing ID:", crowd_id, "\n")

cat("Archive image ID:", archive_image_id, "\n")

# adding to every patient:
patients <- patients %>%
  mutate(
    crowd_id = crowd_id,
    archive_image_id = archive_image_id,
    transcription_url = url1,
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

# testing URL
url2 <- get_next_url(url1)
url3 <- get_next_url(url2)

cat("\nPage 1:", url1, "\nPage 2:", url2, "\nPage 3:", url3, "\n")