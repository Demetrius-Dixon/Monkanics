**Please note that I (Demetrius Dixon) specialize in game development (programming & design), rather than pure software development. They're 2 separate things. So if this repo seems less technical with very little command line usage, that's why.**

### Contributing to Monkanics (Doc is a WIP)

Monkanics is open source under a dual license:
- Code under AGPLv3 and (See `CODE_LICENSE`)
- Art under CC BY-NC-SA 4.0 (See `ART_LICENSE`). 

Monkanics is developed in **Godot version 4.7 in GDscript only** (so, no C#/GDextention)

Monkanics' project file can be downloaded on any operating system Godot 4 natively supports. However, the game was built for Windows and Linux first. Mac development is quite rocky and Web + Mobile development was not supported.

Contributions of any kind are welcome: bug reports, code, art, playtesting feedback, localization, etc. However, development is too early for frequent non-development commits until further notice.

### Pull Request Rules:

*These are very strict rules that, if broken, will have your pull request rejected. All rules are subject to change:*

1. *Absolutely positively **DO NOT** edit the `ART_LICENSE` and `CODE_LICENSE` files under any circumstances!!!* I'm not a lawyer, but we NEED those files.
2. *Do not edit or remove a listing in the `CREDITS_AND_CONTRIBUTORS` or `SPECIAL_THANKS` files that isn't yours*. That's pretty messed up.
3. *Do not edit the `README` file unless it's for grammar errors*.
4. *Do not submit joke pull requests with no actual changes/additions*.
5. *Do not submit AI generated code or art of any kind*. Direct AI output is insanely sloppy and disjointed. Please use your human touch when making commits. We are strictly anti-AI.
6. *English only*. I cannot read other languages.
7. *GDscript only*. I cannot maintain that code.
8. *Exclude any addons/plugins you use in your commit*. For example, I use the script-IDE plugin for a better GDscript editor, but I exclude it from the codebase to keep the build as vanilla as possible. Please do the same.
9. *Do not add code or art that you do not own nor do not have a license to use*. We cannot afford a lawyer.
10. *Please keep pull requests to 1 features/change at a time*. This makes pull requests a LOT easier to merge and keep track of.

*Also, every commit is a case-by-case basis. So a pull request could be rejected outside of these rules. We'll always provide an explanation if this is the case.*

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

- Main Game (Windows) (Runnable)
- Main Game (Linux) (Runnable)
- Relay Router (Linux)

The 2 main game files for Windows and Linux are playable versions set to x86_64 by default. The archetecture can easily be changed to x86_32 or arm in the export menu.

The Relay Router is an instance of Monkanics' relay server. The key to it's multiplayer working. It is exported as a *dedicated_server*. Meaning all the visuals are stripped and unnesesary gameplay elements will be queued_free by the codebase. 

The PCK for the Relay Router is also embedded by default, but this **IS NOT** a DRM measure, but instead a way to make file porting a lot easier when going to cloud servers for deployment.

### Deploying a Relay Server For Monkanics:

*This section will be filled out later. As I have to rewrite the gameplay netcode for Monkanics version 0.2*

### Credit

Contributors are added to `CREDITS_AND_CONTRIBUTORS`. You can add yourself to the txt file in your commit if you'd like.

Or, you'd rather use an alias or outright not be listed, just let us know.

Also, you can add whoever or whatever you want to the `SPECIAL_THANKS` file.
