# Monarchs Assignment

## Element 1:

### Data Description
Data were manually extracted from the sources listed below and encoded into a tibble in R using RStudio (v. XX). The dataset comprises Danish monarchs who reigned from c. 936 to the present, spanning the House of Gorm (c. 936–1042), House of Fairhair (1042–1047), House of Estridsen (1047–1375), House of Bjälbo (1376–1387), House of Estridsen (1387–1412), House of Griffin (1396–1439), House of Wittelsbach, Palatinate-Neumarkt branch (1440–1448), House of Oldenburg (1448–1863), and the Schleswig-Holstein-Sonderburg-Glücksburg branch (1863–present). 

Monarch names were automatically converted into unique identifiers (**monarch_id**) by transforming all characters to lowercase and replacing whitespace with underscores using regular expressions. Roman numerals were retained as lowercase letters (e.g., Christian IV → christian_iv) to distinguish between monarchs sharing the same regnal name.

Following cleaning, the final tidy monarchy CSV file contained 52 observations (monarchs) and 6 variables (monarch_name, monarch_id, date_birth, date_death, start_reign and end_reign).


### Sources
- [Britannica: list of Danish monarchs](https://www.britannica.com/topic/list-of-Danish-monarchs-2061262), accessed the 03/08-2026.

- [Wikipedia: List of monarchs of Denmark](https://en.wikipedia.org/wiki/List_of_monarchs_of_Denmark), accessed the 03/08-2026 (_Only used for the extraction of birth dates*_)


*NOTE: Some birth dates are either unknown or given as a range. Where a range is provided, the earliest year is used.

