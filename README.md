# Fluent::Rubyprof

Using fluent-rubyprof, you can start and stop [ruby-prof](https://github.com/ruby-prof/ruby-prof) dynamically from outside of fluentd without any configuration changes.

## Installation

```
$ fluent-gem install fluent-rubyprof
```

## Prerequisite

`in_debug_agent` plugin is required to be enabled.

```
<source>
  type debug_agent
</source>
```

And, `ruby-prof` gem is required. 

```
$ fluent-gem install ruby-prof
```

## Usage

Start

```
$ fluent-rubyprof start
```

Stop and write a profiling result.

```
$ fluent-rubyprof stop -o /tmp/fluent-rubyprof.txt
```

## Options

|parameter|description|default|
|---|---|---|
|-h, --host HOST|fluent host|127.0.0.1|
|-p, --port PORT|debug_agent|24230|
|-u, --unix PATH|use unix socket instead of tcp||
|-o, --output PATH|output file|/tmp/fluent-rubyprof.txt|
|-m, --measure_mode MEASURE_MODE|ruby-prof measure mode. See [ruby-prof#measurements](https://github.com/ruby-prof/ruby-prof#measurements)|PROCESS_TIME|

## Further Reading

* [Fluentd の debug_agent 経由で ruby-prof を起動する](http://qiita.com/sonots/items/749280547176d82f3e2c) (Japanese)

## ChangeLog

See [CHANGELOG.md](./CHANGELOG.md)

## Contributing

1. Fork it ( http://github.com/sonots/fluent-rubyprof/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

See [LICENSE.txt](./LICENSE.txt)

## Special Thanks

I refered implemention of [fluent-tail](https://github.com/choplin/fluent-tail). Thanks!
