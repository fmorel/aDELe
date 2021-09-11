#!/bin/bash

ADL_PATH=challenge/$1;

echo "Division"
./adele.pl -t $ADL_PATH/div.adl 24062020 1987
./adele.pl -t $ADL_PATH/div.adl 24062020 34

echo "Primality"
./adele.pl -t $ADL_PATH/prime.adl 24062020 #not prime
./adele.pl -t $ADL_PATH/prime.adl 24062021 #not prime
./adele.pl -t $ADL_PATH/prime.adl 24062023 #prime
./adele.pl -t $ADL_PATH/prime.adl 24062025 #not prime
./adele.pl -t $ADL_PATH/prime.adl 24062027 #not prime
./adele.pl -t $ADL_PATH/prime.adl 86436588001 #Not prime



