<p align="center">
 <img width="320" alt="Smash Remix +EXTRA Summercart Edition" src=".github/sr-extra.png">
</p>

# Summercart Edition
- **NOTE: This is not an official update to the "Smash Remix" or "Smash Remix +EXTRA" projects. This fork is a workaround for Summercart support.**  
- To allow the game to work on SummerCart64 without crashing, **delayed character previews** on hover are supported for **one player at a time** when the cart is detected.
  - Delayed previews are only enabled on Summercarts; emulators retain regular character preview behavior.
  - Summercart detection for delayed previews can be disabled within `selected_preview_gate.py` by switching `PREVIEW_POLICY` from `PREVIEW_POLICY_AUTO` to `PREVIEW_POLICY_FORCE_ON` or `PREVIEW_POLICY_FORCE_OFF`.
- If you would like to download the official Smash Remix +EXTRA build, please go here instead: [Latest Release](https://github.com/joaorb64/smashremix-plus-extra/releases)
  - After you have downloaded the patch, you can use [this patcher](https://kotcrab.github.io/xdelta-wasm/) to create the rom. 

# How To Play
- If you are on MOBILE, you need an emulator that will properly run ROMs over 64MB.  
For Android, best emulator would be [Mupen64Plus-AE NIGHTLY BUILD](https://github.com/mupen64plus-ae/mupen64plus-ae)
- For PC (Windows, Linux) it's recommended to use [RMG-K](https://github.com/Jay-Day/RMG-K/releases/latest) as this emulator supports online play AND rollback.

## Prerequisites For Building Your Own Build
- Windows: [Python 3.12+](https://www.python.org/downloads/latest/pymanager), pipenv
  - pipenv gets installed automatically by build.bat - to install manually, run `python -m pip install pipenv` in a terminal
- Linux: Python 3.12+, pipenv, wine

## Setting Up Your Own Build
- Clone the repository using `git clone --recursive` (note the recursive here for it to clone the original smashremix repo as a submodule)
  - If you cloned the repo non-recursively, run `git submodule update --init --recursive` in the clone directory to initialize and update the smashremix submodule
  - If you don't have Git or downloaded this repository without it (i.e. Code -> Download ZIP), download the [Smash Remix source](https://github.com/JSsixtyfour/smashremix/archive/refs/heads/master.zip) manually and extract it's files into `smashremix`
  - Clone into a local drive location and not somewhere like OneDrive to avoid potential issues
- Copy your legal vanilla SSB64 ROM into `smashremix/roms/` as `ssb.rom`. If you have a `.z64`, just rename the extension
- Set up the Python environment: In your clone directory, run `python -m pipenv install` (automatically handled by build.bat)

## Building
**To build, simply run:**
- **Windows: `build.bat`**
  - Manual build: `python -m pipenv run character_appender.py && patch_extra.bat`
- **Linux:**
  - `pipenv run python3 character_appender.py && wine patch_extra.bat`

The build consists of two parts:
- Running `character_appender.py` which does all the magic and generates a `smashremix/roms/original_extra.z64`. This is an extension of the `/roms/original.z64` file with extra content. It also prepares the `src/` and `build/` directories
- Running `patch_extra.bat` which builds the final ROM just like Remix.

## Modding Resources
- [Modding Wiki](https://joaorb64.github.io/smash64-modding-wiki/)
- [Moveset Editor](https://github.com/joaorb64/ssb64-moveset-file-editor)
- [Scripts](https://github.com/joaorb64/smashremix-plus-extra/tree/main/scripts) for extracting characters/stages from ROM, fixing normals from Blender, projectile creation, etc. are included with +EXTRA's source.
- [Templates](https://github.com/joaorb64/smashremix-plus-extra/tree/main/templates) for various assets are included with +EXTRA's source.  

## FAQ
- **"Where do I download this MOD?"**  
Follow the **Setting Up Your Own Build** instructions above. If you would like to download the official Smash Remix +EXTRA build, please go here instead: [Latest Release](https://github.com/joaorb64/smashremix-plus-extra/releases). 
- **"Is this a new Smash Remix update?"**  
This is not an official update to the "Smash Remix" or "Smash Remix +EXTRA" projects. This fork is a workaround for Summercart support.  
- **"What is the purpose of Smash Remix +EXTRA?"**  
The "Smash Remix +EXTRA" team wanted to design a project that will allow users to add their own custom content on top of Smash Remix. They added content across the community into +EXTRA as an example, and even added new additions. Smash Remix +EXTRA is packaged with tools to assist and ease that process of importing your own work into the game.  
- **"Will this work on the original N64?"**  
This build is compatible with flashcarts with support for 78MB roms or higher (such as the Summercart or Everdrive Pro).  
- **"I found a crash?"**  
Please create an issue on GitHub and I will try to fix it!  
- **"Can you add >Insert Character Here<"**  
No, but now YOU can! This mod is designed to help anybody bring in whatever character, stage, song & additional content they want into the game.  
- **"How do I add something to this mod?"**  
You can download the source code of this mod and use the additional characters and stages as references!  
- **"Will there be future updates?"**  
I will merge in upstream updates as I have availability. You can also merge them into this fork to create your own update.  
