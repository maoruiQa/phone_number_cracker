#!/bin/bash

# Help command
if [ "$1" = "--help" ]; then
    echo "Usage: $(basename $0) [hash_file.hc22000] [--region code]"
    echo
    echo "Available regions:"
    echo "  cn    China (11 digits)"
    echo "  us    United States (10 digits)"
    echo "  de    Germany (11 digits)"
    echo "  tw    Taiwan (10 digits)"
    echo
    echo "Examples:"
    echo "  $(basename $0) test.hc22000                     use the default region --- China"
    echo "  $(basename $0) test.hc22000 --region us"
    echo "  $(basename $0) --regions                        list all supported regions"
    exit 0
fi

# Regions list command
if [ "$1" = "--regions" ]; then
    echo "Supported regions:"
    echo "  cn - China"
    echo "  us - United States"
    echo "  de - Germany"
    echo "  tw - Taiwan"
    exit 0
fi

# Validate input file
if [ -z "$1" ]; then
    echo "Error: No hash file specified"
    echo "Use --help for usage information"
    exit 1
fi

hash_file="$1"
if [ ! -f "$hash_file" ]; then
    echo "Error: File $hash_file not found"
    exit 1
fi

# Set default region and check for region parameter
region="cn"
if [ "$2" = "--region" ]; then
    if [ -z "$3" ]; then
        echo "Error: No region specified after --region"
        exit 1
    fi
    region="$3"
fi

# Define prefixes for each region
prefixes_cn="139 138 137 136 135 134 147 150 151 152 157 158 159 182 183 187 188 198 130 131 132 155 156 185 186 166 133 153 180 181 189 191 199"
prefixes_us="201 202 203 212 213 214 310 312 315 516 617 718 805 818 909"
prefixes_de="151 152 153 160 162 163 170 171 172 173 175 176 177 178"
prefixes_tw="02 07 04 03 05"

# Set mask length based on region
declare -A mask_lengths=(
    ["cn"]=8
    ["us"]=7
    ["de"]=8
    ["tw"]=8
)

mask_length=${mask_lengths[$region]}

# Validate region
if [[ ! " cn us de tw " =~ " $region " ]]; then
    echo "Error: Invalid region code: $region"
    echo "Use --regions to see available region codes"
    exit 1
fi

# Set active prefixes based on region
active_prefixes="prefixes_${region}[@]"
active_prefixes="${!active_prefixes}"

echo "Testing $region phone numbers..."
echo "Using prefixes: $active_prefixes"
temp_result="result.txt"
rm -f "$temp_result"

# Process each prefix
for prefix in $active_prefixes; do
    echo "Testing prefix: $prefix"
    mask="$prefix"
    for ((i=1; i<=mask_length; i++)); do
        mask="${mask}?d"
    done
    
    hashcat -a 3 -m 22000 "$hash_file" "$mask" --potfile-disable -o "$temp_result" -w 3
    
    if [ -f "$temp_result" ] && [ -s "$temp_result" ]; then
        echo "Found password: $(cat $temp_result)"
        rm -f "$temp_result"
        echo "Test completed successfully"
        exit 0
    fi
    rm -f "$temp_result"
done

echo "Password not found for region: $region"
exit 1
