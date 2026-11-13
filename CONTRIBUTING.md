# Contributing to Monkanics

Monkanics is officially developed in **Godot version 4.7+ in GDscript only** (No C#/GDextention)

Monkanics' project file can be downloaded on any operating system Godot 4 natively supports. However, the game was built for Windows and Linux first. Mac and Web and not supported natively.

Collaboration is a mix of unpaid volunteer work and paid commissions. 

Monkanics is primarily developed as a *game*, not a piece of independent software.

# Pull Request Disclaimers:

By submitting a pull request to the Monkanics repository, you agree to the following:

1. Your submitted code will be licensed under the copyleft AGPLv3 (See `CODE_LICENSE`).
2. Your submitted art will be licensed under the CC BY-NC-SA 4.0 (See `ART_LICENSE`).
3. Once merged, the code/assets are officially licensed and owned by Wackshop Games LLC.
4. We reserve the right to modify and remove content at our discretion. License restrictions do not apply to the current copyright holders of Monkanics.

# Where to Begin

**Start by submitting an application to join the official Wackshop Games Discord Server:** (https://discord.gg/yMHaKU3Pnt). It’s where all collaboration and communication is done and required for serious pull requests.

To be eligible to join, you must have the following:

1. A compatible skill (Programming, 2D illustration, 3D modeling, rigging, sound design, music composition, game design, etc)
2. Be good enough at that skill and willing to learn alongside us.
3. An attempted contribution to the Monkanics repo, a DM with a proposition to the game director (Discord: demetriusdixon), or the game director inviting you directly. 

# Repo Branches

Monkanics’ repo is split into 2 branches:

1. `development`. The default branch and where all of your pull requests should be going.
2. `live`. The stable branch that is released and players play.

Make sure you put your pull request in the `development branch`. All pull requests for `live` will be rejected.

# How to Make a Pull Request

These instructions assume you use *Github Desktop* and NOT the command line. Using Github Desktop is significantly easier and is the official workflow for Monkanics development.

How to pull request from Github Desktop:

1. Download and install Github Desktop if you haven’t already.
2. Create your fork on the Monkanics repo on the web.
3. Clone your fork by pressing `< > Code` -> `Open in Github Desktop`.
6. Make your file changes.
6. On Github Desktop, commit your changes and create a pull request for the `development` branch.
7. Communicate your changes on Github and the Wackshop Games Discord.
8. Await review.

# Pull Request Rules:

**General Disclaimers:**

- Every pull request is case-by-case. So a pull request could be accepted or rejected outside of these rules/guidelines. We'll always provide an explanation if this is the case.

- These rules only apply to the official version of Monkanics. Not forks or other unofficial versions of Monkanics. Please contact the fork owner for their own rules or make your own fork with your own rules.*

- Please view the official documentation of Godot 4.7+. Either via within the engine or via the website (https://docs.godotengine.org/en/4.7/). It is an invaluable tool for Godot developers like yourself!

- *Code and art pull requests also differ significantly.* Please read carefully before you make a pull request and communicate your changes to the Wackshop Games Discord (https://discord.gg/yMHaKU3Pnt).

**Acceptable Code Pull Requests**

1. Every pull request must focus on 1 change at a time. If you have multiple features/fixes, please split them up into separate pull requests.
2. No 100% vibecoded code. More specifically, no code that you cannot explain nor maintain yourself. Make sure you can debug and take responsibility for everything you submit, regardless of whether AI tools were used.
3. GDscript only. No C# or GDextention.
4. No major rewrites without prior communication in the Wackshop Games discord.
5. No malicious code (Malware, spyware, ransomware, etc).
6. No changes can be made to root files like `README`, `CONTRIBUTING`, `CODE_LICENSE`, `ART_LICENSE`, etc.
7. Please exclude any and all addons/plugins you’ve used that aren’t a part of the base repo. We do not want any external dependencies unless they are absolutely necessary.
8. All code must follow the official GDscript style guide (https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
9. No balance change pull requests are allowed. Game balance is a sensitive design issue that must be properly playtested before being changed. If you’d like to test your balance ideas, please fork Monkanics.

**Acceptable Art Pull Requests**

1. **All art must be submitted directly to the Wackshop Games Discord for inspection before being merged.** (https://discord.gg/yMHaKU3Pnt)
2. No AI-generated or AI-assisted “artwork”.
3. All art must match Monkanics’ art direction and be of acceptable standard.
4. Raw files of your art must be provided for the source file repo.

# Credit

Contributors are added to the `CREDITS` file. Please add yourself to the credits in your commit to save us some time.

If you'd rather use an alias or want to change your name, add/change that name instead.

If you’d rather outright not be listed, just let us know.

# Pay

All volunteer work is unpaid. However, if you possess an above-average level of skill with art, we’ll consider commissioning you for a specific deliverable.

Deliverables are required to be requested directly by the game director. The deliverable must be agreed upon and the full payment be made by us before you begin paid work. Do not request pay for work that has already been completed and/or merged.

Since Monkanics is free-to-play and Wackshop Games is on a low-budget, the game needs to be cheap to make and maintain.

**Payout Disclaimers:**

1. Payouts vary by complexity.
2. Payouts are on a case-by-case basis.
3. Base payout rates are subject to change.
4. Some payout rates are unknown due to insufficient knowledge and will be updated later.
5. Currency is also converted to their equivalent value if the commissioner is not from the United States. We do not adjust rates for non-US economies.
6. Please do not rely on Wackshop Games alone for your income. Work assignments are on a need-to-do basis only.

**Deliverable Payouts**

- *Programming: $??? - $??? USD*

- 2D Character: $50 - $75 USD
- 2D Object: $25 - $50 USD
- *2D Environment: $??? - $??? USD*
- *2D Game Texture: $??? - $??? USD*

- 3D Character: $75 - $150 USD
- 3D Object: $40 - $75 USD
- *3D Environment: $??? - $??? USD*
- *3D Rig: $??? - $??? USD*
- *3D Animation: $??? - $??? USD*

- *Sound Effect: $??? - $??? USD*
- *Music Track: $??? - $??? USD*

Money is paid via Wise, or if that doesn’t work, PayPal. 

Wise is MUCH preferred because of its lower fees and 1:1 currency conversion (You get paid more). Please make personal Wise and Paypal accounts in advance to save us some time.

# Monkanics Documentation

*Documentation for Monkanics' codebase, game design, trivia, and more is a WIP and not available at the moment. This section will be filled out later.*

# Monkanics Raw Asset Repo

This repository stores the raw game assets. This needs to be a separate repo, as putting large non-game files into the main repo takes up too much space and bloats the player download.

*This repo is not available at this time, as it’s currently a WIP.*

# Development Authority

Wackshop Games directs all official Monkanics development. And is led by the current game director.

1. The game director has final authority over creative, technical, and development decisions.
2. Contributors must follow project specifications and direction.
3. Contributions, suggestions, and proposed changes do not guarantee acceptance.
4. Contributors cannot independently establish official game features or change the project's direction.

# Collaboration Expectations

Contributors are expected to communicate properly with the game director and the rest of the team.

1. Communicate when you're unavailable.
2. Don't accept assignments you cannot reasonably complete.
3. Keep the game director informed about progress.
4. Be receptive to constructive criticism from all users.
5. Don't disappear halfway through an assignment without communicating.
6. Respect other contributors and maintain professional conduct.

# Closing Statements

Now, I know this all sounds like a bureaucratic nightmare, but Wackshop Games is a tiny studio run by a random dude from Ohio. 

**Anyone can contribute to Monkanics, fork Monkanics to create their own experiences, and have fun creating and playing.**