# Straitjacket

A one-file framework for reasonable code in a functional style.


## Introduction

Software design is controversial.

"Good" is subjective: what one likes, another hates. However, code solves
problems with logic. Consequently: **we can objectively characterize code in
terms of correctness and completeness of the logic it represents.**

For example:

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

This method:

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

This re-expression preserves original behavior, but on critical inspection
there are some problems:

1. What happens our branch logic finds no match?
2. Why not just make the `subject` an argument, since it's assigned first?
3. What if `#send_email` fails?

Let's address them with another iteration:

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

Characterizing:

`#determine_subject`:

1. has 4 branches handling **every** possible input case, thanks to `else`
2. raises an error on unhandled input
3. does nothing else

`#email`:

1. is indifferent to the subject it receives
2. always sends an email, provided `send_email` "works"
3. does nothing else

This is tigher because fails *explicitly*, but we still encounter fatal errors.
The set of things which could cause our application to fail--errors, unexpected
inputs (I'm looking at you, nil!), misconfigurations--all of it, are called
**bottom**.

The more bottom in your implementation, the more prone to defects it is.


## Defining Defects

Let's posit that **code completeness** is:

> **Just enough code to reasonably address a problem.**

Our code will need to manage:

1. **state** (data)
3. **logical decisions** (ex. email user?; print message?; render page?)
2. **interactions with the world** (ex. networks; the current time)

The following naturally hinder code completeness because they increase bottom:

1. changing ("mutable") state
2. the outside world, especially parts we do not control
3. branch logic, especially when non-exhaustive
4. optional data (nil), which necessitates more branch logic

(\#1 and \#2 are collectively referred to as **side effects**.)

Ignoring bottom increases the likelihood of defects, which are "incorrectness."

There is an intrinsic tool for dealing with bottom. This is **complexity**, or
anticipating and dealing with the real, messy world we code in.

There are ways of writing code which minimize bottom **and** complexity.


## "Simple" *is* an Aesthetic

Straitjacket espouses an aesthetic, and it's fine if you disagree, but:

**Complete, minimally complex software is better than any alternative.**

Without *some* complexity, nothing meaningful gets done. All human undertakings
require data, side effects, and decisions. But *unnecessary* complexity is bad.
This project does something bold. It asserts that **all** code fits neatly into
two categories. There's:

* code without side effects
* code with side effects

The Straitjacket style of coding specifies how to write both. For code with no
side effects, we write **functions**. For code with, we write **actions**.

Actions are where we minimially and consciously introduce bottom to our code.


## Functions

All functions must be mathematical functions:

```
f(x) = 3x + 4
```

Given any input `x`, this function will always yield the same output. There's no
way in mathematical functions to say:

```
f(x) = puts (3x + 4)
```

To `puts` anything, we'd have to be outside of a function:

```
f(x) = 3x + 4
puts f(3)
```

Anything with a side effect--something that if done more than once could cause
unwanted outcomes--does not belong in a function.

Functions which do not side-effect are referred to as **pure**.

Some examples of side effects:

* querying a database
* getting the current time
* doing anything that requires network access
* file system manipulations
* printing to the screen
* changing an original value provided to the function

Functions can do more than basic arithmetic operations. They can:

* return another function
* transform immutable data, returning a new value

Here are the only inviolable constraints for functions. Functions:

1. have no side effects
2. are defined on a module using `module_function`
3. are preferred to actions where possible
4. must have only one responsibility

In Ruby, methods are always defined on an object. The preferred way to describe
Straitjacket-compliant functions is with `module_function`:

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

[`module_function`](http://ruby-doc.org/core-2.4.1/Module.html#method-i-module_function)
makes the method callable directly on the module itself:

```ruby
Utility.multiply(1,2,3)
```

This is the closest approximation of standalone functions attainable in Ruby.

**Which module you locate your functions in is up to you! Straitjacket has no
opinions on where your functions live. Best practice is to keep functions as
adjacent as possible to where they are called.**

Some will note the above function calling a method on the `args` input. This is
fine, provided the method has no side effects. The is not ok:

```ruby
# NOT OK
module Utility
  def email(subject:)
    send_email(subject: subject) # a side-effecting library function
  end
  module_function :email
end
```

It's our function from above! It turns out this function hides side effects.
We didn't know better before, but now we do. This should an action instead.


## Actions

*Good constraints* provide *enforced consistency*. With functions, we had these
constraints. Functions:

1. have no side effects
2. are defined on a module using `module_function`
3. are preferred to actions where possible
4. must have only one responsibility

Actions are more involved. Here are their constraints. Actions:

1. are simple objects mixing in `SJ::Ugly::Action` (more on this shortly)
2. must have side effects
3. must have one responsibility
4. should be written sparingly--they are where bottom lives!
5. may have an outcome; if not, must return Unit

That's all there is to actions. They:

1. require explicit inputs (preferably validating them)
2. put side-effecting code in one place
3. have a uniform interface `.mk`, which is added reliably by a mixin
4. provide a pipeline for feeding the outcome of one action to others

### Constraint \#1: the `SJ::Ugly::Action` mixin

We'll explain `Ugly` later, but it is not (very) pejorative. It means the code
*cannot* conform to Straitjacket's ideals. Yes, Straitjacket is written in a way
that violates its own principles.

Straitjacket has a bias against traditional objects. Why? Well, objects:

1. are designed to store data that changes (have mutable state)
2. must be carefully crafted to have one responsibility, but typically are not
3. are alien to non-technical people, who think in tasks--not things
4. do not usually warn about their side effectcs
5. interact with other objects encapsulating their own (probably bad) behavior

Objects are *predisposed* to bottom, and feel like a minefield at scale.

**It is ultimately easier communicating and reasoning about a set of things we
must do. Solutions can always be expressed as a set of actions and functions.**

We *do* implement actions *as* objects, but that's because objects are a great
approximation the stateful context that surround an action.

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

How to call it:

```ruby
PrintGreeting.mk(name: 'Joshua').call!
```

Mixing in `SJ::Ugly::Action` adds one class method to your object, `.mk` (read
"make"). `.mk` is the only way to interact with an action. `.mk` calls `.new` on
the host class, which in turn invokes `#initialize`, like any other Ruby object.

Arguments provided to `.mk` are passed through to `#initialize`.

`SJ::Ugly::Action` adds two private instance methods to the class: `#validate`
and `#call!`. `#validate` is used optionally by `#initialize` to check that
arguments are sane. It raises if any errors are added to `errors` in the block.

`#call!` in turn calls `#invoke!`, which you implement.

### Constraint \#2: Side Effects

This one's easy: any given action must have side effects, otherwise it should
be expressed as a function instead.

### Constraint \#3: One Responsibility

Actions should only do one topical thing. This may involve invoking other
actions, or doing *literally* different things, but they should all be in
service of the *topical* action being taken.

### Constraint \#4: Sparingly

Actions should be written only when necessary, which will be surprisingly
obvious. If your business needs to you to do something dangerous, you'll need
an action. Otherwise, stick to functions.

### Constraint \#5: Maybe Outcome

Actions may return values called "outcomes". Here's an action with an outcome:

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
values are `Struct`s. A `Struct` is the closest data type we have in Ruby to
a named tuple, which is a fixed-length value list. Like Python's `namedtuple`.

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

**Straitjacket hands the outcome of an action to a block of code provided when
the action was called. This forces the outcome into a "context"--only code in
the block can access the outcome. This constraint is intentional.**

Once any code calls an action, something changes. Our code enters the dangerous
"real world." Forcing an action's outcome *into a context* is admitting that 
everything thereafter is **impure**.

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

Ruby is not a functional programming language. From [Wikipedia](https://en.wikipedia.org/wiki/Functional_programming):

> Programming in a functional style can also be accomplished in languages that
> are not specifically designed for functional programming.

This style of programming confers **immense** benefits for reasonability,
maintainability, and extensibility. Straitjacket provides us those benefits.

It's possible to describe three kinds of code in a post-Straitjacket world.
Broadly:

* **Good**: it adheres perfectly to the constraints
* **Bad**: it could but does not yet (or will not) adhere to the constraints
* **Ugly**: it cannot adhere to the constraints

All three types are necessary. Library code will probably never be "Good". All
code--Good, Bad, and Ugly--can be used by any other kind, so long as we write
only functions and actions.

Take an function in an application which uses ActiveRecord extensively:

```ruby
# NO GOOD
def score_page_hits(user_stats_record:, factor:)
  user_stats_record.page_hits * factor
end
module_function :score_page_hits
```

ActiveRecord is not hip to side effects: simply accessing an attribute may
issue a query to the underlying store. Consequently, this function is "Bad" and
should instead be an action.

Of course, you could also write this perfectly good function:

```ruby
def score_page_hits(page_hits:, factor:)
  page_hits * factor
end
module_function :score_page_hits
```

It would have to be called by an action already having done the dirty work of
talking to ActiveRecord.

**One of the chief ways of refactoring using Straitjacket is moving complex,
side-effecting code "outward" into calling code, which at the outermost level is
inevitably an action.**

It is a bit ironic that Straitjacket is implemented as a mixin. Really, mixins
are actually side effects affecting the Ruby runtime itself. The very thing
enabling our functional style of programming can never be "Good".
["Ceci n'est pas une pipe."](https://en.wikipedia.org/wiki/The_Treachery_of_Images).

In short:

* Aspire to write Good code.
* Aspire to make Bad code Good.
* Use Ugly code in Good code if you must, but hold to Straitjacket constraints.

## Style

There is a forthcoming document on style (maybe more than one), including:

* variable naming conventions
* keyword arguments and why they're preferable, and when they're not
* how Straitjacket is monadic, and what monads are

...and more.

Thanks for reading.
