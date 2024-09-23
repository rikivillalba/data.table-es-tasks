---
title: "Keys and fast binary search based subset"
date: "2024-09-23"
output:
  markdown::html_format
vignette: >
  %\VignetteIndexEntry{Keys and fast binary search based subset}
  %\VignetteEngine{knitr::knitr}
  \usepackage[utf8]{inputenc}
---



This vignette is aimed at those who are already familiar with *data.table* syntax, its general form, how to subset rows in `i`, select and compute on columns, add/modify/delete columns *by reference* in `j` and group by using `by`. If you're not familiar with these concepts, please read the *"Introduction to data.table"* and *"Reference semantics"* vignettes first.

***

## Data {#data}

We will use the same `flights` data as in the *"Introduction to data.table"* vignette.




``` r
flights <- fread("flights14.csv")
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18
dim(flights)
# [1] 253316     11
```

## Introduction

In this vignette, we will

* first introduce the concept of `key` in *data.table*, and set and use keys to perform *fast binary search* based subsets in `i`,

* see that we can combine key based subsets along with `j` and `by` in the exact same way as before,

* look at other additional useful arguments - `mult` and `nomatch`,

* and finally conclude by looking at the advantage of setting keys - perform *fast binary search based subsets* and compare with the traditional vector scan approach.

## 1. Keys

### a) What is a *key*?

In the *"Introduction to data.table"* vignette, we saw how to subset rows in `i` using logical expressions, row numbers and using `order()`. In this section, we will look at another way of subsetting incredibly fast - using *keys*.

But first, let's start by looking at *data.frames*. All *data.frames* have a row names attribute. Consider the *data.frame* `DF` below.


``` r
set.seed(1L)
DF = data.frame(ID1 = sample(letters[1:2], 10, TRUE),
                ID2 = sample(1:3, 10, TRUE),
                val = sample(10),
                stringsAsFactors = FALSE,
                row.names = sample(LETTERS[1:10]))
DF
#   ID1 ID2 val
# I   a   1  10
# D   a   3   9
# G   a   1   4
# A   a   1   7
# B   a   1   1
# E   b   1   8
# C   b   2   3
# J   b   1   2
# F   b   1   5
# H   a   2   6

rownames(DF)
#  [1] "I" "D" "G" "A" "B" "E" "C" "J" "F" "H"
```

We can *subset* a particular row using its row name as shown below:


``` r
DF["C", ]
#   ID1 ID2 val
# C   b   2   3
```

i.e., row names are more or less *an index* to rows of a *data.frame*. However,

1. Each row is limited to *exactly one* row name.

    But, a person (for example) has at least two names - a *first* and a *second* name. It is useful to organise a telephone directory by *surname* then *first name*.

2. And row names should be *unique*.

    
    ``` r
    rownames(DF) = sample(LETTERS[1:5], 10, TRUE)
    # Warning: non-unique values when setting 'row.names': 'C', 'D'
    # Error in `.rowNamesDF<-`(x, value = value): duplicate 'row.names' are not allowed
    ```

Now let's convert it to a *data.table*.


``` r
DT = as.data.table(DF)
DT
#        ID1   ID2   val
#     <char> <int> <int>
#  1:      a     1    10
#  2:      a     3     9
#  3:      a     1     4
#  4:      a     1     7
#  5:      a     1     1
#  6:      b     1     8
#  7:      b     2     3
#  8:      b     1     2
#  9:      b     1     5
# 10:      a     2     6

rownames(DT)
#  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10"
```

* Note that row names have been reset.

* *data.tables* never uses row names. Since *data.tables* **inherit** from *data.frames*, it still has the row names attribute. But it never uses them. We'll see in a moment as to why.

    If you would like to preserve the row names, use `keep.rownames = TRUE` in `as.data.table()` - this will create a new column called `rn` and assign row names to this column.

Instead, in *data.tables* we set and use `keys`. Think of a `key` as **supercharged rownames**.

#### Keys and their properties {#key-properties}

1. We can set keys on *multiple columns* and the column can be of *different types* -- *integer*, *numeric*, *character*, *factor*, *integer64* etc. *list* and *complex* types are not supported yet.

2. Uniqueness is not enforced, i.e., duplicate key values are allowed. Since rows are sorted by key, any duplicates in the key columns will appear consecutively.

