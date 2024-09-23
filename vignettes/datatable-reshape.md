---
title: "Efficient reshaping using data.tables"
date: "2024-09-23"
output:
  markdown::html_format
vignette: >
  %\VignetteIndexEntry{Efficient reshaping using data.tables}
  %\VignetteEngine{knitr::knitr}
  \usepackage[utf8]{inputenc}
---



This vignette discusses the default usage of reshaping functions `melt` (wide to long) and `dcast` (long to wide) for *data.tables* as well as the **new extended functionalities** of melting and casting on *multiple columns* available from `v1.9.6`.

***



## Data

We will load the data sets directly within sections.

## Introduction

The `melt` and `dcast` functions for `data.table`s are for reshaping wide-to-long and long-to-wide, respectively; the implementations are specifically designed with large in-memory data (e.g. 10Gb) in mind.

In this vignette, we will

1. First briefly look at the default `melt`ing and `dcast`ing of `data.table`s to convert them from *wide* to *long* format and _vice versa_

2. Look at scenarios where the current functionalities become cumbersome and inefficient

3. Finally look at the new improvements to both `melt` and `dcast` methods for `data.table`s to handle multiple columns simultaneously.

The extended functionalities are in line with `data.table`'s philosophy of performing operations efficiently and in a straightforward manner.

## 1. Default functionality

### a) `melt`ing `data.table`s (wide to long)

Suppose we have a `data.table` (artificial data) as shown below:


``` r
s1 <- "family_id age_mother dob_child1 dob_child2 dob_child3
1         30 1998-11-26 2000-01-29         NA
2         27 1996-06-22         NA         NA
3         26 2002-07-11 2004-04-05 2007-09-02
4         32 2004-10-10 2009-08-27 2012-07-21
5         29 2000-12-05 2005-02-28         NA"
DT <- fread(s1)
DT
#    family_id age_mother dob_child1 dob_child2 dob_child3
#        <int>      <int>     <IDat>     <IDat>     <IDat>
# 1:         1         30 1998-11-26 2000-01-29       <NA>
# 2:         2         27 1996-06-22       <NA>       <NA>
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21
# 5:         5         29 2000-12-05 2005-02-28       <NA>
## dob stands for date of birth.

str(DT)
# Classes 'data.table' and 'data.frame':	5 obs. of  5 variables:
#  $ family_id : int  1 2 3 4 5
#  $ age_mother: int  30 27 26 32 29
#  $ dob_child1: IDate, format: "1998-11-26" "1996-06-22" "2002-07-11" ...
#  $ dob_child2: IDate, format: "2000-01-29" NA "2004-04-05" ...
#  $ dob_child3: IDate, format: NA NA "2007-09-02" ...
#  - attr(*, ".internal.selfref")=<externalptr>
```


#### - Convert `DT` to *long* form where each `dob` is a separate observation.

We could accomplish this using `melt()` by specifying `id.vars` and `measure.vars` arguments as follows:


``` r
DT.m1 = melt(DT, id.vars = c("family_id", "age_mother"),
                measure.vars = c("dob_child1", "dob_child2", "dob_child3"))
DT.m1
#     family_id age_mother   variable      value
#         <int>      <int>     <fctr>     <IDat>
#  1:         1         30 dob_child1 1998-11-26
#  2:         2         27 dob_child1 1996-06-22
#  3:         3         26 dob_child1 2002-07-11
#  4:         4         32 dob_child1 2004-10-10
#  5:         5         29 dob_child1 2000-12-05
#  6:         1         30 dob_child2 2000-01-29
#  7:         2         27 dob_child2       <NA>
#  8:         3         26 dob_child2 2004-04-05
#  9:         4         32 dob_child2 2009-08-27
# 10:         5         29 dob_child2 2005-02-28
# 11:         1         30 dob_child3       <NA>
# 12:         2         27 dob_child3       <NA>
# 13:         3         26 dob_child3 2007-09-02
# 14:         4         32 dob_child3 2012-07-21
# 15:         5         29 dob_child3       <NA>
str(DT.m1)
# Classes 'data.table' and 'data.frame':	15 obs. of  4 variables:
#  $ family_id : int  1 2 3 4 5 1 2 3 4 5 ...
#  $ age_mother: int  30 27 26 32 29 30 27 26 32 29 ...
#  $ variable  : Factor w/ 3 levels "dob_child1","dob_child2",..: 1 1 1 1 1 2 2 2 2 2 ...
#  $ value     : IDate, format: "1998-11-26" "1996-06-22" "2002-07-11" ...
#  - attr(*, ".internal.selfref")=<externalptr>
```

