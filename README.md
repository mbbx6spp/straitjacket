# Straitjacket

An opinionated, one file framework for writing more reasonable code in a
functional style which quarantines complexity.


## Introduction

Software, like any creative endeavor, is controversial. "Good" is eternally
subjective: what one likes, another detests. However, problems solved by code
are logical. We may not agree on "good", but **we can objectively and
dispassionately characterize code**. For example:

```ruby
def send_appropriate_email(input:)
  if input == :greet
    send_email(subject: "Hello")
  elsif input == :goodbye
    send_email(subject: "Goodbye")
  elsif input == :you_won
    send_email(subject: "You won")
  end
end
```

We can observe that this method:

1. has three execution branches
2. has undefined behavior unless input is `:greet`, `:goodbye`, or `:you_won`.
3. might send an email when called

Some may prefer this functionally identical version:

```ruby
def send_appropriate_email(input:)
  subject =
    case input
    when :greet
      "Hello"
    when :goodbye
      "Goodbye"
    when :you_won
      "You won"
    end

  send_email(subject: subject)
end
```

This re-expression preserves all the original behavior, but accentuates a few
painful things:

1. What happens when `subject` is nil?
2. Why not just make the `subject` an argument, since it's assign at the start?

So this code is already an improvement because of the issues it highlights.
Let's address those issues with another iteration:

```ruby
def determine_subject(input:)
  case input
  when :greet
    "Hello"
  when :goodbye
    "Goodbye"
  when :you_won
    "You won"
  else
    raise "no subject for #{input}"
  end
end

def email(subject:)
  send_email(subject: subject)
end
```

We can characterize this code objectively and dispassionately, too:

`#determine_subject`:

1. has 4 branches handling **every** possible input case, thanks to `else`
2. raises an error on unhandled input
3. does nothing else

`email`:

1. is indifferent to the subject it receives
2. always sends an email, provided `send_email` "works"
3. does nothing else

**Our last iteration is objectively less complex.**

OK, well how can we think about complexity in general?


## Defining Complexity

Let's posit that code complexity is:

> **Code we must write to account for all possible states of things.**

Where "things" are:

1. **data** (ex. a user address; an email's contents; an object's state)
2. **the outside world** (ex. availability of a network; the current time)
3. **logical decisions** (ex. email user?; print message?; render page?)

Naturally, these things are sources of complexity:

1. more data (especially data which can change or may not exist)
2. more interaction with the outside world (especially parts we do not control)
3. more decisions (especially ones which do not handle every case)

