# Straitjacket

Straitjacket is a tiny, tiny framework and a-handful-of-rules coding style
resuling in composable Ruby code with fewer, more obvious bugs.

Things almost always get muddled beyond comprehension in sufficiently old
codebases. Straitjacket is a codified admission that some constraints enforcing
reasonableness are helpful.

## Introduction

As projects written in languages like Ruby grow, bugs invade. Why? Among others,
here are some causes:

1. Incomplete expression of behavior
2. Unanticipated/unhandled states
3. Surprise side effects

Every code addition oblivious to these things increases the likelihood that
something will go wrong. Sadly, Ruby isn't the best at helping.

In the name of *easy* programming, we sacrifice what could be *simple*. Here,
*easy* is defined as authoring code oblivious to the above gremlins.

If you're curious about some specific code pitfalls, we've put together
[a list of a few]().


## Doing it Better

Consider these continuums:

* *safe*       <=> *destructive*
* *reasonable* <=> *confounding*
* *explicit*   <=> *implicit*
* *simple*     <=> *complex*

Straitjacket helps pull code leftward on the above continuums, with slight
trade-offs on this one:

* *easy* <=> *hard*

It is, at first, slightly *harder* at first to write Ruby code in this style.
But it quickly becomes second nature, and reasoning about the intent of the
code is much easier. It's also easier to build complex software out of well-
behaved, simpler software.


## Straitjacket Style: The Rules

This section is heavily dependent on a good understanding of *side effects*. If
you have a good understand of what they are, it'll be easy.

1. All side-effecting code belongs in an action. No exceptions.
2. All non-side-effecting (aka "pure") code belongs in a function.
3. Actions can use functions, but functions cannot use actions.
4. Prefer functions.
5. Always use keyword arguments for actions and functions. No exceptions.
6. Any code unable to conform to these rules is "ugly" and should be used
   minimally in favor of conformant code. This includes almost all library code.

Let's go through these rules.

### Rule #1: Side-effecting code goes in actions.

Actions are modeled as objects, but you can think of them as a stateful
process. You give an action the state it needs, you invoke it, and then you
use its `Outcome` (if present) in subsequent action calls.

Here's what an action's implementation looks like:

```ruby
# lib/my_blog/find_articles.rb

require 'sj'

module MyBlog
  # name your action like a verb. it's something you *do*.
  class FindArticles
    # ironically, the mixin module enabling straitjacket is "ugly"
    include SJ::Ugly::Action
  
    Outcome = Struct.new(:articles)

    def initialize(db_connection:, username:)
      # If any errors are added here, straitjacket raises by design.
      # This is for checking arg types and presence--nothing side-effecting,
      # like running a db query or getting the current time.
      # This is optional but will save you much pain.
      validates do |errors|
        errors.add('nil db_connection') unless !!db_connection
        errors.add('username') unless !!username
      end

      @db_connection = db_connection
      @username = username
    end

    def invoke!
      articles = @db_connection.query_by_username(@username)
      return Outcome.new(articles)
    end
  end
end
```

Here's some calling code, either in "ugly" non-sj code or another action:

```ruby
# count_articles.rb

require 'my_blog/find_articles'
require 'database/conn'
require 'logger'

# "ugly" code is fine to use in actions or ugly code.
db_connection = Database::Conn.new(login: 'foo', password: nil)
logger = Logger.new($stdout)

MyBlog::FindArticles.
  mk(db_connection: db_connection, username: 'onethirtyfive).
call! do |outcome|
  # the trailing comma is necessary for one-element deconstruction
  articles, = *outcome

  # here, you may do something with the articles
  logger.info("#{articles.length} articles found")
end
```

Let's make the code even better by writing a `LogMessage` action:

```
# lib/my_blog/log_article_count.rb

require 'sj'

module MyApp
  class LogMessage
    include SJ::Ugly::Action

    def initialize(logger:, count:)
      @logger = logger
      @count = count
    end

    def invoke!
      @logger.log("#{articles.length} articles found")

      # Unit is a constant meaning "The action did something with a side
      # effect but it has nothing to report."
      return Unit
    end
  end
end
```

And in the calling code:
```ruby
# count_articles.rb, just a script

require 'my_blog/find_articles'
require 'my_blog/log_message'
require 'database/conn'
require 'logger'

db_connection = Database::Conn.new(login: 'foo', password: nil)

MyBlog::FindArticles.
  mk(db_connection: db_connection, username: 'onethirtyfive).
call! do |outcome|
  # the trailing comma is necessary for one-element deconstruction
  articles, = *outcome

  # actions returning Unit do not need a block provided
  MyBlog::LogMessage.
    mk(logger: Logger.new($stdout), count: articles.count).
  call!
end
```

In this coding style, we frequently compose smaller actions into larger ones.
Which actions should exist are entirely up to you.

It is much easier to reason about the scope of an *action*--one thing you want
to happen--than it is to reason about multiple responsibilities of one object
with poorly separated (or worse, mixed) interfaces operating on the same
encapsulated state.

Straitjacket actions are one way of enforcing objects to abide by the
[Single Responsibility Principle](). We author them as things you *do*.

### Rule #2: Pure code goes in functions.

This one's easy: write functions, but skip the side effects.

```ruby
# OK:
# use keyword args. they're explicit at call-time and order-independent
def multiply(a:, b:)
  a * b
end

# OK:
# use keyword args. they're explicit at call-time and order-independent
def minutes_since(time:, count:)
  count.minutes.since(time)
end

# BAD:
# This code is side-effecting in that it depends on the current time, which
# is global state. Should be in an action.
def minutes_from_now(count:)
  count.minutes.from_now
end

# BAD:
# This code depends on global state set up by who knows who?
def three_minutes_after_startup
  3.minutes.since(MyApp.config.start_time)
end

# BAD:
# Using defaults doesn't really help.
def three_minutes_after(startup: MyApp.config.start_time)
  3.minutes.after(startup)
end

# GOOD:
# Leave it to the calling code to be side-effecting
def three_minutes_after(startup:)
  3.minutes.after(startup)
end

# BAD:
# For one, functions should never use actions.
# Moreover, the result of `#call!` is nil by design. without workarounds,
# you can only use the `outcome` within the provided block, by design.
def current_time
  MyApp::GetTheTime.mk.call! do |outcome|
    current_time, = *outcome
  end
end
```

Other than avoiding side effects, straitjacket has no opinions on where your
functions live. They can be class methods on an action, or defined in modules
like so:

```ruby
module SomeModule
  def some_function(a:, b:)
    # whatever non-side-effecting code
  end
  module_function :some_function
end
```

That's all there is to functions.


