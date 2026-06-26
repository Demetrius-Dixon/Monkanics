**Please note that I (Demetrius Dixon) specialize in game development (programming & design), rather than pure software development. They're 2 separate things. So if this documentation seems less technical with very little command line usage, that's why.**

*Also, please view the official documentation of Godot 4.7+. Either via within the engine or via the website (https://docs.godotengine.org/en/stable/). It is an invaluble tool for Godot developers*

### Monkanics Codebase Documentation (Doc is a WIP)

This file details how Monkanics' codebase operates. While most folders, files, and functions are self-explanatory via their name, the way they connect aren't.

Feel free to reference this offline copy whenever you're working with the files.

### Monkanics' Lisences

Monkanics is open-source under a dual license:
- Code under AGPLv3 and (See `CODE_LICENSE`)
- Art under CC BY-NC-SA 4.0 (See `ART_LICENSE`). 

Monkanics is also developed using the Godot Engine:
- Godot is MIT licensed (See `GODOT_LICENSE`)
- Godot's external dependencies have an exhaustive list of licenses which are updated once per year on January 1st (See `GODOT_COPYRIGHT`)
- **Please keep in mind that you will not have to worry about these licenses when forking Monkanics. Just keep the files in the project folder like the other licenses and you'll be fine.**

### Cloning Monkanics' Source Code

*Will be filled out later*

### Exporting Monkanics On Your Machine:

**EXPORT TEMPLATES AND EXPORT PRESETS ARE 2 DIFFERENT THINGS!!!**

- Export Templates are Godot's pre-compiled binaries of the engine *saved on your computer globally, and NOT in the Monkanics project files*. You'll need to download or import them the first time you export Monkanics on a new machine.
- Export Presets are Monkanics' pre-set settings for exporting and *are saved in the project files*.

**It is highly recommended to only export Monkanics using the following export templates. As Monkanics was built for Windows and Linux PCs by default:**

- Windows x86_64
- Linux x86_64

Exporting for 32-bit systems or ARM is theoretically possible, but is not supported by default.

Exporting for Mac, Web, and especially Mobile will result in **SERIOUS compatibility issues**. 

*However, the project files are free to modify. So if you'd like to give yourself a challenge, you can attempt to port Monkanics there yourself. Just let us know how you did it.*

**Monkanics' Export Presets:**

There are currently 3 export presets found in the `export_presets` file:

- Main Game (Windows) [x86_64] (Runnable)
- Main Game (Linux) [x86_64] (Runnable)
- Ingest Server (Linux only) [x86_64]
- Relay Server (Linux only) [x86_64]

The 2 main game files for Windows and Linux are playable versions set to x86_64 by default. The archetecture can easily be changed to x86_32 or arm in the export menu, but keep in mind that support for 32-bit and ARM platforms aren't supported by default.

The ingest and relay exports are instances of Monkanics' multiplayer archetecture.

The PCK for the servers is also embedded by default, **this IS NOT a DRM measure**, but instead a way to make file porting a lot easier when going to cloud servers for deployment.

### Export Feature Tags:

*Will fill in later*

### Deploying a Relay Server For Monkanics:

*This section will be filled out later. As I have to rewrite the gameplay netcode for Monkanics version 0.2*