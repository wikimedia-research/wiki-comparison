if (!dir.exists("data")) dir.create("data")

curl::curl_download(
  "https://docs.google.com/spreadsheets/d/1a-UBqsYtJl6gpauJyanx0nyxuPqRvhzJRN817XpkuS8/export?format=xlsx&id=1a-UBqsYtJl6gpauJyanx0nyxuPqRvhzJRN817XpkuS8",
  "data/features.xlsx"
)

wiki_segmentation_public_data <- readxl::read_xlsx("data/features.xlsx")
readr::write_csv(wiki_segmentation_public_data, "data/features.csv")

wiki_segmentation_data_dictionary <- readr::read_csv("https://docs.google.com/spreadsheets/d/1a-UBqsYtJl6gpauJyanx0nyxuPqRvhzJRN817XpkuS8/export?format=csv&id=1a-UBqsYtJl6gpauJyanx0nyxuPqRvhzJRN817XpkuS8&gid=1801438307", skip = 1)
readr::write_csv(wiki_segmentation_data_dictionary, "data/dictionary.csv")
