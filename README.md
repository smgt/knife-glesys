# Knife Glesys

knife-glesys is a Knife addon that will make it easier manage your VPS at [Glesys](http://www.glesys.se). You can create,
delete, list and show info about your servers.
To be able to use this addon you need to create a Glesys API key with permission to `IP` and `SERVER`. You do this in their control panel.

## Installation

To use the addon install it as a normal gem, from your command line run:

```bash
$ gem install knife-glesys
```

## Configuration

To configure the addon you can either add your Glesys username and your API key to knife.rb in your chef directory.

```ruby
knife[:glesys_username] = "YOUR USERNAME"
knife[:glesys_api_key]  = "YOUR API KEY"
```

Or you can pass your username and your API key to the knife glesys command.

```bash
$ knife glesys server list --glesys-api-key "YOUR API KEY" --glesys-username "YOUR USERNAME"
```

## Usage

### Create a new server

When creating a new instance you there are some options you need to supply for it to work, `template` (server image),
`platform`, `data-center`, `root-password` and a `hostname`. It is recommended that you also specify the number of
cpu cores, the amount of memory and disksize. Or else these will default to 1 cpu core, 512 mb memory and 10 gb disk.
If you want to view the options you can just run the command without any options.

```bash
$ knife glesys server create (options)
```

To create a OpenVZ Debian server in Stockholm you run this command (This will also provision the host with the `db` role):

```bash
$ knife glesys server create --image "Debian 6.0 64-bit" --platform "OpenVZ" --data-center "Stockholm" \
  --cpu-cores 1 --memory-size 128 --transfer 50 -N database --run-list 'role[:db]' \
  --hostname "data.example.com" --root-password 'passw0rd' --description "Redis database server"
```

### List available templates

Glesys offers many different templates (or images) to use when you spin up a new VPS. To get a list of all available and on which platform you run:

```bash
$ knife glesys templates list
```
      
### List your servers

To list your servers that you have connected to your account. This will give you a list with 

```bash
$ knife glesys server list
```

### More information about a server

To get detailed information about a server like how much memory that is used and how much the server costs you can issue the info command.

```bash
$ knife glesys server info vz31337
```

### Delete a server

Every server has a uniqe id at Glesys. Just pass this id to the delete command to erase the server.

```bash
$ knife glesys server delete vz31337
```

And to at the same time delete the Chef node pass the `--purge` option to the delete command.

## TODO

There are a few things that still needs to be fixed (in no special order).

* Manage Glesys IPs
* Graph server stats in console

## Known issues

* Needs HEAD version of [fog](https://github.com/fog/fog) to work

## Contributing

I like contributions, so if you find any errors please add a issue or even better, send a pull request.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

(The MIT License)

Copyright (c) 2013 smgt (Simon Gate)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
