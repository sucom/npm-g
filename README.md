# npm-g

`npm-g` is a cross-platform global package manager wrapper script that helps you keep your global npm packages synchronized across different environments or simply manages them cleanly via a manifest file. It supports Windows, Mac, Linux, and Git-Bash (Windows).

## Why npm-g?

### The pains of the modern developer
As modern developers, we likely work with multiple Node versions using managers like `nvm`, `fnm`, or `volta`. While these tools do an incredible job of isolating our environments, that very isolation creates a repetitive chore: we are forced to manually reinstall our go-to global CLI tools every time we switch to a new Node version or set up a new machine.

`npm-g` solves this by letting you define your essential global tools—your "utility belt"—in a single manifest file. It turns the tedious process of synchronizing your favorite packages across different Node environments into a simple, automated one-liner.

### The Evolution of the Global Package Landscape
To understand why maintaining global packages became such a hassle in the first place, let's take a deeper dive into how the Node ecosystem has evolved:

**The Great Shift: The Community Moved Local**

For the first several years of Node.js, the default approach was to install command-line tools globally. If you needed a tool for your workflow—whether it was a linter, a task runner, or a build tool—you typed `npm install -g <tool-name>` and expected it to be available everywhere.

However, as the ecosystem matured, the overwhelming preference shifted toward local installations. There are two massive reasons for this:

1. **The "Works on My Machine" Problem:** If Project A requires `webpack@4` and Project B requires `webpack@5` (or different versions of `eslint`), a single global installation breaks one of them. Local installs lock the exact dependency version in `package-lock.json`, ensuring absolute determinism across different developer laptops and CI/CD pipelines.
2. **The Invention of npx:** When Node 8.2 introduced `npx`, it allowed developers to execute CLI tools directly from the local `node_modules` (or download them on the fly) without ever needing them installed globally.

While local installations solve the versioning crisis, they introduce a new annoyance: massive duplication. Installing the exact same CLI tools locally across dozens of different projects rapidly eats up disk space.

*(Note: Modern package managers like `pnpm` actually solve the duplication issue by using a global hidden cache and hard-linking files to local projects, giving you the best of both worlds).*

**The "Shared Global" Trap**

When jumping between Node versions, a common temptation is to force `npm` to use a single, shared directory for all global installations (e.g., via `NPM_CONFIG_PREFIX`). While this saves disk space, it is a fragile hack that introduces severe risks:

- **ABI & Native Binary Crashes**: Packages that compile native C++ modules are bound to specific V8 engine internals. A global tool compiled under Node 24 will often instantly crash when executed under Node 18.
- **Core Tool Collisions**: Upgrading `npm` itself or managing `corepack` in a shared environment overwrites the package manager globally. Switching to an older Node version afterward can result in mismatched internals, completely breaking `npm` or `yarn`.
- **Environmental Fragility**: Shared global states rely on strict `PATH` manipulation. Opening multiple terminals with different active Node versions can cause unpredictable path shifts and runtime conflicts mid-session.

**When to Use Globals (The "Utility Belt")**

Despite the shift, global packages are far from dead. The modern golden rule is: **If a tool builds your project, it goes local. If a tool manages your environment or workflow independent of a specific project, it goes global.**

If you know for sure a tool will be used constantly across your entire system and isn't tied to a specific project's build step, it makes sense to install it globally. It saves the hassle of installing it in every single project.

Instead of fighting the architecture, **pure isolation combined with manifest-driven hydration** is the bulletproof solution. By keeping each Node version's packages strictly separate, you guarantee absolute stability and eliminate cross-version pollution. `npm-g` embraces this reality: it respects the isolated environments, while turning the chore of reinstalling your tools into a simple, automated one-liner.

Here are some examples of global packages that fit perfectly into a lean, global "utility belt":

