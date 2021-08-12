aDELe language
==============

Variables
-------
Any name of the form : voyel + (consonant + voyel)*

Lowercase only.

Example valid : ababa, oko, ebedele, abudabi

Example invalid: baba, COCO

Expression
-----
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

She also like to give them to an adult and she always expect to retrieve them in 'last in', 'first out' order.

TA and DA command can operate on 3 stacks
- The default 'unnamed' stack is used to pass function arguments and retrive return values.
- Two 'data' stacks called 'papa' and 'mama' that exists globally, specified at the end of the instruction, preceded by > for TA and < for DA

For the debu function, DA allows to retrieve command line arguments.

Jumps / functions
-----------------
- `HOPLA [label]`: Unconditional jump to label "hop là !"
- `HOPLAZA [label] [rval]` : Jumps to label if rvalue evals to 0, else continue to next instruction
- `HOPLAGA [label] [rval]` : Jumps to label if rvalue evals to >0, else continue to next instruction

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
- `debu`: First function called (main), should return 0 - "début"

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
      TA 0
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
      TA 0
      ORWAR

Launch an aDELe program
============

`./adele.pl [program_file] [arguments]`
or
`perl adele.pl [program_file] [arguments]`

Here is an example to compute the factorial of 10:

    [adele@amc]$./adele.pl examples/facto.adl 10
    >Parsing examples/facto.adl successful: 21 lines
    >Functions:
	-facoto with 9 instructions and 2 labels
	-debu with 4 instructions and 0 labels
    >Start execution

    |> 3628800

    >End execution after 88 instruction
    >Return stack is :
    >	0

If you don't have a Linux distribution available, you can use Fabrice Bellard's VM running in your browser :

https://bellard.org/jslinux/vm.html?url=alpine-x86.cfg&mem=192