3. Setting a `key` does *two* things:

    a. physically reorders the rows of the *data.table* by the column(s) provided *by reference*, always in *increasing* order.

    b. marks those columns as *key* columns by setting an attribute called `sorted` to the *data.table*.

    Since the rows are reordered, a *data.table* can have at most one key because it can not be sorted in more than one way.

For the rest of the vignette, we will work with `flights` data set.

### b) Set, get and use keys on a *data.table*

#### -- How can we set the column `origin` as key in the *data.table* `flights`?


``` r
setkey(flights, origin)
head(flights)
# Key: <origin>
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18
# 2:  2014     1     1        -5       -17      AA    EWR    MIA      161     1085    16
# 3:  2014     1     1       191       185      AA    EWR    DFW      214     1372    16
# 4:  2014     1     1        -1        -2      AA    EWR    DFW      214     1372    14
# 5:  2014     1     1        -3       -10      AA    EWR    MIA      154     1085     6
# 6:  2014     1     1         4       -17      AA    EWR    DFW      215     1372     9

## alternatively we can provide character vectors to the function 'setkeyv()'
# setkeyv(flights, "origin") # useful to program with
```

* You can use the function `setkey()` and provide the column names (without quoting them). This is helpful during interactive use.

* Alternatively you can pass a character vector of column names to the function `setkeyv()`. This is particularly useful while designing functions to pass columns to set key on as function arguments.

* Note that we did not have to assign the result back to a variable. This is because like the `:=` function we saw in the *"Reference semantics"* vignette, `setkey()` and `setkeyv()` modify the input *data.table* *by reference*. They return the result invisibly.

* The *data.table* is now reordered (or sorted) by the column we provided - `origin`. Since we reorder by reference, we only require additional memory of one column of length equal to the number of rows in the *data.table*, and is therefore very memory efficient.

* You can also set keys directly when creating *data.tables* using the `data.table()` function using `key` argument. It takes a character vector of column names.

#### set* and `:=`:

In *data.table*, the `:=` operator and all the `set*` (e.g., `setkey`, `setorder`, `setnames` etc.) functions are the only ones which modify the input object *by reference*.

Once you *key* a *data.table* by certain columns, you can subset by querying those key columns using the `.()` notation in `i`. Recall that `.()` is an *alias to* `list()`.

#### -- Use the key column `origin` to subset all rows where the origin airport matches *"JFK"*


``` r
flights[.("JFK")]
# Key: <origin>
#         year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#        <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#     1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
#     2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
#     3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
#     4:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
#     5:  2014     1     1        -2       -18      AA    JFK    LAX      338     2475    21
#    ---                                                                                    
# 81479:  2014    10    31        -4       -21      UA    JFK    SFO      337     2586    17
# 81480:  2014    10    31        -2       -37      UA    JFK    SFO      344     2586    18
# 81481:  2014    10    31         0       -33      UA    JFK    LAX      320     2475    17
# 81482:  2014    10    31        -6       -38      UA    JFK    SFO      343     2586     9
# 81483:  2014    10    31        -6       -38      UA    JFK    LAX      323     2475    11

## alternatively
# flights[J("JFK")] (or)
# flights[list("JFK")]
```

* The *key* column has already been set to `origin`. So it is sufficient to provide the value, here *"JFK"*, directly. The `.()` syntax helps identify that the task requires looking up the value *"JFK"* in the key column of *data.table* (here column `origin` of `flights` *data.table*).

* The *row indices* corresponding to the value *"JFK"* in `origin` is obtained first. And since there is no expression in `j`, all columns corresponding to those row indices are returned.

* On single column key of *character* type, you can drop the `.()` notation and use the values directly when subsetting, like subset using row names on *data.frames*.

    
    ``` r
    flights["JFK"]              ## same as flights[.("JFK")]
    ```

* We can subset any amount of values as required

    
    ``` r
    flights[c("JFK", "LGA")]    ## same as flights[.(c("JFK", "LGA"))]
    ```

    This returns all columns corresponding to those rows where `origin` column matches either *"JFK"* or *"LGA"*.

#### -- How can we get the column(s) a *data.table* is keyed by?

Using the function `key()`.


``` r
key(flights)
# [1] "origin"
```

* It returns a character vector of all the key columns.

* If no key is set, it returns `NULL`.

### c) Keys and multiple columns

To refresh, *keys* are like *supercharged* row names. We can set key on multiple columns and they can be of multiple types.

#### -- How can I set keys on both `origin` *and* `dest` columns?


