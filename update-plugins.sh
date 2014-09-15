#!/bin/sh
 
PLIST_BUDDY=/usr/libexec/PlistBuddy
 
function add_compatibility() {
  "$PLIST_BUDDY" -c "Add DVTPlugInCompatibilityUUIDs:10 string $2" \
    "$1/Contents/Info.plist"
}
 
function has_compatibility() {
  $PLIST_BUDDY -c 'Print DVTPlugInCompatibilityUUIDs' \
    "$1/Contents/Info.plist"|grep -q "$2"
  return $?
}
 
cd "$HOME/Library/Application Support/Developer/Shared/Xcode/Plug-ins"
 
for file in `ls -d *`
do
 
  if `has_compatibility "$file" C4A681B0-4A26-480E-93EC-1218098B9AA0`
  then
    true
  else
    echo "Plugin $file is now compatible with Xcode 6.0 GM"
    add_compatibility "$file" C4A681B0-4A26-480E-93EC-1218098B9AA0
  fi
done