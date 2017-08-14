The "best code ever".  That's tongue-in-cheek, in case you were wondering.
I'm sure there are more obfuscated examples of perl out there, but keep in mind:
*I wasn't being intentionally obscure*

This is effectively a case study in unreadable perl syntax, but also a lesson in
giving the user what they need, not what they ask for.


The task:

Parse metadata fields from filenames (strings), separated by a delimiter.

The catch:

Users wanted to be able to specify arbitrary delimiters and orderings of metadata fields.  

After an embarassing number of iterations (two) of "ok, now we need the delimiters to be this character and the fields in this order" 
I implemented a general solution so the users could specify whatever they wanted.

The "solution":

The problem amounts to allowing the user to specify a simplified regular expression.
For example, the user would input a delimiter of '-' and pattern like this:

-date--author-

and the system would read filenames like this:

-2017-08-06--kevin- 

and populate the correct date and author.  

Now, because I'm using a regular expression at the end of the day, the delmiter
can't actually be arbitrary as a lot of characters have special meaning in
regular expressions.  

So the first thing I do is replace all occurrences of the user's delimiter with %.
(yes, technically this is fragile but field names contained only [A-Za-z])

Even for this simple step I had to use an eval (shudder) because:
tr won't take variables, as the transliteration table is normally built at compile time
but eval interprets every $ as a variable, so escape the first one

```
eval "\$file_format_regex =~ tr/$db_fw/$fw/";
```

Where `file_format_regex` is the pattern specified by the user and read from the database.

At this point I have the fields encapsulated by '%'.  I build a regex then apply it.

I'm replacing everything between percent signs with a *labeled* capture pattern
The `(?` specifies that it's a labeled pattern, the `<$1>` labels it with what we're
matching in first part of the `s///` from the format string (i.e., the labels).
Then I just apply the regex, which populates the internal hash called `%+` 
See the section on `%+` on this page: http://perldoc.perl.org/perlvar.html for more info

All that to say:
```
    # Build the labeled regex
    $file_format_regex  =~ s/$fw(.*?)$fw/(?<$1>.*?)/g;
    # Now apply it
    # Last $ is necessary so we don't match '' at the end
    $file_basename  =~ /$file_format_regex$/;
    for my $field (keys(%+)) {
      my $tagflag = $+{$field};
      # Insert result into database
    }
```

There's a bunch of extraneous and dangling stuff in the actual code, but you get the idea.
Thanks for reading :)