* `measure.vars` specify the set of columns we would like to collapse (or combine) together.

* We can also specify column *indices* instead of *names*.

* By default, `variable` column is of type `factor`. Set `variable.factor` argument to `FALSE` if you'd like to return a *`character`* vector instead.

* By default, the molten columns are automatically named `variable` and `value`.

* `melt` preserves column attributes in result.

#### - Name the `variable` and `value` columns to `child` and `dob` respectively



``` r
DT.m1 = melt(DT, measure.vars = c("dob_child1", "dob_child2", "dob_child3"),
               variable.name = "child", value.name = "dob")
DT.m1
#     family_id age_mother      child        dob
#         <int>      <int>     <fctr>     <IDat>
#  1:         1         30 dob_child1 1998-11-26
#  2:         2         27 dob_child1 1996-06-22
#  3:         3         26 dob_child1 2002-07-11
#  4:         4         32 dob_child1 2004-10-10
#  5:         5         29 dob_child1 2000-12-05
#  6:         1         30 dob_child2 2000-01-29
#  7:         2         27 dob_child2       <NA>
#  8:         3         26 dob_child2 2004-04-05
#  9:         4         32 dob_child2 2009-08-27
# 10:         5         29 dob_child2 2005-02-28
# 11:         1         30 dob_child3       <NA>
# 12:         2         27 dob_child3       <NA>
# 13:         3         26 dob_child3 2007-09-02
# 14:         4         32 dob_child3 2012-07-21
# 15:         5         29 dob_child3       <NA>
```

* By default, when one of `id.vars` or `measure.vars` is missing, the rest of the columns are *automatically assigned* to the missing argument.

* When neither `id.vars` nor `measure.vars` are specified, as mentioned under `?melt`, all *non*-`numeric`, `integer`, `logical` columns will be assigned to `id.vars`.

    In addition, a warning message is issued highlighting the columns that are automatically considered to be `id.vars`.

### b) `dcast`ing `data.table`s (long to wide)

In the previous section, we saw how to get from wide form to long form. Let's see the reverse operation in this section.

#### - How can we get back to the original data table `DT` from `DT.m1`?

That is, we'd like to collect all *child* observations corresponding to each `family_id, age_mother` together under the same row. We can accomplish it using `dcast` as follows:


``` r
dcast(DT.m1, family_id + age_mother ~ child, value.var = "dob")
# Key: <family_id, age_mother>
#    family_id age_mother dob_child1 dob_child2 dob_child3
#        <int>      <int>     <IDat>     <IDat>     <IDat>
# 1:         1         30 1998-11-26 2000-01-29       <NA>
# 2:         2         27 1996-06-22       <NA>       <NA>
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21
# 5:         5         29 2000-12-05 2005-02-28       <NA>
```

* `dcast` uses *formula* interface. The variables on the *LHS* of formula represents the *id* vars and *RHS* the *measure*  vars.

* `value.var` denotes the column to be filled in with while casting to wide format.

* `dcast` also tries to preserve attributes in result wherever possible.

#### - Starting from `DT.m1`, how can we get the number of children in each family?

You can also pass a function to aggregate by in `dcast` with the argument `fun.aggregate`. This is particularly essential when the formula provided does not identify single observation for each cell.


``` r
dcast(DT.m1, family_id ~ ., fun.agg = function(x) sum(!is.na(x)), value.var = "dob")
# Key: <family_id>
#    family_id     .
#        <int> <int>
# 1:         1     2
# 2:         2     1
# 3:         3     3
# 4:         4     3
# 5:         5     2
```

Check `?dcast` for other useful arguments and additional examples.

## 2. Limitations in current `melt/dcast` approaches

So far we've seen features of `melt` and `dcast` that are implemented efficiently for `data.table`s, using internal `data.table` machinery (*fast radix ordering*, *binary search* etc.).

