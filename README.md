<p align="center">
 <img width="320" alt="Smash Remix +EXTRA" src=".github/sr-extra.png">
</p>

# Extra content build system

## Prerequisites
- Windows: Python 3.12+, pipenv
  - Download and install the latest python version
  - Run in a terminal (in the project directory):
    - `python -m pip install pipenv`
    - `pipenv install` (install our environment)
    - `pipenv shell` (load the environment)
- Linux: Python 3.12+, pipenv, wine

## Setting up
- Clone the repository using `git clone --recursive` (note the recursive here for it to clone the original smashremix repo as a submodule)
  - If you cloned the repo non-recursively, run `git submodule update --init --recursive` in the clone directory to initialize and update the smashremix submodule
  - Clone into a local drive location and not somewhere like Onedrive to avoid potential issues
- Copy your legal vanilla SSB64 ROM into `smashremix/roms/` as `ssb.rom`. If you have a `.z64`, just rename the extension
- Set up the Python environment: In your clone directory, run `pipenv install`

## Building
The build consists of two parts:
- Running `character_appender.py` which does all the magic and generates a `smashremix/roms/original_extra.z64`. This is an extension of the `/roms/original.z64` file with extra content. It also prepares the `src/` and `build/` directories
- Running `patch_extra.bat` which builds the final ROM just like Remix.

**To build, simply run:**
- **Windows: `build.bat`**
  - Manual steps:
    - `python -m pipenv install`
    - `python -m pipenv run character_appender.py && patch_extra.bat`
- **Linux:**
  - `python3 character_appender.py && wine patch_extra.bat`