---
layout: post
title: File Operations With Java 8 Streams
---

Streams are one of the major functional improvements introduced in Java 8 (the other being [lambda expressions](http://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html)). Reams have written about streams in Java - the package [JavaDoc](http://docs.oracle.com/javase/8/docs/api/java/util/stream/package-summary.html) is actually a pretty good starting point. In this post though, I plan to focus on a few specific use cases around file operations that I've found useful.

Java 7 introduced NIO.2, replacing large portions of the original file I/O capability in Java. In Java 8, NIO.2 was further extended with support for streams - offering new solutions for some use cases, two of which, I'll be covering in this post.

* Reading (And Acting On) Lines From a File
* Walking a File Tree

## Reading (And Acting On) Lines From a File

Reading all the lines from a file and performing some action on them has been an extremely common use case in my experience. The new [lines](http://docs.oracle.com/javase/8/docs/api/java/nio/file/Files.html#lines-java.nio.file.Path-) method, on the [Files](http://docs.oracle.com/javase/8/docs/api/java/nio/file/Files.html) class, provides a entry-point into a new method of solving this problem.

Consider this (not at all contrived) example. We are given a text file containing lines of integers like so:

{% highlight text %}
1  2  3  4
5  6  7  8
1  2  4  4
4  4  1  1
{% endhighlight %}

And the task is to sum up all entries in the second column with a value greater than 3.

Easy enough with any version of Java, but quite verbose before streams. With streams though, one solution looks something like this:

{% highlight java linenos %}
int sum = Files.lines(path)
        .map(line -> line.split(" ")[1])
        .mapToInt(Integer::parseInt)
        .filter(i -> i > 3)
        .sum();
{% endhighlight %}

* Line 1: Use the new `Files.lines` method to get a stream containing each line of the file.
* Line 2: Use `map` to replace each line in the stream with the second entry from the line.
* Line 3: Use `mapToInt` and a function reference to convert the second entry from each line into an Integer.
* Line 4: Use `filter` to limit our stream to values greater than 3.
* Line 5: Finally, call the `sum` method to sum up the values in the stream.

An important thing to note is that nothing is actually read from the file until `sum` is called. And, if something should go wrong at that point, you'll get an [UncheckedIOException](http://docs.oracle.com/javase/8/docs/api/java/io/UncheckedIOException.html).

## Walking a File Tree

Another use case for Java 8 streams is when it's necessary to walk a file tree and enumerate all the files meeting a certain criteria. The Files class again offers the entry method for this example, in the form of the [walk](http://docs.oracle.com/javase/8/docs/api/java/nio/file/Files.html#walk-java.nio.file.Path-java.nio.file.FileVisitOption...-) method.

Consider this (again, not at all contrived) example. We want to recursively descend a file tree, finding all files ending with ".java", and returning them in a list of Strings sorted alphabetically.

{% highlight java linenos %}
List<String> sortedJavaFilePaths = Files.walk(path)
        .filter(foundPath -> foundPath.toString().endsWith(".java"))
        .map(javaPath -> javaPath.getFileName().toString())
        .sorted()
        .collect(Collectors.toList());
{% endhighlight %}

* Line 1: Use the new `Files.walk` method to get a stream containing each file path located under the starting path.
* Line 2: Use `filter` to limit the stream to files that end with '.java'
* Line 3: Use `map` to convert each entry in the stream of file paths to just the file name (and converting to `String` along the way)
* Line 4: Use `sorted` to sort the entries of the stream. In this case, the normal `String` sorting behavior was fine.
* Line 5: Finally, call the `collect` method to collect the output of the stream into a `List`.