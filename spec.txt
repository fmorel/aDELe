aDELe language
--------------

Variables
-------
Any name of the form : voyel + (consonant + voyel)*
Lowercase only.
Example valid : ababa, oko, ebedele, abudabi
Example invalid: baba, COCO

Rvalue
-----
- A decimal integer: 0, -523, 12
- A simple variable: aba
A simple operation on variables or decimal integer : ababa PA 1, oko MA aka

Operands
-------
PA : addition - "plus"
MA : substraction - "moins"
FA : multiplication - "fois"

Assignment
----------
BA [var] [rval] : assigns rvalue to variable - "bien"

Stack
------------
Data is stored in stacks, like a cube of toys in which you can store object, or and adult to which you can give them 
and retrieve them in 'last in', 'first out' order.
TA and DA command can operate on 3 stacks
- The default 'unnamed' stack is used to pass function arguments and retrive return values.
- Two 'data' stacks called 'papa' and 'mama' that exists globally, specified at the end of the instruction, preceded by > for TA and < for DA
TA [rval] (>papa/mama): gives rvalue as function argument (push on stack) or for function return - "tiens"
DA [var] (<papa/mama) : pop from stack and retrieve value (in reverse order) and store it in variable - "donne"
For the debu function, DA allows to retrieve command line arguments.

Jumps / functions
-----------------
HOPLA [label]: Unconditional jump to label "hop là !"
HOPLAZA [label] [rval] : Jumps to label if rvalue evals to 0, else continue to next instruction
HOPLAGA [label] [rval] : Jumps to label if rvalue evals to >0, else continue to next instruction

HOPLAFA [label] : Call to function described by label
ORWAR: Returns from fonction. It shall be the last instruction of any function - "au revoir"

Loop
----
ACOR [label] [var] :=
    BA [var] [var] MA 1
    HOPLAGA [label] [var]


Labels
------
Followed by ':'
Anyname of the form (consonant+voyel)+ and different from 'papa' and 'mama'
Voyel can be different, lowercase only.
Example valid: babi, coco.
For functions declaration, it is preceded by 'FA'

Special function
---------------
sekasa : print to terminal - "c'est quoi ça"
debu: First function called (main), should return 0 - "début"

Comments
-------
Begins with #


Full examples
-----------

Fibonnaci :
----------

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

Factorial:
---------

FA facoto:
    DA ana              # counter
    HOPLAZA fini ana    # Will return if zero
    TA ana MA 1
    HOPLAFA facoto      # Recursive call with ana-1
    DA afa              # afa = facoto(ana-1)
    TA ana MA afa       # returns ana * afa
    ORWAR
fini:
    TA 1
    ORWAR

FA debu:
    HOPLAFA facoto  # Command line argument is directly facoto argument
    HOPLAFA sekasa  # facoto returns is directly argument to print
    TA 0
    ORWAR