``` r
setkey(flights, origin, dest)
head(flights)
# Key: <origin, dest>
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     2        -2       -25      EV    EWR    ALB       30      143     7
# 2:  2014     1     3        88        79      EV    EWR    ALB       29      143    23
# 3:  2014     1     4       220       211      EV    EWR    ALB       32      143    15
# 4:  2014     1     4        35        19      EV    EWR    ALB       32      143     7
# 5:  2014     1     5        47        42      EV    EWR    ALB       26      143     8
# 6:  2014     1     5        66        62      EV    EWR    ALB       31      143    23

## or alternatively
# setkeyv(flights, c("origin", "dest")) # provide a character vector of column names

key(flights)
# [1] "origin" "dest"
```

* It sorts the *data.table* first by the column `origin` and then by `dest` *by reference*.

#### -- Subset all rows using key columns where first key column `origin` matches *"JFK"* and second key column `dest` matches *"MIA"*


``` r
flights[.("JFK", "MIA")]
# Key: <origin, dest>
#        year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#       <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#    1:  2014     1     1        -1       -17      AA    JFK    MIA      161     1089    15
#    2:  2014     1     1         7        -8      AA    JFK    MIA      166     1089     9
#    3:  2014     1     1         2        -1      AA    JFK    MIA      164     1089    12
#    4:  2014     1     1         6         3      AA    JFK    MIA      157     1089     5
#    5:  2014     1     1         6       -12      AA    JFK    MIA      154     1089    17
#   ---                                                                                    
# 2746:  2014    10    31        -1       -22      AA    JFK    MIA      148     1089    16
# 2747:  2014    10    31        -3       -20      AA    JFK    MIA      146     1089     8
# 2748:  2014    10    31         2       -17      AA    JFK    MIA      150     1089     6
# 2749:  2014    10    31        -3       -12      AA    JFK    MIA      150     1089     5
# 2750:  2014    10    31        29         4      AA    JFK    MIA      146     1089    19
```

#### How does the subset work here? {#multiple-key-point}

* It is important to understand how this works internally. *"JFK"* is first matched against the first key column `origin`. And *within those matching rows*, *"MIA"* is matched against the second key column `dest` to obtain *row indices* where both `origin` and `dest` match the given values.

* Since no `j` is provided, we simply return *all columns* corresponding to those row indices.

#### -- Subset all rows where just the first key column `origin` matches *"JFK"*


``` r
key(flights)
# [1] "origin" "dest"

flights[.("JFK")] ## or in this case simply flights["JFK"], for convenience
# Key: <origin, dest>
#         year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#        <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#     1:  2014     1     1        10         4      B6    JFK    ABQ      280     1826    20
#     2:  2014     1     2       134       161      B6    JFK    ABQ      252     1826    22
#     3:  2014     1     7         6         6      B6    JFK    ABQ      269     1826    20
#     4:  2014     1     8        15       -15      B6    JFK    ABQ      259     1826    20
#     5:  2014     1     9        45        32      B6    JFK    ABQ      267     1826    20
#    ---                                                                                    
# 81479:  2014    10    31         0       -18      DL    JFK    TPA      142     1005     8
# 81480:  2014    10    31         1        -8      B6    JFK    TPA      149     1005    19
# 81481:  2014    10    31        -2       -22      B6    JFK    TPA      145     1005    14
# 81482:  2014    10    31        -8        -5      B6    JFK    TPA      149     1005     9
# 81483:  2014    10    31        -4       -18      B6    JFK    TPA      145     1005     8
```

* Since we did not provide any values for the second key column `dest`, it just matches *"JFK"* against the first key column `origin` and returns all the matched rows.

#### -- Subset all rows where just the second key column `dest` matches *"MIA"*


``` r
flights[.(unique(origin), "MIA")]
# Key: <origin, dest>
#        year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#       <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#    1:  2014     1     1        -5       -17      AA    EWR    MIA      161     1085    16
#    2:  2014     1     1        -3       -10      AA    EWR    MIA      154     1085     6
#    3:  2014     1     1        -5        -8      AA    EWR    MIA      157     1085    11
#    4:  2014     1     1        43        42      UA    EWR    MIA      155     1085    15
#    5:  2014     1     1        60        49      UA    EWR    MIA      162     1085    21
#   ---                                                                                    
# 9924:  2014    10    31       -11        -8      AA    LGA    MIA      157     1096    13
# 9925:  2014    10    31        -5       -11      AA    LGA    MIA      150     1096     9
# 9926:  2014    10    31        -2        10      AA    LGA    MIA      156     1096     6
# 9927:  2014    10    31        -2       -16      AA    LGA    MIA      156     1096    19
# 9928:  2014    10    31         1       -11      US    LGA    MIA      164     1096    15
```

