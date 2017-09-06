# ActiveJobResqueSolo

A plugin for ActiveJob with Resque to prevent duplicate enqueuing of jobs.

[![Build Status](https://travis-ci.org/kinkade/active_job_resque_solo.svg?branch=master)](https://travis-ci.org/kinkade/active_job_resque_solo)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_job_resque_solo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_job_resque_solo

## Usage

In your job class, include the plugin:

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  queue_as :default

  def perform(*args); end
end
```

If an instance of the job with matching arguments is either waiting for a worker or currently executing,
Solo will prevent a new instance of the job from being enqueued.

You can control which named arguments are used to determine uniqueness in the queue:

* `solo_only_args`
* `solo_except_args`

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  # Only compare "user" args when checking for duplicate jobs.
  solo_only_args :user

  queue_as :default

  def perform(user:, nonce:)
  end
end
```

Conversely, you can exclude arguments from being checked for duplicates.  This
is useful when plugins add arguments of their own to your jobs.

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  solo_except_args :nonce, :retry_count

  queue_as :default

  def perform(user:, nonce:)
  end
end
```
## Locking

Solo uses an internal locking mechanism to prevent multiple processes from
enqueuing the same job during race conditions.  This gem does not perform any
locking around job execution.

The lock prevents competing jobs of the same class and arguments from being
enqueued, complying with the argument filtering programmed with `solo_only_args`
and `solo_except_args`.

The default Redis key prefix is "ajr_solo".  It can be set to a different,
arbitrary string of your choice using `solo_lock_key_prefix`:

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  solo_lock_key_prefix "my_lock_prefix"

  def perform(*args)
  end
end
```

## Duplicate enqueues are possible

While this plugin will greatly reduce duplicate instances of a job from being
enqueued, a job may be enqueued multiple times if the Redis response times are
very slow. Slowness could be caused by extremely high load on Redis or networking
issues.

The locks are acquired for dynamic amounts of time, but expire quickly, typically
in one second. Killed workers will not leave long-lived, orphaned locks to
adversely block jobs from being enqueued.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kinkade/active_job_resque_solo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveJobResqueSolo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kinkade/active_job_resque_solo/blob/master/CODE_OF_CONDUCT.md).
