library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(tidyr)
library(readr)
library(tibble)
# see ../requirements.txt

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
    transcription_url = test_url,
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
url2 <- get_next_url(test_url)
url3 <- get_next_url(url2)

cat("\nPage 1:", test_url, "\nPage 2:", url2, "\nPage 3:", url3, "\n")


# defining starting URLs for the two analytical series
women_start_url <- "https://cs.rigsarkivet.dk/picture/view-origin-values/63211977"
men_start_url <- "https://cs.rigsarkivet.dk/picture/view-origin-values/63210970"


# function for scraping all patient records from one transcription page
scrape_page <- function(url, sex_series, series_page) {
  
  page <- read_html(url)
  
  page_text <- page %>%
    html_element("body") %>%
    html_text2()
  
  patient_text <- page_text %>%
    str_extract(
      regex(
        "Optagne patienter.*?(?=« Forrige billede|Næste billede|Skjul dokument)",
        dotall = TRUE
      )
    )
  
  # return no rows if the page contains no patient transcription
  if (is.na(patient_text)) {
    return(tibble())
  }
  
  patient_blocks <- patient_text %>%
    str_split("(?=Optagne patienter\\s+Løbenr)") %>%
    .[[1]] %>%
    str_trim() %>%
    discard(~ .x == "")
  
  if (length(patient_blocks) == 0) {
    return(tibble())
  }
  
  patients <- patient_blocks %>%
    map_dfr(parse_patient)
  
  html_source <- page %>%
    as.character()
  
  # the view-origin-values URL contains the archive image ID
  archive_image_id <- str_extract(url, "\\d+$")
  
  # retrieve crowdsourcing ID from HTML where available
  crowd_id <- html_source %>%
    str_match('CROWD_ID"\\s*:\\s*\\["(\\d+)"\\]') %>%
    .[, 2]
  
  patients <- patients %>%
    mutate(
      sex_series = sex_series,
      series_page = series_page,
      crowd_id = crowd_id,
      archive_image_id = archive_image_id,
      transcription_url = url,
      archive_image_api = paste0(
        "https://api.rigsarkivet.dk/ao/v1/images/",
        archive_image_id
      ),
      .before = 1
    )
  
  patients
}


# function for scraping a complete series by following "Næste billede"
scrape_series <- function(start_url,
                          sex_series,
                          start_page,
                          delay = 1,
                          max_pages = Inf) {
  
  current_url <- start_url
  current_page <- start_page
  
  all_patients <- list()
  visited_urls <- character()
  
  while (
    !is.na(current_url) &&
    current_page < start_page + max_pages
  ) {
    
    # stop if the website unexpectedly sends the scraper to an already visited page
    if (current_url %in% visited_urls) {
      warning("Already visited URL encountered: ", current_url)
      break
    }
    
    visited_urls <- c(visited_urls, current_url)
    
    message(
      "Scraping ",
      sex_series,
      " - series page ",
      current_page,
      ": ",
      current_url
    )
    
    page_data <- tryCatch(
      scrape_page(
        url = current_url,
        sex_series = sex_series,
        series_page = current_page
      ),
      error = function(e) {
        warning(
          "Unable to scrape series page ",
          current_page,
          ": ",
          conditionMessage(e)
        )
        tibble()
      }
    )
    
    if (nrow(page_data) > 0) {
      all_patients[[length(all_patients) + 1]] <- page_data
    }
    
    next_url <- tryCatch(
      get_next_url(current_url),
      error = function(e) {
        warning(
          "Unable to retrieve next URL after series page ",
          current_page,
          ": ",
          conditionMessage(e)
        )
        NA_character_
      }
    )
    
    Sys.sleep(delay)
    
    current_url <- next_url
    current_page <- current_page + 1
  }
  
  bind_rows(all_patients)
}

#-------------------------------------------------------------------

# testing the women series scraper on three pages
# women_test <- scrape_series(
#   start_url = women_start_url,
#   sex_series = "women",
#   start_page = 3,
#   delay = 1,
#   max_pages = 3
# )
# 
# glimpse(women_test)
# 
# women_test %>%
#   select(
#     sex_series,
#     series_page,
#     archive_image_id,
#     crowd_id,
#     Løbenr,
#     Navn,
#     `Diagnose ved indlæggelsen`
#   ) %>%
#   print(n = Inf)
# 
# #potential CSV for inspection
# write_csv(
#   women_test,
#   file.path("..", "data", "raw", "risskov_women_test_3pages.csv"),
#   na = ""
# )

#-------------------------------------------------------------------

# # testing the men series scraper on three pages
# men_test <- scrape_series(
#   start_url = men_start_url,
#   sex_series = "men",
#   start_page = 3,
#   delay = 1,
#   max_pages = 3
# )
# 
# glimpse(men_test)
# 
# men_test %>%
#   select(
#     sex_series,
#     series_page,
#     archive_image_id,
#     crowd_id,
#     Løbenr,
#     Navn,
#     `Diagnose ved indlæggelsen`
#   ) %>%
#   print(n = Inf)
# 
# #potential CSV for inspection
# write_csv(
#   men_test,
#   file.path("..", "data", "raw", "risskov_men_test_3pages.csv"),
#   na = ""
# )
#-------------------------------------------------------------------

# scraping the complete women series
women_raw <- scrape_series(
  start_url = women_start_url,
  sex_series = "women",
  start_page = 3, #excluding first two pages
  delay = 1,
  max_pages = 203 #excluding last two pages
)


# scraping the complete men series
men_raw <- scrape_series(
  start_url = men_start_url,
  sex_series = "men",
  start_page = 3, #excluding first two pages
  delay = 1,
  max_pages = 205 #excluding last two pages
)


# combining both series
risskov_raw <- bind_rows(
  women_raw,
  men_raw
)


#saving to a CSV file:
write_csv(
  women_raw,
  file.path("..", "data", "raw", "risskov_women_1889_1913_raw.csv"),
  na = ""
)

write_csv(
  men_raw,
  file.path("..", "data", "raw", "risskov_men_1889_1913_raw.csv"),
  na = ""
)

write_csv(
  risskov_raw,
  file.path("..", "data", "raw", "risskov_1889_1913_raw.csv"),
  na = ""
)

# 
# # saving an R-native copy to preserve the raw object exactly
# saveRDS(
#   women_raw,
#   file.path("..", "data", "raw", "women_1889_1913_raw.rds")
# )
# 
# saveRDS(
#   men_raw,
#   file.path("..", "data", "raw", "men_1889_1913_raw.rds")
# )
# 
# saveRDS(
#   risskov_raw,
#   file.path("..", "data", "raw", "concat_1889_1913_raw.rds")
# )

# basic checks of extracted corpus
cat("\nWomen:", nrow(women_raw), "patient records\n")
cat("Men:", nrow(men_raw), "patient records\n")
cat("Total:", nrow(risskov_raw), "patient records\n")

cat(
  "\nWomen pages containing patient records:",
  n_distinct(women_raw$archive_image_id),
  "\n"
)

cat(
  "Men pages containing patient records:",
  n_distinct(men_raw$archive_image_id),
  "\n"
)

cat(
  "Unique patient numbers:",
  n_distinct(risskov_raw$Løbenr),
  "\n"
)