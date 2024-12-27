#!/bin/bash

# Create output file
output_file="repository_contents.md"

# Write header
echo "# Repository Contents" > $output_file
echo "" >> $output_file

# Generate tree structure
echo "## File Structure" >> $output_file
echo '```' >> $output_file
tree -I "node_modules|.git|*.xcodeproj|*.xcworkspace|*.framework|build|DerivedData|*dictionary*" . >> $output_file
echo '```' >> $output_file
echo "" >> $output_file

# Function to detect file type
get_file_type() {
    case "$1" in
        *.swift) echo "swift";;
        *.json) echo "json";;
        *.md) echo "markdown";;
        *.txt) echo "text";;
        *.h) echo "objectivec";;
        *.m) echo "objectivec";;
        *.plist) echo "xml";;
        *) echo "";;  # Return empty for unknown types
    esac
}

# Function to check if file is text
is_text_file() {
    file "$1" | grep -q "text"
}

# Add all file contents
echo "## File Contents" >> $output_file

# Find all files and sort them
find . -type f \
    -not -path '*/\.*' \
    -not -path '*/build/*' \
    -not -path '*/DerivedData/*' \
    -not -path '*.xcodeproj/*' \
    -not -path '*.xcworkspace/*' \
    -not -path '*.framework/*' \
    -not -name '*.png' \
    -not -name '*.jpg' \
    -not -name '*.jpeg' \
    -not -name '*.gif' \
    -not -name '*.pdf' \
    -not -name '*.zip' \
    -not -name '*dictionary*' \
    | sort | while read -r file; do
    
    # Skip the output file itself and dictionary files
    if [ "$file" = "./$output_file" ] || [[ "$file" == *"dictionary"* ]]; then
        continue
    fi
    
    # Only process text files
    if is_text_file "$file"; then
        echo "" >> $output_file
        echo "### $file" >> $output_file
        echo "" >> $output_file
        
        # Get file type for markdown formatting
        file_type=$(get_file_type "$file")
        
        if [ ! -z "$file_type" ]; then
            echo "\`\`\`$file_type" >> $output_file
        else
            echo "\`\`\`" >> $output_file
        fi
        
        cat "$file" >> $output_file
        echo "\`\`\`" >> $output_file
    fi
done

echo "Generated repository contents in $output_file" 