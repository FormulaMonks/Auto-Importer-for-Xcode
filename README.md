# Auto Importer for Xcode

Quickly import your headers on the fly while typing.

## Features

- Allow to import a class/protocol by selecting some text.
- Allow to pick from the list of all classes/protocols and headers in your project.

![Menu](https://github.com/lucholaf/Auto-Import-for-Xcode/raw/master/demo.gif)

## Prerequisites

- Xcode 6

## Install

Clone and build the project, then restart Xcode.

# User guide

- ⌘ + ctrl + H after selecting some text (or you can have no selection at all)
- If the selected text matches the name of a class/protocol it will import the header, otherwise it will show a list of filtered identifiers and headers.
- start typing the keyword of your import
- use ↑ or ↓ keys to navigate
- press ↵ or double click to add an import

## Uninstall

Run `rm -r ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/AutoImporter.xcplugin/`

## Known Issues

- When two workspaces (and thus two windows) are open, there is no distinction between workspaces so all identifiers are shown on the listing.

## Roadmap

- Read framework headers.
- Index categories and their methods.

## Misc

Thanks to the Peckham project (https://github.com/markohlebar/Peckham.git) since I used some pieces from it to speed up.