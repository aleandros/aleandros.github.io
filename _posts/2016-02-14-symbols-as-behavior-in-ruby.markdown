---
layout: post
title: Symbols as behavior in ruby
---

Perhaps you have encountered along your ruby path something like
the following:

{% highlight ruby %}
x = [1, 2, 3, 4]
x.map(&:to_s).join('-') #=> "1-2-3-4"
{% endhighlight %}

It's pretty clear what this code does: taking an array an joining
the string representation of its elements with hyphens. While the code
is concise and somewhat intuitive, you may wonder what the hell
is happening with the argument to `map`.

{% highlight ruby %}
x.map(&:to_s)
{% endhighlight %}

Here is where it gets interesting. It *looks* like special syntax. Somewhat
cryptic, but readable. It seems to call the method `to_s` to every element
in the sequence (since you're using it in a `map`). You may have already used
this form successfully without really understanding how it works. As we shall see,
there's no magic or special syntax involved, but plain old ruby used wisely.

## A small step backward

Before we move on, let's analyze how can we express the same thing
in a (possibly) more traditional way, passing a block to `map`.

{% highlight ruby %}
x = [1, 2, 3, 4]
x.map { |n| n.to_s }.join('-') #=> "1-2-3-4"
{% endhighlight %}

First note that the only thing that changed in the code is the argument to
map. The map semantics is not being altered in any way, and I believe it is
clear that both snippets do exactly the same thing, so the *meaning* of
both arguments to map is the same in spite of having a different *shape*.

In order to analyze the differences between both cases, it is useful if
we ask which one of them would be the obvious choice for our program, and
since you are reading this article, the answer is very likely to be
the one with the block.

So the next question is: how do we go from `{ |n| n.to_s }` to `&:to_s`?
There are two elements of familiar syntax in our target: the unary
ampersand operator (`&`) and `:symbols`. Let's check how they play
together.

## The unary ampersand operator

`&` is a short operator two main responsibilities. The first one
is (VERY broadly speaking) to fix the fact that although every 
ruby method has an associated block that can be executed via calling `yield`,
they cannot be assigned to variables and depending on the API can be a pain
to work with if the block is expected very time the method is called, or if
we want to pass a proc as the associated method's block.

{% highlight ruby %}
def not_much
  yield
end

not_much do # Call m setting its associated block
  puts 'No surprises'
end
#=> It prints, unsurprisingly
# No surprises

m # Call with no block 
#=> Raises "LocalJumpError: no block given (yield)"
{% endhighlight %}

There's nothing inherently wrong with throwing an
exception when a block is expected and not found, but
for purposes of illustration, let's check the alternative
using the unary ampersand.

{% highlight ruby %}
def not_much(&action) # Convert method's block into a proc
  action.call
end

action = proc { puts 'hi' }

not_much &action # Convert proc into method's block
#=> It prints
# hi
{% endhighlight %}

This may look familiar if you have some
experience working with blocks in ruby. Yet, there's one more thing
that we can do with this operator. What do you thing will happen
if we apply it to something that is neither a block nor a proc?

{% highlight ruby %}
obj = Object.new
# We create a method ONLY for obj
class << obj
  def to_proc
    proc { puts 'This looks like fun' }
  end
end

not_much &obj
#=> It prints
# This looks like fun
{% endhighlight %}

It turns out that the unary `&` operator, when used with an non-proc, non-block
object, it *asks* for that object representation as a proc. The standard
way to do this is using the `to_proc` method, which works just the same as methods
like `to_s` or `to_i` are supposed to work.

This is interesting because it doesn't really matter if we are dealing with procs.
We just need an object that can behave like one if we ask politely. That is a
powerful idea, and actually a pretty standard way to do things in ruby.

## If it looks like a duck...

Duck typing is the technique of not relying on an object type, but in assuming
that if it responds to the methods we want, then it is likely to be just the
object we need.

We have put almost all the pieces together. By now you probably have guessed
that symbols implement their own `to_proc` behavior, which we can inspect.

{% highlight ruby %}
action = :to_s.to_proc
action.call(1) #=> "1"
{% endhighlight %}

So a symbol, when represented as a proc, receives an object and
sends the message with its own name to the given object. We could
implement it naively in the following way:

{% highlight ruby %}
class Symbol
  def to_proc
    proc do |obj|
      obj.send(self)
    end
  end
end
{% endhighlight %}

## Putting it all together

Now we know that the form `method(&:symbol)` is nothing special. It
uses ruby features we know an love in a clever way in order to
gain extra conciseness in our code: it asks a symbol for its
representation as a proc (which just calls a a method with the symbol name
on its argument).

While it is useful to know this, it is more interesting to see some
basic ideas being applied in order to give users (in this case, ruby programmers)
a flexible and readable API, something we know is anything but trivial to achieve.
