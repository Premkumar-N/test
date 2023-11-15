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

# Function to extract Spring and its dependencies from a WAR file
get_spring_versions() {
  war_file="$1"
  temp_dir=$(mktemp -d)
  
  # Extract the contents of the WAR file
  unzip -q "$war_file" -d "$temp_dir"
  
  # Search for Spring and its dependencies
  spring_versions=$(grep -o -E 'spring-framework-(.*?).jar' -r "$temp_dir" | sed 's/.*-\(.*\).jar/\1/' | sort -u)
  
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
  component_name=$(basename "$url" | sed 's/\.war$//')
  
  # Download the WAR file
  wget -q "$url" -O "$component_name.war"
  
  # Get Spring versions from the downloaded WAR file
  spring_versions=$(get_spring_versions "$component_name.war")
  
  # Append the information to the output file
  echo -e "$component_name\t$spring_versions" >> "$output_file"
done < "$url_file"

# Email the report
cat "$output_file" | mail -s "$email_subject" "$email_recipient"

# Clean up downloaded WAR files
rm -f *.war