**1. System & Environment Utilities**
- **[corepack](https://nodejs.org/api/corepack.html)**: The modern standard for managing `yarn` and `pnpm` binaries globally.
- **[npm-check-updates (ncu)](https://www.npmjs.com/package/npm-check-updates)**: Upgrades your `package.json` dependencies to their latest versions interactively.
- **[npkill](https://www.npmjs.com/package/npkill)**: Scans your hard drive for forgotten, massive `node_modules` folders and lets you delete them to free up space.

**2. The "Vanilla" Lifesavers**
- **[live-server](https://www.npmjs.com/package/live-server)** (or **http-server**): Spins up a local dev server in milliseconds with live-reloading built right in. No heavy build steps or Webpack configs required.
- **[nodemon](https://www.npmjs.com/package/nodemon)**: The industry standard for auto-restarting Node.js scripts. Excellent to have globally for quick, ad-hoc backend scripting.

**3. CLI & Scratchpad Tools**
- **[typescript](https://www.npmjs.com/package/typescript)** & **[ts-node](https://www.npmjs.com/package/ts-node)**: While these should absolutely be local project dependencies for production build pipelines, having them globally is highly recommended for quick scratchpad testing and running isolated `.ts` scripts directly from the terminal without initializing a whole project.

**4. Platform CLIs & Deployment Tools**
- **[@vscode/vsce](https://www.npmjs.com/package/@vscode/vsce)**: If you develop and publish VS Code extensions, having the extension manager globally available saves you from constantly using `npx`.
- **[vercel](https://www.npmjs.com/package/vercel)** / **[netlify-cli](https://www.npmjs.com/package/netlify-cli)** / **[firebase-tools](https://www.npmjs.com/package/firebase-tools)**: Essential CLI tools for managing cloud deployments and serverless functions effortlessly from any terminal window.

## The npm-g Advantage

Ultimately, `npm-g` acts as the perfect bridge for legitimate global use cases. It embraces the strict isolation enforced by modern Node version managers while completely eliminating the friction of maintaining your toolset. By leveraging a single manifest, it empowers you to seamlessly sync your favorite utilities across all your environments—saving you time and providing a clean, trackable record of exactly what you have installed.

## Setup & Installation

You can place the `npm-g.cmd` (for Windows Command Prompt) and `npm-g.sh` (for Bash/Zsh) files anywhere on your system, as long as the folder containing them is in your system's `PATH`.

A common and convenient location is your node version manager's home directory (e.g., `NVM_HOME` or `FNM_DIR` on Windows, or `~/.nvm` on Mac/Linux) since that path is typically already added to your environment `PATH` during their setup. However, any directory in your `PATH` will work perfectly fine.

### 1. Download the scripts
Download `npm-g.cmd` and `npm-g.sh` to your chosen directory.

### 2. Make the script executable (Mac/Linux/Git-Bash)
```bash
chmod +x /path/to/your/folder/npm-g.sh
```

### 3. Setup Aliases

To make it easier to use `npm-g` and create a shorter `g` shortcut, you can add aliases to your shell profile.

#### Git-Bash (Windows) / Linux
Add the following to your `~/.bash_profile` or `~/.bashrc`:
```bash
# Shortcut for npm-g global package manager
alias npm-g='"$(cygpath -u "$NVM_HOME")/npm-g.sh"'
alias g='"$(cygpath -u "$NVM_HOME")/npm-g.sh"'
```
*(Note: If you placed the files in a different directory instead of `NVM_HOME`, replace `"$NVM_HOME"` with the appropriate environment variable or absolute path)*

*(Note: After adding the aliases, you will need to either restart your terminal or run `source ~/.bashrc` (or `source ~/.bash_profile`) one time to load them into memory.)*

#### Mac
Add the following to your `~/.zprofile` or `~/.zshrc`:
```zsh
# Shortcut for npm-g global package manager
alias npm-g='"$HOME/.nvm/npm-g.sh"'
alias g='"$HOME/.nvm/npm-g.sh"'
```

*(Note: After adding the aliases, you will need to either restart your terminal or run `source ~/.zprofile` (or `source ~/.zshrc`) one time to load them into memory.)*

### 4. Initialize
Run `npm-g` for the first time. It will automatically create an `npm-g.manifest` file in the same directory as the scripts if one doesn't already exist.

## Usage Guide

`npm-g` operates primarily on the `npm-g.manifest` file, which tracks the exact global packages you want installed on your system.

### Basic Commands

- **Help / Usage**
  ```bash
  npm-g --help
  ```

- **Version**
  Displays the version of npm-g, node, and npm.
  ```bash
  npm-g --version
  ```

### Managing Packages

- **Add to Manifest (`add`, `-a`)**
  Adds one or more packages to your `npm-g.manifest` file.
  ```bash
  npm-g add nodemon typescript@5.4.2
  # Or using the shortcut if configured:
  g a eslint
  ```

- **Remove from Manifest (`remove`, `-r`)**
  Removes one or more packages from your manifest file. *(Note: this does not uninstall them from the system, it just stops tracking them).*
  ```bash
  npm-g remove nodemon
  ```

- **List Status (`list`, `-l`)**
  Shows a detailed list comparing the packages defined in your manifest against what is actually installed globally on your machine.
  ```bash
  npm-g list
  ```
  It will show tags like `[OK]`, `[MISSING]`, `[MISMATCH]`, and `[UNTRACKED]`.

- **Show Diff (`diff`, `-d`)**
  Shows only the discrepancies between your manifest and the current environment (missing packages, mismatched versions, or untracked packages).
  ```bash
  npm-g diff
  ```

### Syncing Environment

- **Install from Manifest (`install`, `-i`)**
  Installs all missing or mismatched packages defined in your manifest to bring your system up to sync.
  ```bash
  npm-g install
  ```

- **Install Specific Packages**
  Passing a package name acts as an implicit fallback to sequential global installation, similar to standard `npm i -g`.
  ```bash
  npm-g install nodemon
  # Or simply:
  npm-g nodemon
  ```

- **Uninstall Untracked Packages (`uninstall`, `-u`)**
  Purges all global packages from your system that are **not** listed in your manifest. Use this to clean up your global environment.
  ```bash
  npm-g uninstall
  ```

- **Uninstall Specific Packages**
  Explicitly remove target modules globally.
  ```bash
  npm-g uninstall nodemon
  ```

## 💡 Recommended NVM Companion

If you are using `nvm-windows` and miss the ability to run different Node.js versions in separate terminal sessions (a feature native to `nvm` on Mac/Linux or `fnm`), check out [`nvm-use`](https://github.com/sucom/nvm-use)—a lightweight companion tool that lets you use different Node versions per project or terminal simultaneously.

## ⚖️ LICENSE

MIT