---
layout: post
title: DecimalFormat Is Not Thread Safe
---

The [docs](https://docs.oracle.com/javase/8/docs/api/java/text/DecimalFormat.html) are pretty clear on this point.

> Decimal formats are generally not synchronized. It is recommended to create separate format instances for each thread. If multiple threads access a format concurrently, it must be synchronized externally.

Nevertheless, because of how it's often declared, and the evolution of its implementation, there's an interesting gotcha here.

When declaring a `DecimalFormat`, this is a common pattern:

{% highlight java %}
private static final DecimalFormat FORMATTER = new DecimalFormat("#,###");
{% endhighlight %}

It often makes sense to declare like a constant in this way, and that's fine, as long only one thread will ever access the containing class at any given time.

However, in multi-threaded code, it can cause huge problems.

Here's the other catch though, prior to Java 8, `DecimalFormat` was essentially thread safe _in practice_.

Java 8 introduced a fast-track option for formatting decimals with common patterns. See this [issue](https://bugs.openjdk.java.net/browse/JDK-7050528). The performance gains are reportedly quite substantial, and as the docs had always been quite clear regarding the lack of thread safety, the change makes sense.

It did, though, bite us in some legacy code that used the above declaration pattern in multi-threaded code.

For us, it manifested as a `NullPointerException`, as it did for the questioner in this StackOverflow [question](http://stackoverflow.com/questions/26514290/why-does-numberformat-format-throw-an-nullpointerexception).

## Options

In our case, the method that used the `DecimalFormat` was called very frequently, so I wanted to avoid instantiating a new format instance in the method body with every call.

Instead, I did exactly what the docs suggest and created separate format instances for each thread by using [ThreadLocal](http://docs.oracle.com/javase/7/docs/api/java/lang/ThreadLocal.html).

The above declaration now becomes:

{% highlight java %}
private static final ThreadLocal<DecimalFormat> FORMATTER =
    new ThreadLocal<DecimalFormat>() {
        @Override
        protected DecimalFormat initialValue() {
            return new DecimalFormat("#,###");
        }
    };
{% endhighlight %}

And you use the formatter as so:

{% highlight java %}
FORMATTER.get().format(value);
{% endhighlight %}
