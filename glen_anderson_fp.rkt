;;;;; Final Project
;;;;  Glen Anderson
;;;   May 2, 2014

#lang racket

; To access csv file from yahoo finance
(require net/url)

;CSV reader library
(require (planet neil/csv:2:0))

;Plot library
(require plot) 

(plot-new-window? #t)

;Last index
(define (last lst)
  (if (null?(cdr lst))
      (car (car lst))
      (last (cdr lst))))

;Accumulate
(define (accumulate op initial sequence)
  (if (null? sequence)
      initial
      (op (car sequence)
          (accumulate op initial (cdr sequence)))))

;Finds and returns maximum number of a list
(define (list-max lst)
  (define (iter lst sofar)
    (cond((null? lst) sofar)
         ((>(car lst) sofar) (iter (cdr lst) (car lst)))
         ((iter (cdr lst) sofar))))
  (iter lst 0))

;Finds and returns minimum number of a list
(define (list-min lst)
  (define (iter lst sofar)
    (cond((null? lst) sofar)
         ((<(car lst) sofar) (iter (cdr lst) (car lst)))
         ((iter (cdr lst) sofar))))
  (iter lst 0))

;;returns minimum cdr of a list of cons cells
(define (min-list lst)
  (define (iter lst so-far)
    (cond ((null? lst) so-far)
          ((< (cdr (car lst)) so-far) (iter (cdr lst) (cdr (car lst))))
          ((> (cdr (car lst)) so-far) (iter (cdr lst) so-far))
          ((equal? (cdr (car lst)) so-far) (iter (cdr lst) (cdr (car lst))))))  
  (iter lst (cdr (car lst))))

;;returns maximum cdr of a list of cons cells
(define (max-list lst)
  (define (iter lst so-far)
    (cond ((null? lst) so-far)
          ((> (cdr (car lst)) so-far) (iter (cdr lst) (cdr (car lst))))
          ((< (cdr (car lst)) so-far) (iter (cdr lst) so-far))
          ((equal? (cdr (car lst)) so-far) (iter (cdr lst) (cdr (car lst))))))  
  (iter lst (cdr (car lst))))

(define (prices-until lst last-day total)
  (if (eq? (car(car  lst)) (+ last-day 1)) total
      (prices-until (cdr lst) last-day (+ (car(cdr(car lst))) total)))) 

;; integers generates a list of numbers from 0 to 100000
(define (numlist min max)
  (if ( > min max)
      '()
   (cons min (numlist (+ 1 min) max))))
(define integers (numlist 0 100000))

;;takes list of cons cells and returns a list of closing prices
(define (onlyclose closing-pairs)
  (if (null?  closing-pairs)
      '()
      (cons (cdr (car closing-pairs))
        (onlyclose (cdr closing-pairs)))))

;;takes list of cons cells and returns a list of daily volumes
(define (onlyvolume volume-pairs)
  (if (null?  volume-pairs)
      '()
      (cons (cdr (car volume-pairs))
            (onlyvolume (cdr volume-pairs)))))

;takes a list of pairs, and returns a list of pairs , replacing the cars of the pairs with an index starting at 0

(define (make-indexed nums pairs)
 (if  (or (null? pairs) (null?  nums))
     '()
  (cons  (cons (car nums) (cdr (car pairs)))
         (make-indexed (cdr nums) (cdr pairs)))))

(define my-in-port (current-input-port))
(define my-out-port (current-output-port))

;; stock input
(display "Enter stock ticker symbol \n")
(define ticker (read-line my-in-port))
(define myurl (string->url (string-append "http://ichart.finance.yahoo.com/table.csv?s="
                                          ticker
                                          "&d=4&e=1&f=2014&g=d&a=10&b=5&c=1963&ignore=.csv")))

(define myport (get-pure-port myurl))

;;CSV READER
(define my-csv-reader (make-csv-reader-maker '((strip-leading-whitespace . #t)
                                               (strip-trailing-whitespace . #t))))
;;unparsed string of data
(define unparsed-string (port->string myport))

;;keep calling next-row for next row 
(define next-row (my-csv-reader unparsed-string)) 

 ;;list of lists of data as strings
(define myrows (reverse(cdr(csv->list (my-csv-reader unparsed-string)))))


;;list of cons cells in each cons cell is date(string) and closing price
(define closing-pairs (reverse (cdr(csv-map (lambda(x) (cons (car x) (string->number (fifth x)))) unparsed-string))))


;; returns a list of cons cells,in each cons cell is a day index in the car and closing stock price for that day in the cdr
(define closing-indexed (make-indexed integers closing-pairs))

 ;;list of vectors, in each vector is a day index and closing price
(define vecti (map list->vector (map flatten closing-indexed) ))


;;closes = just list of prices
(define closes (onlyclose closing-pairs))

;;closing-lists = lsit of lists with  date(string) and price
(define closing-lists (map flatten closing-pairs))
(define closing-indexedf (map flatten closing-indexed))

;; list of daily volumes
(define (getvolumes lst nums )
  (if (null? lst) '()
      (cons  (cons (car nums) (string->number (sixth(car lst))))
             (getvolumes (cdr lst) (cdr nums)))))
(define volumes-indexed (getvolumes myrows integers))
(define volumes-indexedf (map flatten volumes-indexed))

;;takes a list of pairs and returns the dates
(define (date-strip lst)
  (if (null? lst)
      '()
      (cons (car (car lst))
            (date-strip (cdr lst)))))

;; returns a lsit of dates that their is data for
(define closing-dates (date-strip closing-pairs))
                  
;;EMA takes 1. A list of lists, in each list is an index in the car and price in the cdr
;;          2. previous ema, intitally is an SMA of the first n values, with n being the day range
;;          3. the day range for EMA calculation
;;          4. integer list for the index
;;and returns list of EMA values, the index of the first pair being n (day-range - 1)
(define (EMA lst prev-ema day-range nums)
  (let ((multiplier ( / 2 ( + day-range 1))))
    (if (null? lst)
        '()
        (cons (cons (car  nums)
                    (+ (* (- (car(cdr (car lst))) prev-ema) multiplier) prev-ema))
              (EMA (cdr lst)
                   (+ (* (- (car(cdr (car lst))) prev-ema) multiplier) prev-ema)
                   day-range        
                   (cdr nums ))))))
;;returns sum of first n prices, used for calculation of SMA
(define first5 (prices-until closing-indexedf 4 0))
(define first26 (prices-until closing-indexedf 25 0))
(define first12 (prices-until closing-indexedf 11 0))
(define first10 (prices-until closing-indexedf 9 0))
(define first50 (prices-until closing-indexedf 49 0))
(define first100 (prices-until closing-indexedf 99 0))
(define first150 (prices-until closing-indexedf 149 0))
(define first200 (prices-until closing-indexedf 199 0))

;; returns list of cons cells, each with day index and EMA value for that day
(define EMA5 (EMA closing-indexedf (/ first5 5) 5 (list-tail integers 4)))
(define EMA26 (EMA closing-indexedf (/ first26 26) 26 (list-tail integers 25)))
(define EMA12 (EMA closing-indexedf (/ first12 12) 12 (list-tail integers 11)))
(define EMA50 (EMA closing-indexedf (/ first50 50) 50 (list-tail integers 49)))
(define EMA100 (EMA closing-indexedf (/ first100 100) 100 (list-tail integers 99)))                     
(define EMA150 (EMA closing-indexedf (/ first150 150) 150  (list-tail integers 149)))
(define EMA200 (EMA closing-indexedf (/ first200 200) 200 (list-tail integers 199)))

(define (MACD-line-make EMA1 EMA2 nums)
  (if (or (null? EMA1) (null? EMA2)) '()
      (cons (cons (car nums) (- (cdr (car EMA1)) (cdr(car EMA2)) ) )
            (MACD-line-make (cdr EMA1) (cdr EMA2) (cdr nums)))))
;;MACD indexes start at 25
(define MACD-line (MACD-line-make (list-tail EMA12 14) EMA26 (list-tail integers 25)))  

(define signal-line (EMA (map flatten MACD-line) (/ (prices-until (map flatten MACD-line) 33 0) 9) 9 (list-tail integers 33)))
                   
(define (MACD-histogram-make macd-line signal-line nums)
  (if (or (null? macd-line) (null? signal-line)) '()
      (cons (cons (car nums) (- (cdr (car macd-line)) (cdr(car signal-line))))
            (MACD-histogram-make (cdr macd-line) (cdr signal-line) (cdr nums)))))

(define MACD-histogram (MACD-histogram-make (list-tail MACD-line 8) signal-line (list-tail integers 33)))
  

;; Price and MACD
(parameterize ([plot-x-tick-label-anchor 'top-right]
               [plot-x-tick-label-angle 70]
               [plot-title ticker]
               [plot-x-label "Day"]
               [plot-y-label "Price"])             
  (plot (list 
              (function (lambda(x) 0) 0 (last closing-indexedf))
              (lines-interval vecti (list #(0 0) (vector (last closing-indexedf) 0)) #:color '(30 144 255) 
                                                                                     #:label ticker 
                                                                                     #:y-max (+ 30 (list-max closes)) 
                                                                                     #:x-max  (last closing-indexed))
              (lines (map list->vector (map flatten MACD-line)) #:color '( 0 0 0)
                                                                #:label "MACD Line" 
                                                                #:y-min (-(list-min (onlyclose MACD-line  )) 5)    
                                                                #:y-max  (+ 5 (list-max (onlyclose MACD-line)))
                                                                #:x-max  (last closing-indexed))
              (lines (map list->vector (map flatten signal-line)) #:color '(50 205 50)
                                                                  #:label "Signal Line" 
                                                                  #:y-min (- (list-min (onlyclose signal-line)) 5  )
                                                                  #:x-max  (last closing-indexed))
              (lines (map list->vector (map flatten MACD-histogram)) #:label "MACD Histogram" 
                                                                     #:y-min (- (list-min (onlyclose MACD-histogram )) 5)
                                                                     #:x-max  (last closing-indexed)))))
;;Only MACD

(parameterize (
               [plot-title (string-append ticker " MACD")])
             (plot (list 
              (lines (map list->vector (map flatten MACD-line)) #:color '(138 43 226) 
                                                                #:label "MACD Line" 
                                                                #:y-min ( - (list-min (onlyclose MACD-line  )) 5) 
                                                                #:y-max  (+ 5 (list-max (onlyclose MACD-line))))
              (lines (map list->vector (map flatten signal-line)) #:color '(139 0 0) 
                                                                  #:label "Signal Line")
              (function (lambda(x) 0) 0 (last closing-indexedf))
              (discrete-histogram (map list->vector (map flatten MACD-histogram)) ;#:color '(34 139 34) 
                                                                                  #:label "MACD Histogram" 
                                                                                  #:y-min (- (list-min (onlyclose MACD-histogram )) 5)))))
;;Volume
(parameterize ([plot-x-tick-label-anchor 'top-right]
               [plot-x-tick-label-angle 70]
               [plot-x-label "Day"]
               [plot-y-label "Volume"]
               [plot-title (string-append ticker " Daily Volume")])
  (plot 
    (discrete-histogram volumes-indexedf #:y-max (+ 10000000 (list-max (onlyvolume volumes-indexed))))))

;;Moving Averages Graph
(parameterize ([plot-x-label "Day"]
               [plot-y-label "Price"]
               [plot-title (string-append ticker " Moving Averages")])
  (plot (list
         (lines-interval vecti (list #(0 0) (vector (last closing-indexedf) 0))#:color '(30 144 255) 
                                                                               #:label ticker 
                                                                               #:y-max (+ 30 (list-max closes)) 
                                                                               #:x-max  (last closing-indexed))
         (lines (map list->vector (map flatten EMA200))  #:color  '(0 0 0)
                                                         #:label (string-append ticker "200-day EMA ")
                                                         #:x-max  (last closing-indexed))
         (lines (map list->vector (map flatten EMA50 )) #:color '( 78 93 146) 
                                                        #:label (string-append ticker "50-day EMA")
                                                        #:x-max  (last closing-indexed))
         (lines (map list->vector (map flatten EMA100 )) #:color '( 255 50 100) 
                                                         #:label (string-append ticker "100-day EMA")
                                                         #:x-max  (last closing-indexed)))))
  

(define (highest14 pricelst)
  (max-list (take pricelst 14)))

(define (lowest14 pricelst)
  (min-list  (take pricelst 14)))
       
(define (stochastic pricelst nums)
  (if (null? (cddddr(cddddr(cddddr(cdr pricelst ))))) '()
      (cons (cons (car nums) (* (/(- (cdr(car pricelst)) (lowest14 pricelst)) (- (highest14 pricelst) (lowest14 pricelst))) 100))
          (stochastic (cdr pricelst) (cdr nums)))))

(define stlist (stochastic EMA5 (list-tail integers 4)))

;(define (SMA3 lst nums)
 ; (if (null? (cddddr lst)) '()
  ;    (cons (cons (car nums)
   ;               (/(+ (car (cdr (car lst))) 
    ;                 (car (cdr (car (cdr lst))))
     ;                (car (cdr (car (cdr (cdr lst))))))3))
      ;      (SMA3 (cdr lst)
       ;           (cdr nums)))))
 (define (SMA5 lst nums)
  (if (null? (cddddr lst)) '()
      (cons (cons (car nums)
                  (/(+ (car(cdr(list-ref lst 0))) 
                     (car (cdr (list-ref lst 1)))
                     (car (cdr (list-ref lst 2)))
                     (car (cdr (list-ref lst 3)))
                     (car (cdr (list-ref lst 4))))5))
            (SMA5 (cdr lst)
                  (cdr nums)))))                 
                     
(define SMA (SMA5 (map flatten stlist)(list-tail integers 4)))      

;;Slow Stochastic graph
(parameterize ([plot-title (string-append ticker " Slow Stochastic")] )     
(plot (list(lines (map list->vector (map flatten stlist)) #:label "%K Line" 
                                                          #:y-max 400 
                                                          #:y-min -20
                                                          #:x-max  (last closing-indexed)
                                                          #:color '(135 206 250))
           (lines (map list->vector (map flatten SMA)) #:color '(255 69 0) 
                                                       #:label "%D Line"
                                                       #:x-max  (last closing-indexed))
           (function (lambda (x) 80) #:label "80 = Overbought")
           (function (lambda (x) 20) #:label "20 = Oversold"))))