(\#1 and \#2 are collectively referred to as **side effects**.)

Simple software minimizes its exposure to complexity. This is why the latest
iteration of our code is objectively simpler. Again, with the above lists in
consideration:

```ruby
def determine_subject(input:)
  case input
  when :greet
    "Hello"
  when :goodbye
    "Goodbye"
  when :you_won
    "You won"
  else
    raise "no subject for #{input}"
  end
end

def email(subject:)
  send_email(subject: subject)
end
```


## "Simple" *is* an Aesthetic

Again, with software, there's no accounting for taste--but it *is* possible to
dispassionately analyze complexity. Here is Straitjacket's *raison d'etre*.
It is a belief and an aesthetic, and it's fine if you don't like it:

**Minimally complex software is better than any alternative.**

To the author of Straitjacket, this is really important. Without some
complexity, nothing gets done. All human undertakings require *some* complexity.
But even one scintilla of *unnecessary* complexity is not welcome. That's the
aspiration of Straitjacket. Pragmatic, no?

This project does something bold. It asserts that **all** code fits neatly into
two categories. There's:

* code without side effects
* code with side effects

The Straitjacket style of coding specifies how to write both. In fact, that's
all the style is. The rest, as they say, tends to fix itself.

For code with no side effects, we write **functions**. For code with side
effects, we write **actions**.


## Functions

Functions, to hear any functional programming advocate explain them, are just
like mathematical functions:

```
f(x) = 3x + 4
```

As in math, any input `x` provided will always yield the same output. There's no
way in mathematical functions to say:

```
f(x) = puts (3x + 4)
```

To `puts` anything, we'd have to be outside of a function:

```
f(x) = 3x + 4
puts f(3)
```

Any operation with a side effect--something that if done more than once could
cause unwanted outcomes--does not belong in a function.

Functions which do not side-effect are referred to as **pure**.

Some examples of side effects:

* querying a database
* getting the current time
* doing anything that requires network access
* file system manipulations
* printing to the screen
* changing an original value provided to the function

Obviously, functions can do more than basic arithmetic operations. They can:

* return another function
* transform immutable data, returning a new value
* transform actions to other actions, which in and of itself is pure--so
  long as no action is never invoked

Here are the only inviolable constraints for functions. Functions:

1. have no side effects
2. are defined on a module using `module_function`
3. are preferred to actions where possible
4. must have only one responsibility

In Ruby, whenever we define a method, it is inevitably defined on some object.
The best, and "Straitjacket" way to implement functions is with a helper method
called `module_function`:

```ruby
module Utility
  def multiply(*args)
    args.inject(&:*)
  end
  module_function :multiply

  def double(value:)
    multiply(value, 2)
  end
  module_function :double
end
```

What [`module_function`](http://ruby-doc.org/core-2.4.1/Module.html#method-i-module_function)
does is make the method callable directly on the module itself:

```ruby
Utility.multiply(1,2,3)
```

This is the closest approximation of pure functions attainable in Ruby.

**Which module you locate your functions in is up to you!  Straitjacket has no
opinions on where your functions live. That said, it's regarded as good practice
to keep functions as adjacent as possible to where they are called.**

Keen observers will note the above function calling a method on the `args`
input. This is just fine, provided the method has no side effects. The following
method is not ok:

```ruby
# NOT OK
module Utility
  def email(subject:)
    send_email(subject: subject) # some nasty library function
  end
  module_function :email
end
```

Look familiar? It's our function from above! It turns out this function hides
side effects. We didn't know better before, but now we do. This should be
written as an action instead.


## Actions

What's really awesome about *good constraints* is *enforced consistency*. With
functions, we had these constraints. Functions:

1. have no side effects
2. are defined on a module using `module_function`
3. are preferred to actions where possible
4. must have only one responsibility

These aren't too much to keep in your head. But actions are more involved.
Let's get the constraints out of the way. Actions:

1. are simple objects mixing in `SJ::Ugly::Action` (more on this shortly)
2. must have side effects
3. must have one responsibility
4. should be written sparingly--they are where complexity lives!
5. may have an outcome; if not, must return Unit

### Constraint \#1: the `SJ::Ugly::Action` mixin

We'll explain the use of the word `Ugly` later in this document, but it is not
(very) pejorative. It simply means that the code cannot conform to
Straitjacket's ideals. It turns out that Straitjacket is written in a way
that violates its own principles. (It has to be. hah!)

Let's back up for a second. Straitjacket has a bias against them. Why?
Because objects:

1. are designed to store data that changes (have mutable state)
2. must be mindfully authored to have one responsibility, but typically are not
3. are alien to non-technical people, who think in tasks--not things
4. do not usually warn about their side effectcs
5. by design interact with other objects which abstract their own (probably
   bad) behavior

Objects are *predisposed* to complexity, and feel like a minefield at scale.

**It ends up being easier communicating and reasoning about a set of things we
must do. Solutions can always be expressed as a set of actions and functions.**

We *do* implement actions *as* objects, but that's because objects are a great
fit for approximating the stateful context that an action happens in.

Actions are easier to:

1. test the side effects of, when appropriately small in scope
2. compose into bigger actions--also easy to test this composition
4. communicate with product owners about

Here's an example of a silly action:

```ruby
class GreetPerson
  include SJ::Ugly::Action

  private

  def initialize(name:)
    validate do |errors|
      errors << 'bad name' unless name.respond_to?(:to_str)
    end

    @name = name
  end

  def invoke!
    puts "Hello, #{@name}!"

    return Unit
  end
end
```

And here's how we'd call it:

```ruby
PrintGreeting.mk(name: 'Joshua').call!
```

Mixing in `SJ::Ugly::Action` adds one class method to your object, `.mk` (read
"make"). `.mk` is the sole interface to an action. `.mk` calls `.new` on the
host class, which in turn invokes `#initialize`, like any other Ruby object.
Arguments provided to `.mk` are passed through to `#initialize`.

`SJ::Ugly::Action` adds two private instance methods to the class: `#validate`
and `#call!`. `#validate` is used optionally by `#initialize` to check that
arguments are sane. It raises if any errors are added to `errors` in the block.

`#invoke!` calls `#call!`, which is implemented by the action, and uses its
return value in a special way described below.

That's the whole framework.

### Constraint \#2: Side Effects

**The entire aim of Straitjacket as a library is to quarantine complexity and
add lots of thoughtfulness and a bit of friction to adding complexity.**

Actions:

1. require explicit inputs (and preferably validate them)
2. put side-effecting code in one place
3. have a uniform interface `.mk`, which is added reliably by a mixin
4. provide a pipeline for feeding the outcome of one action to others

### Constraint \#3: One Responsibility

Actions should only do one topical thing. This may involve invoking other
actions, or doing *literally* different things, but they should all be in
service of the named action being taken.

### Constraint \#4: Sparingly

Actions should be written only when necessary, which will be surprisingly
obvious. If your business needs to you to do something dangerous, you'll need
an action. Otherwise, stick to functions.

### Constraint \#5: Maybe Outcome

Actions may optionally return values called "outcomes". Straitjacket imposes
some constraints on these values and how they are used. Let's take a look at
an action with an outcome:

```ruby
class GreetPerson
  include SJ::Ugly::Action

  Outcome = Struct.new(:entire_message)

  private

  def initialize(name:)
    validate do |errors|
      errors << 'bad name' unless name.respond_to?(:to_str)
    end

    @name = name
  end

  def invoke!
    entire_message = "Hello, #{@name}!"

    puts entire_message

    return Outcome.new(entire_message)
  end
end
```

And the calling code that needs the outcome from the action:

```ruby
GreetPerson.mk(
  name: "Joshua"
).call! do |outcome|
  entire_message, = *outcome
  # do something with the "entire message"
end
```

We have defined a constant `Outcome` in the class of type `Struct`. All outcome
values are `Struct`s so they are uniformly structured. A `Struct` is essentially
a list of named values.

If your eyes landed on this unconventional line of code:

```ruby
  entire_message, = *outcome # sets entire_message to outcome.entire_message
```

...don't worry. Splatting a `Struct` is just like splatting an array:

```ruby
  value1, = *[1] # sets value1 to 1
```

If we don't include the trailing comma, Ruby doesn't know that we're splatting:

```ruby
  # NO GOOD
  value1 = outcome # sets value1 to instance of Outcome struct
```

For multiple values, it looks more familiar:

```ruby
  value1, value2 = *outcome
```

**Actions MAY have an Outcome, which will be handed by the mixin to the block
given when the action was called. This forces the outcome into a "context"--only
code within the provided block can access the outcome. This constraint is
intentional.**

Once any code calls an action, something changes. The code is now in the real
world of "dangerous" actions. Forcing the outcome of an action to be accessible
only *in a context* is admitting that subsequent operations are "tainted" by
the dangerous world outside. It says "This is impure, you're in the wild west."

For actions with no `Outcome` (which should explicitly `return Unit`), there is
no need to provide a block when calling:

```ruby
class UnitAction
  include SJ::Ugly::Action

  private

  def initialize(message:)
    @message = message
  end

  def invoke!
    puts @message
    return Unit
  end
end
```

If the calling code expected an outcome, it would be this:

```
# NO GOOD
UnitAction.mk(
  message: "Hi"
).call! do |outcome|
  ??, = *outcome # there's nothing to assign--this action reports no outcome!
end
```

Consequently, we just `#call!` it and move on:

```
UnitAction.mk(
  message: "Hi"
).call!
```

Actions which have nothing to report (no `Outcome`) are simply invoked, and
the calling code moves on. It's only logical: the `Unit` type means "I have
nothing to say about what I've done."


### On Composing Actions

It is perfectly legitimate and desirable to do this:

```ruby
GreetPerson.mk(
  name: "Joshua"
).call! do |outcome|
  entire_message, = *outcome

  LogGreeting.mk(
    entire_message: entire_message
  ).call!

  return Outcome.new(entire_message)
end
```


## The Good, The Bad, and The Ugly

Ruby is not a functional programming language. This is a fools errand, then!
Nope. From [Wikipedia](https://en.wikipedia.org/wiki/Functional_programming):

> Programming in a functional style can also be accomplished in languages that
> are not specifically designed for functional programming.

It is merely a style of programming which confers **immense** benefits for
reasonability, maintainability, and extensibility of complex projects.
Straitjacket is a set of a handful of constraints which let us access those
benefits.

Not to be too dogmatic, but it's possible to describe three kinds of code in
a post-Straitjacket world. Broadly, code is:

* **Good**: it adheres perfectly to the constraints
* **Bad**: it could but does not yet (or will not) adhere to the constraints
* **Ugly**: it cannot adhere to the constraints

All three types of code are necessary in Ruby. Library code will probably never
be Straitjacket-based. All code--Good, Bad, and Ugly--can be used by any other
kind, so long as we are mindful of the side effects.

Take an function in an application which uses ActiveRecord extensively:

```ruby
# NO GOOD
def score_page_hits(user_stats_record:, factor:)
  user_stats_record.page_hits * factor
end
module_function :score_page_hits
```

ActiveRecord is not hip to side effects (you may have noticed!), and it is
possible that simply accessing an attribute issues a query to the underlying
store. Consequently, this function is "bad" and should instead be an action.

Of course, you could also write this perfectly good function:

```ruby
def score_page_hits(page_hits:, factor:)
  page_hits * factor
end
module_function :score_page_hits
```

It would have to be called by some code (definitely an action) which did the
dirty work of talking to ActiveRecord. But it itself is pure.

**One of the chief ways of refactoring using Straitjacket is moving complex,
side-effecting code "outward" into calling code, which at the outermost level is
inevitably an action.**

It is thus ironic that Straitjacket is implemented as a mixin. If you think
about it, mixing in a module *is actually a state mutation* of the Ruby runtime.
The very thing enabling our functional style of programming can never be "good".
["Ceci n'est pas une pipe."](https://en.wikipedia.org/wiki/The_Treachery_of_Images)
, indeed.

In short:

* Aspire to write Good code.
* Aspire to make Bad code Good.
* Feel free to use Ugly code anywhere, provided it doesn't break constraints.

## Style

There is a forthcoming document on style (maybe more than one), including:

* variable naming conventions
* keyword arguments and why they're preferable, and when they're not
* how Straitjacket is monadic, and what monads are

...and more.

Thanks for reading.