However, there are situations we might run into where the desired operation is not expressed in a straightforward manner. For example, consider the `data.table` shown below:


``` r
s2 <- "family_id age_mother dob_child1 dob_child2 dob_child3 gender_child1 gender_child2 gender_child3
1         30 1998-11-26 2000-01-29         NA             1             2            NA
2         27 1996-06-22         NA         NA             2            NA            NA
3         26 2002-07-11 2004-04-05 2007-09-02             2             2             1
4         32 2004-10-10 2009-08-27 2012-07-21             1             1             1
5         29 2000-12-05 2005-02-28         NA             2             1            NA"
DT <- fread(s2)
DT
#    family_id age_mother dob_child1 dob_child2 dob_child3 gender_child1 gender_child2 gender_child3
#        <int>      <int>     <IDat>     <IDat>     <IDat>         <int>         <int>         <int>
# 1:         1         30 1998-11-26 2000-01-29       <NA>             1             2            NA
# 2:         2         27 1996-06-22       <NA>       <NA>             2            NA            NA
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02             2             2             1
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21             1             1             1
# 5:         5         29 2000-12-05 2005-02-28       <NA>             2             1            NA
## 1 = female, 2 = male
```

And you'd like to combine (`melt`) all the `dob` columns together, and `gender` columns together. Using the current functionality, we can do something like this:


``` r
DT.m1 = melt(DT, id = c("family_id", "age_mother"))
DT.m1[, c("variable", "child") := tstrsplit(variable, "_", fixed = TRUE)]
#     family_id age_mother variable      value  child
#         <int>      <int>   <char>     <IDat> <char>
#  1:         1         30      dob 1998-11-26 child1
#  2:         2         27      dob 1996-06-22 child1
#  3:         3         26      dob 2002-07-11 child1
#  4:         4         32      dob 2004-10-10 child1
#  5:         5         29      dob 2000-12-05 child1
#  6:         1         30      dob 2000-01-29 child2
#  7:         2         27      dob       <NA> child2
#  8:         3         26      dob 2004-04-05 child2
#  9:         4         32      dob 2009-08-27 child2
# 10:         5         29      dob 2005-02-28 child2
# 11:         1         30      dob       <NA> child3
# 12:         2         27      dob       <NA> child3
# 13:         3         26      dob 2007-09-02 child3
# 14:         4         32      dob 2012-07-21 child3
# 15:         5         29      dob       <NA> child3
# 16:         1         30   gender 1970-01-02 child1
# 17:         2         27   gender 1970-01-03 child1
# 18:         3         26   gender 1970-01-03 child1
# 19:         4         32   gender 1970-01-02 child1
# 20:         5         29   gender 1970-01-03 child1
# 21:         1         30   gender 1970-01-03 child2
# 22:         2         27   gender       <NA> child2
# 23:         3         26   gender 1970-01-03 child2
# 24:         4         32   gender 1970-01-02 child2
# 25:         5         29   gender 1970-01-02 child2
# 26:         1         30   gender       <NA> child3
# 27:         2         27   gender       <NA> child3
# 28:         3         26   gender 1970-01-02 child3
# 29:         4         32   gender 1970-01-02 child3
# 30:         5         29   gender       <NA> child3
#     family_id age_mother variable      value  child
DT.c1 = dcast(DT.m1, family_id + age_mother + child ~ variable, value.var = "value")
DT.c1
# Key: <family_id, age_mother, child>
#     family_id age_mother  child        dob     gender
#         <int>      <int> <char>     <IDat>     <IDat>
#  1:         1         30 child1 1998-11-26 1970-01-02
#  2:         1         30 child2 2000-01-29 1970-01-03
#  3:         1         30 child3       <NA>       <NA>
#  4:         2         27 child1 1996-06-22 1970-01-03
#  5:         2         27 child2       <NA>       <NA>
#  6:         2         27 child3       <NA>       <NA>
#  7:         3         26 child1 2002-07-11 1970-01-03
#  8:         3         26 child2 2004-04-05 1970-01-03
#  9:         3         26 child3 2007-09-02 1970-01-02
# 10:         4         32 child1 2004-10-10 1970-01-02
# 11:         4         32 child2 2009-08-27 1970-01-02
# 12:         4         32 child3 2012-07-21 1970-01-02
# 13:         5         29 child1 2000-12-05 1970-01-03
# 14:         5         29 child2 2005-02-28 1970-01-02
# 15:         5         29 child3       <NA>       <NA>

str(DT.c1) ## gender column is character type now!
# Classes 'data.table' and 'data.frame':	15 obs. of  5 variables:
#  $ family_id : int  1 1 1 2 2 2 3 3 3 4 ...
#  $ age_mother: int  30 30 30 27 27 27 26 26 26 32 ...
#  $ child     : chr  "child1" "child2" "child3" "child1" ...
#  $ dob       : IDate, format: "1998-11-26" "2000-01-29" NA ...
#  $ gender    : IDate, format: "1970-01-02" "1970-01-03" NA ...
#  - attr(*, ".internal.selfref")=<externalptr> 
#  - attr(*, "sorted")= chr [1:3] "family_id" "age_mother" "child"
```

