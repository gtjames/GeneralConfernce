#!/bin/zsh
# Check if search string is provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <year> <month> <searchPhrase>"
  echo "Usage: $0 2023 04/10 garments"
  exit 1
fi

year="${1}"
month="${2}"

url="https://www.churchofjesuschrist.org/study/general-conference/${1}/${2}?lang=eng"

searchPhrase="$3"
outputDir="subjects/$3"  # Create a temporary directory for output files

mkdir -p "$outputDir"

# Function to extract links from the HTML content
extractLinks() {
  local content="$1"
  echo "$content" | xmllint --html --xpath '//a/@href' - 2>/dev/null | sed -e 's/href="\([^"]*\)"/\n\1\n/g' | grep -v '^$'
}

# Function to download the content of a URL
downloadPage() {
  local url="$1"
  curl -sL "$url" -o nextPage.html
  cat nextPage.html
}

# Function to extract the title of the HTML content
extractAttr() {
    local class="$1"
    local content="$2"
    echo "$content" | xmllint --html --xpath "string(//*[@class='$class'])" - 2>/dev/null
}

# Function to extract the title of the HTML content
extractTitle() {
  local content="$1"
  echo "$content" | xmllint --html --xpath 'string(//title)' - 2>/dev/null
}

# Function to search for the phrase in the content
searchPhrase() {
  local content="$1"
  local phrase="$2"
  echo "$content" | grep -ni "$phrase"
}

# Function to reduce the number of links found to just the unique URLs
uniqURLs() {
  local content="$1"
  echo "$content" | sort | uniq
}

# Download the main page content
main_page_content=$(downloadPage "$url")

# Extract links from the main page content
dblLinks=$(extractLinks "$main_page_content")
links=$(uniqURLs "$dblLinks")
# echo "All Links $links" >> zlink.txt

# Process each link
for link in ${(f)links}; do           # while IFS= read -r link; do
  # Skip if the link is empty or not an HTTP/HTTPS URL
  link="https://www.churchofjesuschrist.org${link}"

  if [[ -z "$link" || ! "$link" =~ ^https?:// ]]; then
    continue
  fi

  # Download the linked page content
  pageContent=$(downloadPage "$link")

  # Extract the title
  title=$(extractTitle "$pageContent")
  title_safe=$(echo "$title" | sed 's/[\/:*?<>|]/_/g')  # Make title safe for filenames
  title_safe=$(echo "$title_safe" | tr -d '“”')
  cp nextPage.html "./talks/$title_safe.html"

  # Search for the phrase
  matches=$(searchPhrase "$pageContent" "$searchPhrase")

  # Save results to file if matches are found
  if [ -n "$matches" ]; then
    author=$(extractAttr "author-name" "$pageContent")
    kicker=$(extractAttr "kicker" "$pageContent")
    role=$(extractAttr "author-role" "$pageContent")

    output_file="$outputDir/${year}-${month}-${title_safe}.html"
    {
      echo "<html><head><title>$title</title></head><body>"
      echo "<a href=$link>$title</a>"
      echo "<h2>Title: $title</h2>"
      echo "<h2>Author: $author</h2>"
      echo "<h2>Role: $role</h2>"
      echo "<h3>Description: $kicker</h3>"
      echo "<p>$matches</p>"
      echo "</body></html>"
    } > "$output_file"
    echo "Results saved to $output_file"
  fi
done          # done <<< "$links"

echo "Processing completed. Results saved in $outputDir"
rm nextPage.html
