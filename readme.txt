Files:  glen_anderson_fp.rkt

Code Structure: In lines 7 to 16 I 'require' files like net/url for web access, planet neil/csv:2:0 for the CSV reader library and plot for the
  plot library. In lines 18-88 I define some fundamental procedures that are used throughout my program. Then from lines 101 to 129 the program
 reads a stock ticker symbol from the input, downloads the csv file of the stock data for that input, then arranges it into a list. Then lines
 132 to 143 arrange the data in different forms for different uses later on. Lines 181 to 187 define moving averages for different day ranges
 using sums of prices defined in lines 171 to 178 and the procedure defined in lines 160 to 169.Line 194 defines the MACD-line defined in lines
 189 to 192 and EMA 26. Line 196 defines signal-line using the EMA function and the MACD-line. Then line 203 defines MACD-histogram using the
 MACD-line and signal-line. In lines 206 to 229 is the code for the  graph for the MACD indicator and the stock price. In lines 230 to 242 is
 the code for just the MACD indicator. Lines 246 to 252 graph the stock's volume.Lines 255 to 271 graph the stocks price and 3 different moving
 averages. Lines 274 to 298 define the data for the stochastic indicator, which is graphed by the code from line 301 to 312.

Using Ideas From Class: My code uses lists and list manipulations as a way to hold all of the data for graphing and as a way to manipulate
      all of the data. One example of this is how I convert the long string of CSV data into a list with each cons cell having a day index
      and a price for that day. On line 129 I use csv-map (a version of map) to map a function that takes the car and fifth of each row
     ( which are the date and price) to each row. Then on line 132 I use myrecursive make-indexed function (defined on line 98) and integers (define from 70 to 74). To reconstruct the list to have an index instead of a date as a string. On line 135 I map list->vector across a flatten 
     version of the indexed list. Because my indexed list of data is a list of cons cells with an index in the car and price in the cdr, I 
     map flatten on the list and define the flattened version as closing-indexedf. Then from lines 160 to 169 I define a procedure  that 
     recursively goes down the list and applies a formula. Howeve, since the first day of the new list (after the formula) is not 0 I have to 
     use the list-tail function on 'integers' to start on a different day index. The rest of my code is similar. It consists of reconstructing
     the closing-indexedf list and indexing with different days to match the index of other averages that the formula uses. 

How to run Code: My code is easy to run. Click run and enter a ticker symbol for the input. (the neil:csv library might take a little while to
    load at first). Some example ticker symbols are: googl, f, aapl, clf, or emc. Then 5 different windows with different technical idicators
    will pop up. The graphs may not beeasy to read at first but by horizontally stretching them and zooming in, you can make them easier to
    read.

Code I'm happy with: I'm happy with the way I applied the different indicator formulas to lists of data. I think recursively reconstructing
     new lists based on the formula for an indicator and the original list was a good way to achieve my goal.

Annoying things: One annoying thing was that Racket's  (plot (function....))  didn't work. I was going to use this by passing list-ref
	 as a function that would return the price for the given x (day index). However, this did not work for some reason, so instead
	 I had to (map list->vector (flatten..)) over every list I created and graph the vectors instead. Another annoying thing was with my
	 EMA formula. EMA is an Exponential Moving Average formula that doesn't start on the first day (day 0). This can get very confusing
 	 using list-tail to match the day indexes when dealing with a formula(like MACD-line) that uses two different EMAs that start on 
         different day indexes. Another annoying thing was that Scheme has no way to look 'backwards' at lists, so to calculate a simple moving
	 average I had to 'look ahead' to calculate the average.
	 
	 
