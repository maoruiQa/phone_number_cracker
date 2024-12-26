#!/bin/bash

# Function to display usage help
usage() {
    echo "Usage: $0 [options] <hc22000 file>"
    echo
    echo "Options:"
    echo "  --help          Show this help message"
    echo "  --country       Specify country for phone number format (e.g., china, usa, germany)"
    echo "  --list-countries List all supported countries"
    echo "  <hc22000 file>  Path to the hc22000 hash file to crack"
    echo
    echo "Example:"
    echo "$0 --country china /path/to/your/hc22000/file"
    exit 1
}

# Check if hashcat is installed
if ! command -v hashcat &> /dev/null; then
    echo "hashcat is not installed. Please install hashcat first."
    exit 1
fi

# Define country-specific phone number prefixes
declare -A country_prefixes
# China (9+ digit numbers)
country_prefixes["china"]=(
    "139" "138" "137" "136" "135" "134" "147" "150" "151" "152" "157" "158" "159" "182" "183" "187" "188" "198"
    "130" "131" "132" "155" "156" "185" "186" "166"
    "133" "153" "180" "181" "189" "191" "199"
)
# USA (10-digit numbers)
country_prefixes["usa"]=(
    "201" "202" "203" "212" "213" "214" "310" "312" "315" "516" "617" "718" "805" "818" "909"
)
# Germany (11-digit numbers)
country_prefixes["germany"]=(
    "151" "152" "153" "160" "162" "163" "170" "171" "172" "173" "175" "176" "177" "178"
)

# Define expected phone number lengths
declare -A country_lengths
country_lengths["china"]=11
country_lengths["usa"]=10
country_lengths["germany"]=11

# Function to run hashcat with the provided prefix
run_hashcat_with_mask() {
    local prefix="$1"
    local mask="$2"
    echo "Cracking using prefix: $prefix"
    
    # Run hashcat with the mask attack
    if ! hashcat -m 22000 -a 3 "$hash_file" "$prefix$mask" --force --potfile-disable; then
        echo "hashcat encountered an error with prefix: $prefix"
        return 1
    fi
    
    # Check if password was found
    if hashcat --show -m 22000 "$hash_file" | grep -q .; then
        echo "Password found!"
        hashcat --show -m 22000 "$hash_file"
        exit 0
    fi
    
    return 0
}

# Function to generate a mask for arbitrary lengths
generate_mask() {
    local length="$1"
    local mask=""
    for ((i=1; i<=length; i++)); do
        mask="${mask}?d"
    done
    echo "$mask"
}

# Parse command line arguments
country="china"
hash_file=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            usage
            ;;
        --list-countries)
            echo "Supported countries:"
            echo "  - china"
            echo "  - usa"
            echo "  - germany"
            echo "  - other unsupported countries(maybe slower)"
            exit 0
            ;;
        --country)
            if [ -z "$2" ]; then
                echo "Error: --country requires a value"
                exit 1
            fi
            country="$2"
            shift 2
            ;;
        *)
            hash_file="$1"
            shift
            ;;
    esac
done

# Check if hash file is provided
if [ -z "$hash_file" ]; then
    echo "Error: You must specify a hc22000 file."
    usage
fi

# Check if hash file exists and is readable
if [ ! -f "$hash_file" ]; then
    echo "Error: File '$hash_file' does not exist."
    exit 1
fi

if [ ! -r "$hash_file" ]; then
    echo "Error: Cannot read file '$hash_file'."
    exit 1
fi

# Handle country-specific logic
if [ -z "${country_prefixes[$country]}" ]; then
    echo "The country '$country' is not supported with specific prefixes."
    read -p "Please enter the phone number length for '$country': " phone_length
    
    # Validate phone length input
    if ! [[ "$phone_length" =~ ^[0-9]+$ ]]; then
        echo "Invalid phone length. Please enter a numeric value."
        exit 1
    fi
    
    mask=$(generate_mask "$phone_length")
    echo "Using generated mask: $mask"
    run_hashcat_with_mask "" "$mask"
    exit 0
fi

# Get expected length for the country
expected_length="${country_lengths[$country]}"

# If the country has specific prefixes, use mask attack
for prefix in "${country_prefixes[$country][@]}"; do
    mask=$(generate_mask $((expected_length - ${#prefix})))
    if ! run_hashcat_with_mask "$prefix" "$mask"; then
        echo "Error occurred while processing prefix: $prefix"
        continue
    fi
done

echo "Cracking completed, but no password was found."
exit 0