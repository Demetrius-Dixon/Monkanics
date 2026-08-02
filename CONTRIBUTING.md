# Contributing to Monkanics

Monkanics is developed in **Godot version 4.7+ in GDscript only** (so, no C#/GDextention)

Monkanics' project file can be downloaded on any operating system Godot 4 natively supports. However, the game was built for Windows and Linux first. Meaning Mac development is quite rocky and Web + Mobile development was not built to be supported.

## Pull Request Disclaimer:

By submitting a pull request to the Monkanics repo, you agree that your submitted code will be licensed under the copyleft AGPLv3 (See `CODE_LICENSE`) and submitted art will be licensed under the CC BY-NC-SA 4.0 (See `ART_LICENSE`).

Once merged, the code/assets are officially licensed. Meaning the public will have access to the code and art under their respective licenses.

We also reserve the right to modify and remove content at our discretion. License restrictions do not apply to copyright holders. (Demetrius Dixon and Wackshop Games)

## Where to Do a Pull Request:

Always send your pull request to the in-development branch. NEVER the main branch, as that’s the stable version of the game everyone plays.

## Pull Request Rules:

*Please note that every commit is case-by-case. So a pull request could be accepted or rejected outside of these rules/guidelines. We'll always provide an explanation if this is the case.*

* All rules and guidelines only apply to the original Monkanics repo run by Demetrius Dixon and Wackshop Games. Not your own/other’s forks/mods. Contact them for their own rules/Make your own rules.
* Please keep your pull request focused on ONE CHANGE/ADDITION ONLY. If you have multiple proposed changes/additions, separate them into separate commits. This is so we can limit technical debt and have a cleaner integration with the rest of the repo.
* English only. Use a translator if you must.
* GDscript only. We cannot maintain non-GDscript code.
* No AI-generated content. We know the topic of AI is a hot topic these days and that there’s a lot of nuance. But we cannot allow Monkanics to be filled with AI-slop. Content must be primarily made by a human.
* Do not make a pull request to change core root files like `README`, `CONTRIBUTING`, `FUNDING`, `CODE_LICENSE`, `ART_LICENSE`, etc.
* Do not submit joke pull requests with no purpose.
* Do not hide content in your pull request. All content added/changed must be disclosed.
* Do not submit offensive, political, religious, or generally divisive content in your pull request.
* Please exclude any addons/plugins you’ve used in your project files. We do not want any external dependencies unless they are absolutely necessary.
* Do not add code or art that you do not own, even if properly licensed. We cannot afford lawyers.
* Do not submit malicious code, viruses, or hacks.
* For code, please follow the official GDscript style guide. (Seen in later sections)

## What we Can and Cannot Merge

*Section to be filled out later*

## Code Style Guide

Monkanics *mostly* follows Godot's official style guide in order to align with new contributors. Please take a look before contributing code.

**View the official guide here:** (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

**Jump straight to the casing guide:** (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#:~:text=small_number%20%3D%2012_345-,Naming%20conventions,%EF%83%81,-These%20naming%20conventions)

## Credit

Contributors are added to the `CREDITS` file. You can add yourself to the txt file in your commit if you'd like.

Or, you'd rather use an alias or outright not be listed, just let us know.

## Monkanics Codebase Documentation

Documentation for Monkanics' codebase, game design, trivia, and more can be found in the `documentation` folder.

This section details how Monkanics' codebase operates. While most folders, files, and functions are self-explanatory via their name, the way they connect aren't.

Feel free to reference this offline copy whenever you're working with the files.

**Please note that I (Demetrius Dixon) specialize in game development (programming & design), rather than pure software development. They're 2 separate things. So if this documentation seems less technical with very little command line usage, that's why.**

*Also, please view the official documentation of Godot 4.7+. Either via within the engine or via the website (https://docs.godotengine.org/en/4.7/). It is an invaluble tool for Godot developers*
