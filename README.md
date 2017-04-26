# Straitjacket

A one-file framework (and a philosophy) facilitating composable Ruby code.


## Introduction

Writing good software is hard. _Why_ is debatable. Consider _giraffes_. Which
giraffe is best? Are giraffes better than other creatures? OK, I know. The point
is: judging software is similarly fraught.

To do anything well, we need the right understanding and good tooling.


## Pondering Giraffes

On giraffes, some might ask:

1. Should giraffes exist?
2. Are giraffes good or evil?
3. What is the essence of a giraffe?
4. Do giraffes have souls?
5. Why are giraffes always painted in watercolor?

Who knows? But a better line of inquiry ought be more concrete:

1. Which adaptations in musculature support the giraffe's neck?
2. How come giraffes stand less than one hour after birth?
3. What percentage of body weight do giraffes eat daily? \[it's 66lb, or 4%\]
4. Arctic giraffes: what needs to change?
5. Why are there no giraffe mathletes?

When it comes to giraffes, there's no accounting for taste. But we can most
assuredly account for **fitness of purpose in their context**. Software is no
different. Software is giraffes all the way down. And we can characterize good
software very easily as:

> **The minimal expression of complexity, expressed in code and data, to serve
> an particular computational need.**

We do only the work required to meet the need. This is ideal because lower
complexity means software will adapt easily to new needs. Maybe your software
requirements have non-negotiable, ahem, particularies. This is reasonable and
OK. We're go to war with the army we have.


## Genericity, ~~Giraffes~~ Software, and Other Foibles

OK, let's let go of the giraffe thing. Let's talk about software. I lied; more
giraffes, specific to general:

1. giraffes on the savannah
2. giraffes in general
3. four-legged land-dwelling animals
4. mammals
5. vertebrates
6. animals

The further down the list, the harder to make generalizations about the item.
Why? Because if we observe something about animals, and want that observation to
apply to giraffes on the savannah, our observation must be **broadly
applicable**.

For any software on the planet, you could make a similar list:

1. the software you've written (with a specific business purpose)
2. the framework(s)/library(ies) it uses
3. the language(s)
4. the language family/families
5. software in general

If we observe something about software in general, and want that observation to
apply to the software you've written as well, our observation must be **broadly
applicable**.

What astounding observations are made herein by the author? Just what other,
smarter people already figured out. To write good software, again:

> **The minimal expression of complexity, expressed in code and data, to serve
> an particular computational need.**

...we must prize **compositionality**, or **the building of complex things out
of simple things**. Writing good software is like building the Taj Mahal out of
Duplo blocks.


## Inheriting New Wisdom

Straitjacket is a set of constraints that _almost_ forces users to write
compositional software. But, since Ruby comes with few helpful offerings to this
end (more on this later, of course), one has to know the spirit of the endeavor!

The thesis of this framework and this document is simple:

> **Elegant code is a minimally, but necessarily complex. We can segregate the
> parts of our code which are dangerous from the parts that aren't, and we can
> compose both types together to ship maintainable, reasonable software which
> rarely surprises us.**

Sadly, fellow Rubyists, we are awash in unnecessarily complexity, despite our
best efforts to make things "simple", included but not limited to:

- opinionated frameworks
- conventions, not configuration
- service objects--except in our ActiveRecord models, because Rails
- switching to javascript (lol)
- dabbling in Haskell in evenings, further aggravating our stupid RSI
- a "few" "good" and "innovative" "approaches" that we and our coworkers are
  annoyed by within a year

[Editor's note: The author is speaking with a therapist, and offers apologies
for the thinly veiled cynicism masquerading as giraffes. p.s. giraffes]

These are misguided efforts, as are all solutions to misunderstood problems. We
can do better.


## Ruby, Not Helping

In imperative OOP languages like the one we love, we do think a lot. We think
about things. We have our `Blog`, `Todo`, `User` models. We have our
`Sidekiq::Worker` mixin. When we do think about compositionality, we do so
narrowly and in reference to objects: "I assemble objects from other objects
and test each separately."

Like this, sometimes:

```ruby
  module Greeter
    def greet(name)
      puts "#{greeting}, #{name}!"
    end
  end

  class Worker
    include Greeter

    attr_reader :greeting

    def initialize(greeting)
      @greeting = greeting
    end
  end

  class RudeWorker < Worker
    def initialize
      super("Step off")
    end
  end

  class NiceWorker < Worker
    def initialize
      super("Welcome")
    end
  end

  puts RudeWorker.new.greet("Bucky")  # => "Step off, Bucky!"
  puts NiceWorker.new.greet("Friend") # => "Hello, Friend!"
```

This is contrived, but there is truth in the example. Succinctly:

> **In OOP, one source of complexity is the _domain of objects_ we employ.
> Another is _what any object does_. Yet another is _what state the object
> hides_.**

Article of faith: one cannot think these three things simultaneously and stay
sane at any large scale--the developer is serving three very demanding masters.


## Ruby, Not Helping More

Here are two opposing things: **simple** vs. **complex**. Separately, here are
two more: **easy** vs. **difficult**. The holy grail of software is **simple**
and **easy**.

Straitjacket facilitates **simple**, and it does so with certitude.
(Unfortunately, it cannot promise **easy**.) The philosophy of Straitjacket
regard a few **sources of complexity** with disdain. In no particular order:

- pieces of information that might change, or **mutable state**
- the scary world of what's on the screen, what's in your database, what time
  it is, or what the next random number will be--collectively **side effects**
- **nil**, or the possibility that any value might not be there
- **incomplete branch logic** which does not exhaust all possibilities
- **implicit or coincidental code decisions** (defaults; reliance on unreliable
  values)

These account for most complexity in code. And, when unhandled, bugs. If we code
simply, we will see these pitfalls from a mile away.

Our understandings of these liabilities grow, too. An example of this is
realizing that Ruby mixins are in fact mutations of the entire Ruby runtime.
Ever been bitten by someone else's monkey-patch? That's **mutable state** and
**implicit code decision** problems you're having.

Similarly, we might think this function pretty benign:

```ruby
  def get_time
    Time.now.to_i
  end
```

It isn't. If called twice, it returns different values. Why? It relies on
global, mutable state known as "time". To reason about this function, we must
reason too about time. Here's another thing we Rubyists overlook at our peril:

```ruby
  user     = User.find(1)
  nickname = user.name # oops, it's nil
  send_email(nickname)
```

Our code necessarily ends up looking like this:

```ruby
  user     = User.find(1)
  nickname = user.name
  if !!nickname
    send_email(nickname)
  else
    raise 'no nickname'
  end
```

Tests--we have tests, right?--must set up two cases: one with a nickname, one
without. **nil** always produces branch complexity: the logic required for
maybe having a value, maybe not. Woe unto you if you miss this need, especially
as your software grows more and more complex.

All of this is to say, complexity is something we can _talk about_ and _avoid_.

Sadly, Ruby has nothing to say about this. `nil` is ubiquitous. Mutation is
normal and encouraged. Branch logic is often incomplete (`if` without `else`),
yielding essentially undefined behavior. The main mode of composition is mixins
and object inheritance.

**To write simpler software, we borrow from other paradigms.**

Half of you reading this already realize that the author is a fan of
**functional programming**, which is an approach to coding that is mindful of
compositionality and complexity. **Functional programming is an approach, not
a language.** Consequently, we can write functional code in Ruby.

And, the author argues, we should. Now, for the nitty gritty.


## Borrowing a Cup of Sugar

I'm going to skip straight to the punchline. Broadly speaking, we _can_ choose
to categorize code into two major groups:

1. Side-effecting **actions**
2. Pure **functions**

This, you might guess, doesn't really have anything to do with OOP. Rather than
thinking about types of **things**, we're thinking about types of **doings**.
Some Ruby projects employ objects tasked with doing something. These classes,
widely known as "service objects", might have names like:

- `SiteVisitorRecorder`
- `InvoiceCalculator`
- `InputSanitizer`
- `RateLimiter`
- `SignupValidator`

...or whatever business the project has which don't seem like obvious "model"
concerns. These service objects are an admirable attempt at isolating
complexity.

But there's something amiss here. All these classes end in "-er" or "-or", and
seem to be reaching for some common semantic _something_. Let's rename them:

- `RecordSiteVisitor`
- `CalculateInvoice`
- `SanitizeInput`
- `RateLimit`
- `ValidateSignup`

That's it! These are really **verbs** in **noun** clothing. OOP fetishizes
_things_, so we contort ourselves into using them. Alas, that's how we've come
to think. But constraints are liberating, and imposing the label of **action**
allows us an important benefit:

> **We can standardize the interface to all actions. Ever.**

This is because, of any action, we can say:

1. An action MAY require **inputs**.
2. Every action MUST be **callable**.
3. An action MAY report an **outcome value**.
4. Every action MUST have some **side effect(s)**.
5. The action MAY have different side effects and MAY return a different
   outcome value every call.

What does this leave us with for the other type of code, **functions**?
Of functions, we can say:

1. A function MAY require **inputs**.
2. Every function MUST be **callable**.
3. A function MAY return a **value**.
4. Every function MUST NOT have **side effects**.
4. Given the same inputs, the function MUST return the same value.

**Together, these two types of code comprise a complete set of all code
possibilities. It is possible to express all code this way.**


## Actions the Straitjacket Way

TODO


## Functions the Straitjacket Way

This part's easy. Ruby gives us **methods**, but they're always conventionally
attached to an object. But there's a nifty `module_function` method which at
least lets us pretend that we're dealing with a platonic function:

```ruby
module MyApp
  def add(list_values:)
    list_values.sum
  end
  module_function :add

  def path(prefix:, list_components:)
    '/' + [prefix, list_components].flatten.join('/')
  end
  module_function :path
end

MyApp.add(list_values: [1, 2, 3]) # => 6
MyApp.path(prefix: 'Macintosh HD', list_components: ['Documents', 'foo.txt'])
  # => "/Macintosh HD/Documents/foo.txt"
```

Or, depending on your taste, this:

```ruby
module MyApp
  module_function # affects everything after

  def add(args:)
    args.sum
  end

  def path(prefix:, list_components:)
    [prefix, list_components].flatten.join('/')
  end
end
```

Defining functions this way clearly denotes that they are, well, functions.
Importantly:

1. A function MAY call any other function.
2. An action MAY call any function.
3. A function MUST NOT call an action. (side effects!)

That's it for functions.

n.b. `module_function` is only available within `Module` definitions, not
`Class`!


