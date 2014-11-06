# Auto Importer for Xcode

Quickly import your headers on the fly while typing.

## Features

- Allows to import a class/protocol/category header by selecting some text matching its name.
- Allows to import from a list of all classes/protocols/categories and headers in your project.

![](demo.gif)

## Prerequisites

- Xcode 6

## Install

#### Alcatraz

- Install [Alcatraz](https://github.com/supermarin/Alcatraz) and search for **Auto-Importer** 

#### Manual

- Clone and build the project, then restart Xcode.

NOTE: If you find a crash while typing the shortcut, it may be because of a bad bundle build, so delete `~/Library/Application Support/Alcatraz/Plug-ins/Auto-Importer` and `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/Auto-Importer` and reinstall from scratch.

## Usage

- ⌘ + ctrl + H after selecting some text (or you can have no selection at all)
- If the selected text matches the name of a class/protocol or category method, it will import the header and you're done, otherwise it will show a list of filtered identifiers and headers...
- start typing the keyword of your import
- use ↑ or ↓ keys to navigate
- press ↵ or double click to add an import

NOTE: on the list, classes are shown as [C], protocols as [P] and category methods as [ClassExtended()]

## Uninstall

Run `rm -r ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/AutoImporter.xcplugin/`

## Known Issues

- When two workspaces (and thus two windows) are open, there is no distinction between workspaces and all identifiers are shown on the listing.
- Avoid using 'InstallApplicationEventHandler' since it prevent other plugins to use it.

## Roadmap

- Read headers from frameworks.

## Misc

Thanks to the [Peckham](https://github.com/markohlebar/Peckham.git) project since I used some pieces from it.