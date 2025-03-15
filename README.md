# LocalHexdocs

`LocalHexdocs` is a simple Elixir script allowing you to easily save and update Hexdoc files locally on your machine so you always have the most recent documentation for any Elixir libraries you might want to view.

## Usage

### Pulling down this repository

Before you can run `LocalHexdocs`, you must run `git clone` to download this repository. (Alternatively, you could manually copy the files from https://github.com/JamesLavin/local_hexdocs without downloading the repository, but pulling any future changes would be harder.)

```
git clone git@github.com:JamesLavin/local_hexdocs.git
```

OR

```
git clone https://github.com/JamesLavin/local_hexdocs.git
```

### Specifying Hexdocs libraries you want to save locally

After pulling down this repository, the next step is `cd`-ing into the top directory of this repository and specifying which Elixir libraries you wish to pull documentation for.

If you do nothing, running `elixir save_hexdocs.ex` in this directory will download all Hexdoc files listed in the provided `default_libraries.txt`.

You can modify `default_libraries.txt` to add, remove, or comment out (with a leading "#") libraries, but this may make it hard to update this project in the future, so we recommend that you copy `default_libraries.txt` to a new `libraries.txt` file and modify that.

`libraries.txt` is listed in `.gitignore`, so updating this repository will not touch that file. You can safely make it your own.

### Running `LocalHexdocs`

Once you're happy with your `libraries.txt` file, you can run this script to pull down the latest documentation for each library with this command, executed from the main directory :

```
elixir save_hexdocs.ex
```

(I didn't bother creating an executable binary since anyone wanting to download Hexdocs probably already has Elixir installed.)

You will see a stream of output, with one line per library. Each should say one of the following:

* "Docs fetched: /home/mateusz/.hex/docs/hexpm/scholar/0.4.0"
* "No package with name made_up_library"
* "Docs already fetched: /home/mateusz/.hex/docs/hexpm/sobelow/0.13.0"

At the end, you should see an Elixir map with three keys, each with a list of library names, like:

```
%{
  "Docs already fetched" => ["amqp/4.0.0", "amqp_client/4.0.3", "axon/0.7.0",
   "bamboo/2.4.0", "bamboo_phoenix/1.0.0", "bamboo_smtp/4.2.2", "bandit/1.6.8",
   "bcrypt_elixir/3.2.1", "benchee/1.3.1", "bodyguard/2.4.3", "broadway/1.2.1",
   ...
   "vega_lite/0.1.11", "vix/0.33.0", "wallaby/0.30.10", "websock/0.5.3",
   "websock_adapter/0.5.8", "xla/0.8.0", "yamerl/0.10.0", "yaml_elixir/2.11.0",
   "zigler/0.13.3"],
  "Docs fetched" => ["live_svelte/0.15.0", "req/0.5.8", "sobelow/0.13.0"],
  "No package with name" => ["made_up_library", "not_real"]
}
```

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

## Author

`LocalHexdocs` was created by James Lavin.