#### Issues

1. What we wanted to do was to combine all the `dob` and `gender` type columns together respectively. Instead, we are combining *everything* together, and then splitting them again. I think it's easy to see that it's quite roundabout (and inefficient).

    As an analogy, imagine you've a closet with four shelves of clothes and you'd like to put together the clothes from shelves 1 and 2 together (in 1), and 3 and 4 together (in 3). What we are doing is more or less to combine all the clothes together, and then split them back on to shelves 1 and 3!

2. The columns to `melt` may be of different types, as in this case (`character` and `integer` types). By `melt`ing them all together, the columns will be coerced in result, as explained by the warning message above and shown from output of `str(DT.c1)`, where `gender` has been converted to *`character`* type.

3. We are generating an additional column by splitting the `variable` column into two columns, whose purpose is quite cryptic. We do it because we need it for *casting* in the next step.

4. Finally, we cast the data set. But the issue is it's a much more computationally involved operation than *melt*. Specifically, it requires computing the order of the variables in formula, and that's costly.

In fact, `stats::reshape` is capable of performing this operation in a very straightforward manner. It is an extremely useful and often underrated function. You should definitely give it a try!

## 3. Enhanced (new) functionality

### a) Enhanced `melt`

Since we'd like for `data.table`s to perform this operation straightforward and efficient using the same interface, we went ahead and implemented an *additional functionality*, where we can `melt` to multiple columns *simultaneously*.

#### - `melt` multiple columns simultaneously

The idea is quite simple. We pass a list of columns to `measure.vars`, where each element of the list contains the columns that should be combined together.


``` r
colA = paste0("dob_child", 1:3)
colB = paste0("gender_child", 1:3)
DT.m2 = melt(DT, measure = list(colA, colB), value.name = c("dob", "gender"))
DT.m2
#     family_id age_mother variable        dob gender
#         <int>      <int>   <fctr>     <IDat>  <int>
#  1:         1         30        1 1998-11-26      1
#  2:         2         27        1 1996-06-22      2
#  3:         3         26        1 2002-07-11      2
#  4:         4         32        1 2004-10-10      1
#  5:         5         29        1 2000-12-05      2
#  6:         1         30        2 2000-01-29      2
#  7:         2         27        2       <NA>     NA
#  8:         3         26        2 2004-04-05      2
#  9:         4         32        2 2009-08-27      1
# 10:         5         29        2 2005-02-28      1
# 11:         1         30        3       <NA>     NA
# 12:         2         27        3       <NA>     NA
# 13:         3         26        3 2007-09-02      1
# 14:         4         32        3 2012-07-21      1
# 15:         5         29        3       <NA>     NA

str(DT.m2) ## col type is preserved
# Classes 'data.table' and 'data.frame':	15 obs. of  5 variables:
#  $ family_id : int  1 2 3 4 5 1 2 3 4 5 ...
#  $ age_mother: int  30 27 26 32 29 30 27 26 32 29 ...
#  $ variable  : Factor w/ 3 levels "1","2","3": 1 1 1 1 1 2 2 2 2 2 ...
#  $ dob       : IDate, format: "1998-11-26" "1996-06-22" "2002-07-11" ...
#  $ gender    : int  1 2 2 1 2 2 NA 2 1 1 ...
#  - attr(*, ".internal.selfref")=<externalptr>
```

