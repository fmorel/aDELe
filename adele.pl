#!/bin/perl

use strict;
use warnings;

my %data;
my $vowel = '[aeiou]';
my $conso = '[b-df-hj-np-tv-z]';
my $rval = '\w.*';

#Parsing
#-------
#Instruction object :
#   op_code-> "BA"
#   label -> '' or 'coco'
#   var -> '' or "aba"
#   rval_type -> -1 (no rval), 0 (var), 1 (imm), 2 (rval PA), 3 (rval MA), 4 (rval FA)
#   rval1_var -> valid only if rval_type == 0, 2, 3, 4
#   rval1_imm -> valid only if rval_type == 1, 2, 3, 4 and rval1_var == ''
#   rval2_var -> valid only if rval_type == 2, 3, 4
#   rval2_imm -> valid only if rval_type == 2, 3, 4 and rval2_var == ''
#
#Label object :
#   name-> "coco"
#   inst_idx-> 12 - index of instruction inside the inst array of the function

#Function oject :
#   name-> "fubara"
#   insts-> [ {inst1}, {inst2} ]
#   lbls-> [ {lbl1}, {lbl2} ]

my @functions = ();
my $line = 0;

#Execution
#---------
#
#Frame object :
#   func-> \ref to function object
#   pc-> 0 - index of instruction inside current function
#   vars-> {"aka" => 12, ...}
#
#Execution object :
#   cur_frame -> index of current frame
#   frames -> [ {frame1}, {frame2} ]
#   stack = [12, 42, ...] - current stack for TA/DA functions
#

my %execution = ();

sub is_var {
    my $v = shift;
    return ($v =~ m/^$vowel($conso$vowel)*$/);
}
sub is_imm {
    my $i = shift;
    return ($i =~ m/^-?\d+$/);
}
sub is_var_or_imm {
    my $vi = shift;
    return is_var($vi) || is_imm($vi);
}
sub is_label {
    my $l = shift;
    return ($l =~ m/^($conso$vowel)+$/);
}

#Remove indentations and comments
sub trim {
    my $s = shift;
    $s =~ s/#.*//;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub parse_func {
    my $f = shift;
    if ($f =~ m/^FA\s+((?:$conso$vowel)+)\s*:$/) {
        return $1;
    } else {
        return "";
    }
}

sub parse_rval {
    my $r = shift;
    my $res = 0;
    my %inst = (rval_type => -1);
    if (is_var($r)) {
       $inst{rval_type} = 0;
       $inst{rval1_var} = $r;
    } elsif (is_imm($r)) {
       $inst{rval_type} = 1;
       $inst{rval1_imm} = int($r);
    } elsif ($r =~ m/^(\w+)\s+(PA|MA|FA)\s+(\w+)$/) {
        my $v1 = $1;
        my $v2 = $3;
        if (is_var_or_imm($v1) && is_var_or_imm($v2)) {
            if ($2 =~ m/PA/) {
                $inst{rval_type} = 2;
            } elsif ($2 =~ m/MA/) {
                $inst{rval_type} = 3;
            } elsif ($2 =~ m/FA/) {
                $inst{rval_type} = 4;
            }
            if (is_var($v1)) {
                $inst{rval1_var} = $v1;
            } else {
                $inst{rval1_imm} = int($v1);
            }
            if (is_var($v2)) {
                $inst{rval2_var} = $v2;
            } else {
                $inst{rval2_imm} = int($v2);
            }
        } else {
            $res = -1;
        }
    } else {
        $res = -1;
    }
    my $rinst = shift;
    %$rinst = %inst;
    return \%inst;
}    

sub parse_error
{
    my $e = shift;
    die(">Parser error @ $line : $e");
}

sub parse_inst
{
    my $i = shift;
    my %inst = ();
    my $rinst = \%inst;
    # BA
    if ($i =~ m/BA\s+(\w+)\s*($rval)$/) {
        if (!is_var($1)) {
            parse_error("Expected variable as 1st argument of BA instruction");
        }
        if (parse_rval($2, $rinst) < 0) {
            parse_error("Expected rvalue as 2nd argument of BA instruction");
        }
        $rinst->{op_code} = "BA";
        $rinst->{var} = $1;
    } elsif ($i =~ m/TA\s+($rval)$/) {
        if (parse_rval($1, $rinst) < 0) {
            parse_error("Expected rvalue as 1st argument of TA instruction");
        }
        $rinst->{op_code} = "TA";
    } elsif ($i =~ m/DA\s+(\w+)$/) {
        if (!is_var($1)) {
            parse_error("Expected variable as 1st argument of DA instruction");
        }
        $rinst->{op_code} = "DA";
        $rinst->{var} = $1;
    } elsif ($i =~ m/(HOPLA|HOPLAFA)\s+(\w+)$/) {
        if (!is_label($2)) {
            parse_error("Expected label as 1st argument of $1 instruction");
        }
        $rinst->{op_code} = $1;
        $rinst->{label} = $2;
    } elsif ($i =~ m/(HOPLAZA|HOPLAGA)\s+(\w+)\s+($rval)$/) {
        if (!is_label($2)) {
            parse_error("Expected label as 1st argument of $1 instruction");
        }
        if (parse_rval($3, $rinst) < 0) {
            parse_error("Expected rvalue as 2nd argument of $1 instruction");
        }
        $rinst->{op_code} = $1;
        $rinst->{label} = $2;
    } elsif ($i =~ m/ORWAR$/) {
        $rinst->{op_code} = "ORWAR";
    } elsif ($i =~ m/((?:$conso$vowel)+)\s*:$/) {
        $rinst->{name} = $1;
    } else {
        parse_error("Unrecognized instruction <$i>");
    }
    return $rinst;
}

#Parse file

my $f = {insts => [], lbls => []};
print ">Parsing $ARGV[0] ...\n";
while (<>) {
    $line += 1;
    my $l = trim($_);
    if ($l eq "") {
        next;
    }
    #Function context
    if (exists($f->{name})) {
        my $rinst = parse_inst($l);
        #Label
        if (exists($rinst->{name})) {
            $rinst->{inst_idx} = @{$f->{insts}};    #Current number of instructions
            push(@{$f->{lbls}}, $rinst);
        }
        #Regular instruction
        else {
            push(@{$f->{insts}}, $rinst);
            #End of function, append to functions array
            if ($rinst->{op_code} eq "ORWAR") {
                push (@functions, $f);
                $f = {insts => [], lbls => []};
            }
        }
    }
    #No context
    else {
        $f->{name} = parse_func($l);
        if ($f->{name} eq "") {
            parse_error("Expected function definition\n");
        }
    }
}

print ">Parsing successful: $line lines\n";
print ">Functions:\n";
foreach (@functions) {
    my %f = %{$_};
    my $n_inst = @{$f{insts}};
    my $n_lbls = @{$f{lbls}};
    print "\t$f{name} has $n_inst instructions and $n_lbls labels\n";
}

    



