aDELe language
==============

This small programming language has been inspired
by the first 'words' of my daughter Adèle.


It is some sort of of assembly language without notion of memory.
Everyone can try and play with the language.

Variables
-------
A variable is like a toy cube containing an integer value.
aDELe uses them to perform operations, tests and stack or un stack them.

It can be any name of the form : voyel + (consonant + voyel)*

Lowercase only.

Example valid : ababa, oko, ebedele, abudabi

Example invalid: baba, COCO

Expression
-----
An expression is the way to perform operations on variables.

It can be :

- A decimal integer: 0, -523, 12
- A simple variable: aba
- A simple operation on variables or decimal integer : `ababa PA 1`, `oko MA aka`

Operands
------
- `PA` : addition - "plus"
- `MA` : substraction - "moins"
- `FA` : multiplication - "fois"

Assignment
----------
- `BA [var] [expr]` : assigns expression to variable - "bien"

Stack
------------
- `TA [expr] (>papa/mama)`: gives expression as function argument (push on stack) or for function return - "tiens"
- `DA [var] (<papa/mama)` : pop from stack and retrieve value and store it in variable - "donne"

Data is stored in stacks, and Adele likes to stack and unstack her little cubes.

She also likes to give them to an adult and she always expect to retrieve them in 'last in', 'first out' order.
Example :

    TA 10 >mama
    TA 20 >papa
    TA 30 >mama
    DA aba <mama   #aba will hold the value 30
    DA aca <papa   #aca will hold 20
    DA ada <mama   #ada will hold 10
    DA eroro <papa #will produce an error since there is
                    no more elements in papa stack


TA and DA command can operate on 3 stacks
- The default 'unnamed' stack is used to pass function arguments and retrive return values.
- Two 'data' stacks called 'papa' and 'mama' that exists globally, specified at the end of the instruction, preceded by > for TA and < for DA

For the debu function, DA allows to retrieve command line arguments.

Jumps / functions
-----------------
- `HOPLA [label]`: Unconditional jump to label "hop là !"
- `HOPLAZA [label] [expr]` : Jumps to label if expr evals to 0, else continue to next instruction
- `HOPLAGA [label] [expr]` : Jumps to label if expr evals to >0, else continue to next instruction

- `HOPLAFA [label]` : Call to function described by label
- `ORWAR` : Returns from fonction. It shall be the last instruction of any function - "au revoir"

Labels
------
Followed by `:`

Anyname of the form (consonant+voyel)+ and different from 'papa' and 'mama'
Voyel can be different, lowercase only.

Example valid: babi, coco.

For functions declaration, it is preceded by the keyword `FA`

Special function
---------------
- `sekasa` : print to terminal - "c'est quoi ça"
- `debu`: First function called (main) - "début"

Comments
-------
Begins with `#`

Full examples
-----------
These examples files are available in the `examples` directory of this repo.

### Fibonnaci :

    FA debu:
      DA ana  #counter of iteration from command line
      BA unu 1    #u_n
      BA unumu 1  #u_n-1
      fibo:
        BA ubufu unu PA unumu # u_n+1 <- un + un-1
        BA unumu unu
        BA unu ubufu
        BA ana ana MA 1       #counter decrement
        HOPLAGA fibo ana      #loop
      TA unu
      HOPLAFA sekasa            #print result
      ORWAR

### Factorial :

    FA facoto:
      DA ana              # counter
      HOPLAZA fini ana    # Will return if zero
      TA ana MA 1
      HOPLAFA facoto      # Recursive call with ana-1
      DA afa              # afa = facoto(ana-1)
      TA ana MA afa       # returns ana * afa
      HOPLA reta
    fini:
      TA 1		  # Return value of factorial(0)
    reta
      ORWAR

    FA debu:
      HOPLAFA facoto  # Command line argument is directly facoto argument
      HOPLAFA sekasa  # facoto returns is directly argument to print
      ORWAR

Launch an aDELe program
============

`./adele.pl [program_file] [arguments]`

or

`perl adele.pl [program_file] [arguments]`

Perl is readily available on most standard Linux distributions.

Here is an example to compute the factorial of 10:

    [adele@amc]$./adele.pl examples/facto.adl 10
    >Parsing examples/facto.adl successful: 21 lines
    >Functions:
	-facoto with 9 instructions and 2 labels
	-debu with 4 instructions and 0 labels
    >Start execution

    |> 3628800

    >End execution after 88 instruction

If you don't have a Linux distribution available, you can use Fabrice Bellard's VM running in your browser :

https://bellard.org/jslinux/vm.html?url=alpine-x86.cfg&mem=192

Challenge
=========

### Euclidean division

Write a program performing the euclidean division of two integers, giving the quotient and remainder as stack returns
    
    [adele@amc]$./adele.pl challenge/div.adl 24062020 1987
    >Parsing challenge/div.adl successful: 67 lines
    [...]
    >Start execution

    >End execution after 208 instruction
    >Return stack is :
    >	12109
    >	1437

Here we have 1987 * 12109 + 1437 = 24062020

If you want to carry on the challenge, it is important for the function to be efficient (in terms of instructions executed) when dividing big numbers by small numbers.

### Primality

Write a program performing the primality check on an integer

### Delicate primes

Write a program finding the nth [delicate prime](https://en.wikipedia.org/wiki/Delicate_prime) in base 10, when n is passed as function argument.

It is authorized to use the fact that the first delicate prime is 294001.
It is not auhtorized to hardcode any other delicate prime.
The program must be able to give at least all the delicate primes with 9 digits or less.