* We can remove the `variable` column if necessary.

* The functionality is implemented entirely in C, and is therefore both *fast* and *memory efficient* in addition to being *straightforward*.

#### - Using `patterns()`

Usually in these problems, the columns we'd like to melt can be distinguished by a common pattern. We can use the function `patterns()`, implemented for convenience, to provide regular expressions for the columns to be combined together. The above operation can be rewritten as:


``` r
DT.m2 = melt(DT, measure = patterns("^dob", "^gender"), value.name = c("dob", "gender"))
DT.m2
#     family_id age_mother variable        dob gender
#         <int>      <int>   <fctr>     <IDat>  <int>
#  1:         1         30        1 1998-11-26      1
#  2:         2         27        1 1996-06-22      2
#  3:         3         26        1 2002-07-11      2
#  4:         4         32        1 2004-10-10      1
#  5:         5         29        1 2000-12-05      2
#  6:         1         30        2 2000-01-29      2
#  7:         2         27        2       <NA>     NA
#  8:         3         26        2 2004-04-05      2
#  9:         4         32        2 2009-08-27      1
# 10:         5         29        2 2005-02-28      1
# 11:         1         30        3       <NA>     NA
# 12:         2         27        3       <NA>     NA
# 13:         3         26        3 2007-09-02      1
# 14:         4         32        3 2012-07-21      1
# 15:         5         29        3       <NA>     NA
```

#### - Using `measure()` to specify `measure.vars` via separator or pattern

If, as in the data above, the input columns to melt have regular
names, then we can use `measure`, which allows specifying the columns
to melt via a separator or a regex. For example consider the iris
data,


``` r
(two.iris = data.table(datasets::iris)[c(1,150)])
#    Sepal.Length Sepal.Width Petal.Length Petal.Width   Species
#           <num>       <num>        <num>       <num>    <fctr>
# 1:          5.1         3.5          1.4         0.2    setosa
# 2:          5.9         3.0          5.1         1.8 virginica
```

The iris data has four numeric columns with a regular structure: first
the flower part, then a period, then the measurement dimension. To
specify that we want to melt those four columns, we can use `measure`
with `sep="."` which means to use `strsplit` on all column names; the
columns which result in the maximum number of groups after splitting
will be used as `measure.vars`:


``` r
melt(two.iris, measure.vars = measure(part, dim, sep="."))
#      Species   part    dim value
#       <fctr> <char> <char> <num>
# 1:    setosa  Sepal Length   5.1
# 2: virginica  Sepal Length   5.9
# 3:    setosa  Sepal  Width   3.5
# 4: virginica  Sepal  Width   3.0
# 5:    setosa  Petal Length   1.4
# 6: virginica  Petal Length   5.1
# 7:    setosa  Petal  Width   0.2
# 8: virginica  Petal  Width   1.8
```

The first two arguments to `measure` in the code above (`part` and
`dim`) are used to name the output columns; the number of arguments
must equal the max number of groups after splitting with `sep`.

If we want two value columns, one for each part, we can use the
special `value.name` keyword, which means to output a value column
for each unique name found in that group:


``` r
melt(two.iris, measure.vars = measure(value.name, dim, sep="."))
#      Species    dim Sepal Petal
#       <fctr> <char> <num> <num>
# 1:    setosa Length   5.1   1.4
# 2: virginica Length   5.9   5.1
# 3:    setosa  Width   3.5   0.2
# 4: virginica  Width   3.0   1.8
```

Using the code above we get one value column per flower part. If we
instead want a value column for each measurement dimension, we can do


``` r
melt(two.iris, measure.vars = measure(part, value.name, sep="."))
#      Species   part Length Width
#       <fctr> <char>  <num> <num>
# 1:    setosa  Sepal    5.1   3.5
# 2: virginica  Sepal    5.9   3.0
# 3:    setosa  Petal    1.4   0.2
# 4: virginica  Petal    5.1   1.8
```

Going back to the example of the data with families and children, we
can see a more complex usage of `measure`, involving a function which
is used to convert the `child` string values to integers:


