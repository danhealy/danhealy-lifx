# danhealy-lifx

This is the script I use to control my LIFX lights at home.  Use this as an
example or a starting point for designing your own custom script.

It uses the [lightsd daemon](https://github.com/lopter/lightsd) running locally
on my Macbook to communicate with the 6 LIFX Color 1000 lights I have.  
Everything is on the same LAN.  The script talks to lightsd using JSON-RPC via
the [RJR gem](https://github.com/movitto/rjr) using its unix socket support for
JSON-RPC clients.

The idea is that it will periodically choose a base hue value for all the
lights, vary each light randomly by some small value, and blend them all to
their new colors in about 10 seconds.  I have three lights on a tree lamp, and
I've written a special method for these which takes a hue value assigned to the
whole lamp and spreads it across the three lights with a variance, and also it
will blend them at slightly different speeds.

The code was hastily written but well documented.  Enjoy!

# Installation (Mac)
First ensure you have ruby 2+ installed (I use [rvm](https://rvm.io/)) with the
[Bundler gem](http://bundler.io/) installed.

Also make sure you have [homebrew](http://brew.sh/) installed.

Install lightsd:

```
$ brew install lopter/lightsd/lightsd
```

Set lightsd to run on startup:

```
$ ln -sfv /usr/local/opt/lightsd/*.plist ~/Library/LaunchAgents
$ launchctl load ~/Library/LaunchAgents/homebrew.mxcl.lightsd.plist
```

lightsd logs are available in `/usr/local/var/log/lightsd.log`

Install gems:

```
$ bundle install
```

Run the script:

```
$ bundle exec ruby app.rb
```


# Installation (Other)
This was only tested on a Mac, but much of the code should work for other
platforms that support lightsd locally.  You will be on your own for the lightsd
installation and you may need to change the socket path.  Theoretically this
could even connect to a remote lightsd server, but this is left as an exercise
for the reader.