#### What's happening here?

* Read [this](#multiple-key-point) again. The value provided for the second key column *"MIA"* has to find the matching values in `dest` key column *on the matching rows provided by the first key column `origin`*. We can not skip the values of key columns *before*. Therefore, we provide *all* unique values from key column `origin`.

* *"MIA"* is automatically recycled to fit the length of `unique(origin)` which is *3*.

## 2. Combining keys with `j` and `by`

All we have seen so far is the same concept -- obtaining *row indices* in `i`, but just using a different method -- using `keys`. It shouldn't be surprising that we can do exactly the same things in `j` and `by` as seen from the previous vignettes. We will highlight this with a few examples.

### a) Select in `j`

#### -- Return `arr_delay` column as a *data.table* corresponding to `origin = "LGA"` and `dest = "TPA"`.


``` r
key(flights)
# [1] "origin" "dest"
flights[.("LGA", "TPA"), .(arr_delay)]
#       arr_delay
#           <int>
#    1:         1
#    2:        14
#    3:       -17
#    4:        -4
#    5:       -12
#   ---          
# 1848:        39
# 1849:       -24
# 1850:       -12
# 1851:        21
# 1852:       -11
```

* The *row indices* corresponding to `origin == "LGA"` and `dest == "TPA"` are obtained using *key based subset*.

* Once we have the row indices, we look at `j` which requires only the `arr_delay` column. So we simply select the column `arr_delay` for those *row indices* in the exact same way as we have seen in *Introduction to data.table* vignette.

* We could have returned the result by using `with = FALSE` as well.

    
    ``` r
    flights[.("LGA", "TPA"), "arr_delay", with = FALSE]
    ```

### b) Chaining

#### -- On the result obtained above, use chaining to order the column in decreasing order.


``` r
flights[.("LGA", "TPA"), .(arr_delay)][order(-arr_delay)]
#       arr_delay
#           <int>
#    1:       486
#    2:       380
#    3:       351
#    4:       318
#    5:       300
#   ---          
# 1848:       -40
# 1849:       -43
# 1850:       -46
# 1851:       -48
# 1852:       -49
```

### c) Compute or *do* in `j`

#### -- Find the maximum arrival delay corresponding to `origin = "LGA"` and `dest = "TPA"`.


``` r
flights[.("LGA", "TPA"), max(arr_delay)]
# [1] 486
```

* We can verify that the result is identical to first value (486) from the previous example.

### d) *sub-assign* by reference using `:=` in `j`

We have seen this example already in the *Reference semantics* vignette. Let's take a look at all the `hours` available in the `flights` *data.table*:


``` r
# get all 'hours' in flights
flights[, sort(unique(hour))]
#  [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
```

We see that there are totally `25` unique values in the data. Both *0* and *24* hours seem to be present. Let's go ahead and replace *24* with *0*, but this time using *key*.


``` r
setkey(flights, hour)
key(flights)
# [1] "hour"
flights[.(24), hour := 0L]
#          year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#         <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#      1:  2014     4    15       598       602      DL    EWR    ATL      104      746     0
#      2:  2014     5    22       289       267      DL    EWR    ATL      102      746     0
#      3:  2014     7    14       277       253      DL    EWR    ATL      101      746     0
#      4:  2014     2    14       128       117      EV    EWR    BDL       27      116     0
#      5:  2014     6    17       127       119      EV    EWR    BDL       24      116     0
#     ---                                                                                    
# 253312:  2014     8     3         1       -13      DL    JFK    SJU      196     1598     0
# 253313:  2014    10     8         1         1      B6    JFK    SJU      199     1598     0
# 253314:  2014     7    14       211       219      B6    JFK    SLC      282     1990     0
# 253315:  2014     7     3       440       418      FL    LGA    ATL      107      762     0
# 253316:  2014     6    13       300       280      DL    LGA    PBI      140     1035     0
key(flights)
# NULL
```

* We first set `key` to `hour`. This reorders `flights` by the column `hour` and marks that column as the `key` column.

* Now we can subset on `hour` by using the `.()` notation. We subset for the value *24* and obtain the corresponding *row indices*.

* And on those row indices, we replace the `key` column with the value `0`.

* Since we have replaced values on the *key* column, the *data.table* `flights` isn't sorted by `hour` anymore. Therefore, the key has been automatically removed by setting to NULL.

Now, there shouldn't be any *24* in the `hour` column.


``` r
flights[, sort(unique(hour))]
#  [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
```

### e) Aggregation using `by`

Let's set the key back to `origin, dest` first.


``` r
setkey(flights, origin, dest)
key(flights)
# [1] "origin" "dest"
```

#### -- Get the maximum departure delay for each `month` corresponding to `origin = "JFK"`. Order the result by `month`


``` r
ans <- flights["JFK", max(dep_delay), keyby = month]
head(ans)
# Key: <month>
#    month    V1
#    <int> <int>
# 1:     1   881
# 2:     2  1014
# 3:     3   920
# 4:     4  1241
# 5:     5   853
# 6:     6   798
key(ans)
# [1] "month"
```

* We subset on the `key` column *origin* to obtain the *row indices* corresponding to *"JFK"*.

* Once we obtain the row indices, we only need two columns - `month` to group by and `dep_delay` to obtain `max()` for each group. *data.table's* query optimisation therefore subsets just those two columns corresponding to the *row indices* obtained in `i`, for speed and memory efficiency.

* And on that subset, we group by *month* and compute `max(dep_delay)`.

* We use `keyby` to automatically key that result by *month*. Now we understand what that means. In addition to ordering, it also sets *month* as the `key` column.

## 3. Additional arguments - `mult` and `nomatch`

### a) The *mult* argument

We can choose, for each query, if *"all"* the matching rows should be returned, or just the *"first"* or *"last"* using the `mult` argument. The default value is *"all"* - what we've seen so far.

#### -- Subset only the first matching row from all rows where `origin` matches *"JFK"* and `dest` matches *"MIA"*


``` r
flights[.("JFK", "MIA"), mult = "first"]
# Key: <origin, dest>
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1         6         3      AA    JFK    MIA      157     1089     5
```

#### -- Subset only the last matching row of all the rows where `origin` matches *"LGA", "JFK", "EWR"* and `dest` matches *"XNA"*


``` r
flights[.(c("LGA", "JFK", "EWR"), "XNA"), mult = "last"]
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     5    23       163       148      MQ    LGA    XNA      158     1147    18
# 2:    NA    NA    NA        NA        NA    <NA>    JFK    XNA       NA       NA    NA
# 3:  2014     2     3       231       268      EV    EWR    XNA      184     1131    12
```

* The query *"JFK", "XNA"* doesn't match any rows in `flights` and therefore returns `NA`.

* Once again, the query for second key column `dest`,  *"XNA"*, is recycled to fit the length of the query for first key column `origin`, which is of length 3.

### b) The *nomatch* argument

We can choose if queries that do not match should return `NA` or be skipped altogether using the `nomatch` argument.

#### -- From the previous example, Subset all rows only if there's a match


``` r
flights[.(c("LGA", "JFK", "EWR"), "XNA"), mult = "last", nomatch = NULL]
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     5    23       163       148      MQ    LGA    XNA      158     1147    18
# 2:  2014     2     3       231       268      EV    EWR    XNA      184     1131    12
```

* Default value for `nomatch` is `NA`. Setting `nomatch = NULL` skips queries with no matches.

* The query “JFK”, “XNA” doesn’t match any rows in flights and therefore is skipped.

## 4. binary search vs vector scans

We have seen so far how we can set and use keys to subset. But what's the advantage? For example, instead of doing:


``` r
# key by origin,dest columns
flights[.("JFK", "MIA")]
```

we could have done:


``` r
flights[origin == "JFK" & dest == "MIA"]
```

One advantage very likely is shorter syntax. But even more than that, *binary search based subsets* are **incredibly fast**.  

As the time goes `data.table` gets new optimization and currently the latter call is automatically optimized to use *binary search*.  
To use slow *vector scan* key needs to be removed.  


``` r
setkey(flights, NULL)
flights[origin == "JFK" & dest == "MIA"]
```

### a) Performance of binary search approach

To illustrate, let's create a sample *data.table* with 20 million rows and three columns and key it by columns `x` and `y`.


``` r
set.seed(2L)
N = 2e7L
DT = data.table(x = sample(letters, N, TRUE),
                y = sample(1000L, N, TRUE),
                val = runif(N))
print(object.size(DT), units = "Mb")
# 381.5 Mb
```

`DT` is ~380MB. It is not really huge, but this will do to illustrate the point.

From what we have seen in the Introduction to data.table section, we can subset those rows where columns `x = "g"` and `y = 877` as follows:


``` r
key(DT)
# NULL
## (1) Usual way of subsetting - vector scan approach
t1 <- system.time(ans1 <- DT[x == "g" & y == 877L])
t1
#    user  system elapsed 
#    0.17    0.04    0.89
head(ans1)
#         x     y        val
#    <char> <int>      <num>
# 1:      g   877 0.57059767
# 2:      g   877 0.74859806
# 3:      g   877 0.03616756
# 4:      g   877 0.28087868
# 5:      g   877 0.83727299
# 6:      g   877 0.43867189
dim(ans1)
# [1] 762   3
```

Now let's try to subset by using keys.


``` r
setkeyv(DT, c("x", "y"))
key(DT)
# [1] "x" "y"
## (2) Subsetting using keys
t2 <- system.time(ans2 <- DT[.("g", 877L)])
t2
#    user  system elapsed 
#       0       0       0
head(ans2)
# Key: <x, y>
#         x     y        val
#    <char> <int>      <num>
# 1:      g   877 0.57059767
# 2:      g   877 0.74859806
# 3:      g   877 0.03616756
# 4:      g   877 0.28087868
# 5:      g   877 0.83727299
# 6:      g   877 0.43867189
dim(ans2)
# [1] 762   3

identical(ans1$val, ans2$val)
# [1] TRUE
```

* The speed-up is **~890x**!

### b) Why does keying a *data.table* result in blazing fast subsets?

To understand that, let's first look at what *vector scan approach* (method 1) does.

#### Vector scan approach

* The column `x` is searched for the value *"g"* row by row, on all 20 million of them. This results in a *logical vector* of size 20 million, with values `TRUE, FALSE or NA` corresponding to `x`'s value.

* Similarly, the column `y` is searched for `877` on all 20 million rows one by one, and stored in another logical vector.

* Element wise `&` operations are performed on the intermediate logical vectors and all the rows where the expression evaluates to `TRUE` are returned.

This is what we call a *vector scan approach*. And this is quite inefficient, especially on larger tables and when one needs repeated subsetting, because it has to scan through all the rows each time.

Now let us look at binary search approach (method 2). Recall from [Properties of key](#key-properties) - *setting keys reorders the data.table by key columns*. Since the data is sorted, we don't have to *scan through the entire length of the column*! We can instead use *binary search* to search a value in `O(log n)` as opposed to `O(n)` in case of *vector scan approach*, where `n` is the number of rows in the *data.table*.

#### Binary search approach

Here's a very simple illustration. Let's consider the (sorted) numbers shown below:

```
1, 5, 10, 19, 22, 23, 30
```

Suppose we'd like to find the matching position of the value *1*, using binary search, this is how we would proceed - because we know that the data is *sorted*.

* Start with the middle value = 19. Is 1 == 19? No. 1 < 19.

* Since the value we're looking for is smaller than 19, it should be somewhere before 19. So we can discard the rest of the half that are >= 19.

* Our set is now reduced to *1, 5, 10*. Grab the middle value once again = 5. Is 1 == 5? No. 1 < 5.

* Our set is reduced to *1*. Is 1 == 1? Yes. The corresponding index is also 1. And that's the only match.

A vector scan approach on the other hand would have to scan through all the values (here, 7).

It can be seen that with every search we reduce the number of searches by half. This is why *binary search* based subsets are **incredibly fast**. Since rows of each column of *data.tables* have contiguous locations in memory, the operations are performed in a very cache efficient manner (also contributes to *speed*).

In addition, since we obtain the matching row indices directly without having to create those huge logical vectors (equal to the number of rows in a *data.table*), it is quite **memory efficient** as well.

## Summary

In this vignette, we have learnt another method to subset rows in `i` by keying a *data.table*. Setting keys allows us to perform blazing fast subsets by using *binary search*. In particular, we have seen how to

* set key and subset using the key on a *data.table*.

* subset using keys which fetches *row indices* in `i`, but much faster.

* combine key based subsets with `j` and `by`. Note that the `j` and `by` operations are exactly the same as before.

Key based subsets are **incredibly fast** and are particularly useful when the task involves *repeated subsetting*. But it may not be always desirable to set key and physically reorder the *data.table*. In the next vignette, we will address this using a *new* feature -- *secondary indexes*.



