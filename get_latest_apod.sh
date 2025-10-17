#!/bin/bash

# Set today's date string
daysago=0
day=$(date -v-${daysago}d +%y%m%d)

if ls | grep -q "$day"; then
  exit 1
fi 

echo "Looking up APOD for $day..."

# Set APOD website URL
url=https://apod.nasa.gov/apod

# Set APOD subdir for date 
subdir=ap$day.html

# Get page source for image and description
pagesrc=$(curl $url/$subdir)

# Obtain image path from website <a> tag
imgsrc=$(echo "$pagesrc" | /opt/homebrew/bin/htmlq 'a' | grep -B 5 '<img' | grep -v html | /opt/homebrew/bin/htmlq 'a' --attribute href)

# Obtain image description from website <p> tag
imgdesc=$(echo "$pagesrc" | /opt/homebrew/bin/htmlq 'p' | awk '/<b> Explanation: <\/b>/ {flag=1} flag; /<\/p>/ && flag {flag=0}'|
perl -0777 -pe '
BEGIN { our %F; our $n = 1; our $base_url = shift @ARGV; }
# Remove HTML tags and convert links to footnotes
s{<a\s+href="([^"]+)"[^>]*>(.*?)</a>}{
  my $url = $1;
  my $t = $2;
  if ($url !~ /^https/i) {
    $url = $base_url . $url;
  }
  $F{$n} = $url;
  my $out = $t . "[" . $n . "]";
  $n++;
  $out
}gse;
# Remove HTML tags
s{</?b>}{}g;
s{</?p>}{}g;
# Trim whitespace
s/^\s+//mg;
# Remove double-spacing
s/\n{2,}/\n/g;
' -e '
# Replace all newlines with spaces in the main body
$_ =~ s/\n/ /g;
END {
  print $_;  # main body as a single line with spaces
  print "\nFootnotes:\n";
  for my $i (1..$n-1) {
    print "[$i]: $F{$i}\n" if exists $F{$i};
  }
}
' "$url")

# Extract image's filename + extension
filename="${imgsrc##*/}"

if [ -z "${filename}" ]; then
  echo "No image found for $day."
  exit 1
fi

echo "Downloading $filename from APOD website..."

# Download the file
curl $url/$imgsrc -o "$day-$filename"

echo "Done."

echo "$imgdesc"
echo "~~~~~~~~~~~~~~~~~~~~~"
