# EjabberdRest

Ruby interface for ejabberd [mod_rest](https://github.com/processone/ejabberd-contrib/tree/master/mod_rest)

## Implemented method

* Add user
* Delete user

## Installation

Add this line to your application's Gemfile:

    gem 'ejabberd_rest'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ejabberd_rest

## Usage

```ruby
client = EjabberdRest::Client.new(url: "http://dreamland:5285")
client.add_user("ruby1", "dreamland", "ruby1password")
 => true
client.delete_user("ruby1", "dreamland")
 => "0"
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/ejabberd_rest/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
