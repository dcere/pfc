import sys
import math

print "Prime numbers"

#Asks user how many numbers he wants to calculate.
a = int(raw_input("Start?: "))
b = int(raw_input("End?: "))

if (a < 0) :
   print "Error: Invalid number. It must be greater than zero"
   sys.exit

if (a < 2) : # Discard 0 and 1 as primes
   a = 2     # Primes(0,10) == Primes(2,10)

count = 0 # number of already calculated primes.

for i in range(a,b) :
   
   for j in range(2,i) :
      if i % j ==0 :
         break
   else : # for's else; not if's else
      print i
      count += 1

print "Total: ", count