``` r
DT.m3 = melt(DT, measure = measure(value.name, child=as.integer, sep="_child"))
DT.m3
#     family_id age_mother child        dob gender
#         <int>      <int> <int>     <IDat>  <int>
#  1:         1         30     1 1998-11-26      1
#  2:         2         27     1 1996-06-22      2
#  3:         3         26     1 2002-07-11      2
#  4:         4         32     1 2004-10-10      1
#  5:         5         29     1 2000-12-05      2
#  6:         1         30     2 2000-01-29      2
#  7:         2         27     2       <NA>     NA
#  8:         3         26     2 2004-04-05      2
#  9:         4         32     2 2009-08-27      1
# 10:         5         29     2 2005-02-28      1
# 11:         1         30     3       <NA>     NA
# 12:         2         27     3       <NA>     NA
# 13:         3         26     3 2007-09-02      1
# 14:         4         32     3 2012-07-21      1
# 15:         5         29     3       <NA>     NA
```

In the code above we used `sep="_child"` which results in melting only
the columns which contain that string (six column names split into two
groups each). The `child=as.integer` argument means the second group
will result in an output column named `child` with values defined by
plugging the character strings from that group into the function
`as.integer`.

Finally we consider an example (borrowed from tidyr package) where we
need to define the groups using a regular expression rather than a
separator.


``` r
(who <- data.table(id=1, new_sp_m5564=2, newrel_f65=3))
#       id new_sp_m5564 newrel_f65
#    <num>        <num>      <num>
# 1:     1            2          3
melt(who, measure.vars = measure(
  diagnosis, gender, ages, pattern="new_?(.*)_(.)(.*)"))
#       id diagnosis gender   ages value
#    <num>    <char> <char> <char> <num>
# 1:     1        sp      m   5564     2
# 2:     1       rel      f     65     3
```

When using the `pattern` argument, it must be a Perl-compatible
regular expression containing the same number of capture groups
(parenthesized sub-expressions) as the number other arguments (group
names). The code below shows how to use a more complex regex with five
groups, two numeric output columns, and an anonymous type conversion
function,


``` r
melt(who, measure.vars = measure(
  diagnosis, gender, ages,
  ymin=as.numeric,
  ymax=function(y) ifelse(nzchar(y), as.numeric(y), Inf),
  pattern="new_?(.*)_(.)(([0-9]{2})([0-9]{0,2}))"
))
#       id diagnosis gender   ages  ymin  ymax value
#    <num>    <char> <char> <char> <num> <num> <num>
# 1:     1        sp      m   5564    55    64     2
# 2:     1       rel      f     65    65   Inf     3
```

### b) Enhanced `dcast`

Okay great! We can now melt into multiple columns simultaneously. Now given the data set `DT.m2` as shown above, how can we get back to the same format as the original data we started with?

If we use the current functionality of `dcast`, then we'd have to cast twice and bind the results together. But that's once again verbose, not straightforward and is also inefficient.

#### - Casting multiple `value.var`s simultaneously

We can now provide **multiple `value.var` columns** to `dcast` for `data.table`s directly so that the operations are taken care of internally and efficiently.


``` r
## new 'cast' functionality - multiple value.vars
DT.c2 = dcast(DT.m2, family_id + age_mother ~ variable, value.var = c("dob", "gender"))
DT.c2
# Key: <family_id, age_mother>
#    family_id age_mother      dob_1      dob_2      dob_3 gender_1 gender_2 gender_3
#        <int>      <int>     <IDat>     <IDat>     <IDat>    <int>    <int>    <int>
# 1:         1         30 1998-11-26 2000-01-29       <NA>        1        2       NA
# 2:         2         27 1996-06-22       <NA>       <NA>        2       NA       NA
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02        2        2        1
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21        1        1        1
# 5:         5         29 2000-12-05 2005-02-28       <NA>        2        1       NA
```

* Attributes are preserved in result wherever possible.

* Everything is taken care of internally, and efficiently. In addition to being fast, it is also very memory efficient.

#

#### Multiple functions to `fun.aggregate`:

You can also provide *multiple functions* to `fun.aggregate` to `dcast` for *data.tables*. Check the examples in `?dcast` which illustrates this functionality.



#

***
