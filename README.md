# Auto Importer for Xcode

Quickly import your headers on the fly while typing.

## Features

- Allows to import a class/protocol by selecting some text.
- Allows to pick from the list of all classes/protocols and headers in your project.

![](demo.gif)

## Prerequisites

- Xcode 6

## Install

Clone and build the project, then restart Xcode.

## Usage

- ⌘ + ctrl + H after selecting some text (or you can have no selection at all)
- If the selected text matches the name of a class/protocol it will import the header and you're done, otherwise it will show a list of filtered identifiers and headers.
- start typing the keyword of your import
- use ↑ or ↓ keys to navigate
- press ↵ or double click to add an import

## Uninstall

Run `rm -r ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/AutoImporter.xcplugin/`

## Known Issues

- When two workspaces (and thus two windows) are open, there is no distinction between workspaces and all identifiers are shown on the listing.
- Avoid using 'InstallApplicationEventHandler' since it void other plugins to use it.

## Roadmap

- Read framework headers.
- Index categories and their methods.

## Misc

Thanks to the Peckham project (https://github.com/markohlebar/Peckham.git) since I used some pieces from it.