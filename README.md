# LocalHexdocs

`LocalHexdocs` is a simple Elixir script allowing you to easily save and update Hexdoc files locally on your machine so you always have the most recent documentation for any Elixir libraries you might want to view.

## Usage

### Pulling down this repository

Before you can run `LocalHexdocs`, you must run `git clone` to download this repository. (Alternatively, you could manually copy the files from https://github.com/JamesLavin/local_hexdocs without downloading the repository, but pulling any future changes would be harder.)

```
git clone git@github.com:JamesLavin/local_hexdocs.git

# OR

git clone https://github.com/JamesLavin/local_hexdocs.git
```

### Specifying Hexdocs libraries you want to save locally

After pulling down this repository, the next step is going into the top directory of this repository and specifying which Elixir libraries you wish to pull documentation for.

If you do nothing, running `elixir save_hexdocs.ex` in this directory will download all Hexdoc files listed in the provided `default_libraries.txt`.

You can modify `default_libraries.txt` to add, remove, or comment out libraries (with a leading "#"), but this may make it hard to update this project in the future, so we recommend that you copy `default_libraries.txt` to a new `libraries.txt` file and modify that. `libraries.txt` is listed in `.gitignore`, so updating this repository will not touch that file. You can safely make it your own.

### Running `LocalHexdocs`

Once you're happy with your `libraries.txt` file, you can run this script to pull down the latest documentation for each library with this command, executed from the main directory :

```
elixir save_hexdocs.ex
```

(I didn't bother creating an executable binary since anyone wanting to download Hexdocs probably already has Elixir installed.)

### Serving & viewing your local Hexdocs files

Once you have downloaded your Hexdoc files locally, one way to view them is using `caddy file-server` (see: [CaddyServer.com](https://caddyserver.com/) and [the Caddy Github repo](https://github.com/caddyserver/caddy)). The following will serve your Hexdocs on port 8888 (assuming your `hexpm` directory is at `~/.hex/docs/hexpm`):

```
cd ~/.hex/docs/hexpm
caddy file-server --browse --listen :8888
```

### Updating your Hexdocs documentation

Updating your local Hexdocs documentation is as simple as re-running the `elixir save_hexdocs.ex` command.

Each time you run this, `LocalHexdocs` will pull the latest version of documentation for each specified library.

If you want to ensure you always have the latest documentation, you might create a cron job to periodically run `elixir save_hexdocs.ex`.
