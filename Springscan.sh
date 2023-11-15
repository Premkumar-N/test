#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <url_file>"
  exit 1
fi

url_file="$1"
output_file="spring_versions_table.txt"
email_recipient="your@email.com"
email_subject="Spring Versions Report"

# Function to extract Spring and its dependencies from a ZIP, WAR, or TAR file
get_spring_versions() {
  file="$1"
  temp_dir=$(mktemp -d)

  # Check if the file is a ZIP, WAR, or TAR
  if unzip -t "$file" &> /dev/null; then
    # It's a ZIP file
    unzip -q "$file" -d "$temp_dir"
  elif tar tf "$file" &> /dev/null; then
    # It's a TAR file
    tar xf "$file" -C "$temp_dir"
  elif [ "${file##*.}" == "war" ]; then
    # It's a WAR file
    unzip -q "$file" -d "$temp_dir"
  else
    echo "Unsupported file format: $file"
    rm -rf "$temp_dir"
    return
  fi

  # Check if a WAR file is found
  war_file=$(find "$temp_dir" -name "*.war" -print -quit)

  if [ -z "$war_file" ]; then
    echo "Invalid URL: No WAR file found in $file"
    rm -rf "$temp_dir"
    return
  fi

  # Extract the found WAR file
  unzip -q "$war_file" -d "$temp_dir"

  # Search for Spring JARs specifically in WEB-INF/lib
  spring_versions=$(grep -o -E 'WEB-INF/lib/spring-framework-(.*?).jar' -r "$temp_dir" | sed 's/.*-\(.*\).jar/\1/' | sort -u)

  # Clean up temporary directory
  rm -rf "$temp_dir"

  if [ -n "$spring_versions" ]; then
    echo "$spring_versions"
  else
    echo "No spring used"
  fi
}

# Process each URL in the file
while IFS= read -r url; do
  # Get the component name from the URL (assuming it ends with the component name)
  component_name=$(basename "$url" | sed 's/\.[^.]*$//')

  # Download the ZIP, WAR, or TAR file
  wget -q "$url" -O "$component_name.file"

  # Get Spring versions from the downloaded file
  spring_versions=$(get_spring_versions "$component_name.file")

  # Append the information to the output file
  echo -e "$component_name\t$spring_versions" >> "$output_file"
done < "$url_file"

# Email the report
cat "$output_file" | mail -s "$email_subject" "$email_recipient"

# Clean up downloaded files
rm -f *.file
