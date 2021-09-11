#!/bin/perl

use strict;
use warnings;

########
#Parsing
#-------
#Instruction object :
#   op_code-> "BA"
#   label -> '' or 'coco'
#   var -> '' or "aba"
#   expr_type -> -1 (no expr), 0 (var), 1 (imm), 2 (expr PA), 3 (expr MA), 4 (expr FA)
#   expr1_var -> valid only if expr_type == 0, 2, 3, 4
#   expr1_imm -> valid only if expr_type == 1, 2, 3, 4 and expr1_var == ''
#   expr2_var -> valid only if expr_type == 2, 3, 4
#   expr2_imm -> valid only if expr_type == 2, 3, 4 and expr2_var == ''
#

#Function oject :
#   name-> "fubara"
#   insts-> [ {inst1}, {inst2} ]
#   lbls-> {name => idx, ... }

my $vowel = '[aeiou]';
my $conso = '[b-df-hj-np-tv-z]';
my $var_or_imm = '[-a-z0-9]+'; #Don't forget the '-' for negative immediates
my $expr = $var_or_imm . '(?:\s+(?:PA|MA|FA)\s+' . $var_or_imm . ')?';
my $line = 0;
my $test = 0;

sub test_print {
    if ($test) {
        print $_[1];
    } else {
        print $_[0];
    }
}
#Quick helpers
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
    if ($l =~ m/^(papa|mama)$/) {
        return 0;
    }
    return ($l =~ m/^($conso$vowel)+$/);
}

#Remove indentations and comments
sub trim {
    my $s = shift;
    $s =~ s/#.*//;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

#Automatically add line information when encountering parsing error
sub parse_error
{
    my $e = shift;
    die(">Parser error @ line $line : $e\n");
}

#Parse sub-elements
sub parse_func {
    my $f = shift;
    if ($f =~ m/^FA\s+((?:$conso$vowel)+)\s*:$/) {
        return $1;
    } else {
        return "";
    }
}

sub parse_expr {
    my $r = shift;
    my $inst = shift;
    my $res = 0;
    
    $inst->{expr_type} = -1;

    if (is_var($r)) {
       $inst->{expr_type} = 0;
       $inst->{expr1_var} = $r;
    } elsif (is_imm($r)) {
       $inst->{expr_type} = 1;
       $inst->{expr1_imm} = int($r);
    } elsif ($r =~ m/^($var_or_imm)\s+(PA|MA|FA)\s+($var_or_imm)$/) {
        my $v1 = $1;
        my $v2 = $3;
        if (is_var_or_imm($v1) && is_var_or_imm($v2)) {
            if ($2 =~ m/PA/) {
                $inst->{expr_type} = 2;
            } elsif ($2 =~ m/MA/) {
                $inst->{expr_type} = 3;
            } elsif ($2 =~ m/FA/) {
                $inst->{expr_type} = 4;
            }
            if (is_var($v1)) {
                $inst->{expr1_var} = $v1;
            } else {
                $inst->{expr1_imm} = int($v1);
            }
            if (is_var($v2)) {
                $inst->{expr2_var} = $v2;
            } else {
                $inst->{expr2_imm} = int($v2);
            }
        } else {
            $res = -1;
        }
    } else {
        $res = -1;
    }
    return $res;
}

sub parse_stack
{
    my $s = shift;
    my $i = shift;
    if (defined($s)) {
        if ($s =~ "(papa|mama)") {
            return $s;
        } else {
            parse_error("Unknown stack descriptor $s for instruction <$i>");
        }
    } else {
        return "default";
    }
}

sub parse_inst
{
    my $i = shift;
    my $inst = {};
    # BA
    if ($i =~ m/^BA\s+(\w+)\s*($expr)/) {
        if (!is_var($1)) {
            parse_error("Expected variable as 1st argument of BA instruction <$i>");
        }
        if (parse_expr($2, $inst) < 0) {
            parse_error("Expected expr as 2nd argument of BA instruction <$i>");
        }
        $inst->{op_code} = "BA";
        $inst->{var} = $1;
    } elsif ($i =~ m/^TA\s+($expr)\s*(?:>(\w+))?/) {
        if (parse_expr($1, $inst) < 0) {
            parse_error("Expected expr as 1st argument of TA instruction <$i>");
        }
        $inst->{stack} = parse_stack($2, $i);
        $inst->{op_code} = "TA";
    } elsif ($i =~ m/^DA\s+(\w+)\s*(?:<(\w+))?/) {
        if (!is_var($1)) {
            parse_error("Expected variable as 1st argument of DA instruction <$i>");
        }
        $inst->{stack} = parse_stack($2, $i);
        $inst->{op_code} = "DA";
        $inst->{var} = $1;
    } elsif ($i =~ m/^(HOPLA|HOPLAFA)\s+(\w+)/) {
        if (!is_label($2)) {
            parse_error("Expected label as 1st argument of $1 instruction <$i>");
        }
        $inst->{op_code} = $1;
        $inst->{label} = $2;
    } elsif ($i =~ m/^(HOPLAZA|HOPLAGA)\s+(\w+)\s+($expr)/) {
        if (!is_label($2)) {
            parse_error("Expected label as 1st argument of $1 instruction <$i>");
        }
        if (parse_expr($3, $inst) < 0) {
            parse_error("Expected exprue as 2nd argument of $1 instruction <$i>");
        }
        $inst->{op_code} = $1;
        $inst->{label} = $2;
    } elsif ($i =~ m/^ORWAR$/) {
        $inst->{op_code} = "ORWAR";
    } elsif ($i =~ m/^((?:$conso$vowel)+)\s*:$/) {
        $inst->{name} = $1;
    } else {
        parse_error("Unrecognized instruction <$i>");
    }
    return $inst;
}

#Main parsing
if ($ARGV[0] eq "-t") {
    $test = 1;
    shift @ARGV;
}
my @functions = ();
my $f = {insts => [], lbls => {}};
my $filename = shift @ARGV;

open(FILE, "<", $filename)
    or die($!);

while (<FILE>) {
    $line += 1;
    my $l = trim($_);
    if ($l eq "") {
        next;
    }
    #Function context
    if (exists($f->{name})) {
        my $inst = parse_inst($l);
        #Label
        if (exists($inst->{name})) {
            my $lbl = $inst->{name};
            my $inst_idx = scalar @{$f->{insts}};    #Current number of instructions
            $f->{lbls}->{$lbl} = $inst_idx;
        }
        #Regular instruction
        else {
            push(@{$f->{insts}}, $inst);
            #End of function, append to functions array
            if ($inst->{op_code} eq "ORWAR") {
                push (@functions, $f);
                $f = {insts => [], lbls => {}};
            }
        }
    }
    #No context - expect function declaration
    else {
        $f->{name} = parse_func($l);
        if ($f->{name} eq "") {
            parse_error("Expected function definition\n");
        }
    }
}

test_print(">Parsing $filename successful: $line lines\n", "");
test_print(">Functions:\n", "");
foreach (@functions) {
    my %f = %{$_};
    my $n_inst = @{$f{insts}};
    my $n_lbls = keys %{$f{lbls}};
    test_print("\t-$f{name} with $n_inst instructions and $n_lbls labels\n", "");
#Debug
#    foreach (@{$f{insts}}) {
#        my %inst = %{$_};
#        print map { "$_ => $inst{$_}, " } keys %inst;
#        print "\n";
#    }
}

##########
#Execution
#---------
#
#Frame object :
#   func-> \ref to function object
#   pc-> 0 - index of instruction inside current function
#   vars-> {"aka" => 12, ...}
#
#Execution object (implicit):
#   cur_frame -> index of current frame
#   frames -> [ {frame1}, {frame2} ]
#   stack = [12, 42, ...] - current stack for TA/DA functions
#   papa_stack = []
#   mama_stack = []

#Globals
my @frames = ();
my $frame = {func => undef, pc => 0, vars => {}};
my @stack = ();
my @papa_stack = ();
my @mama_stack = ();
my %stack_ref = (default => \@stack, papa => \@papa_stack, mama => \@mama_stack);
my $n_insts = 0;
my $MAX_FRAMES = 64;



sub get_func_by_name {
    my $name = shift;
    foreach (@functions) {
        if ($_->{name} eq $name) {
            return $_;
        }
    }
    return undef;
}

sub exec_error {
    my $e = shift; 
    print STDERR ">Execution error\n";
    print STDERR ">Callstack:\n";
    foreach (@frames) {
        print STDERR ">\t$_->{func}->{name} at $_->{pc}:\n";
    }
    die(">$e\n");
}

sub eval_var {
    my $v = shift;
    my $vars = $frame->{vars};
    if (exists($vars->{$v})) {
        return $vars->{$v};
    } else {
        exec_error("Variable $v unassigned in current context");
    }
}

sub eval_expr {
    my $inst = shift;
    my $t = $inst->{expr_type};

    if ($t == 0) {
        return eval_var($inst->{expr1_var});
    } elsif ($t == 1) {
        return $inst->{expr1_imm};
    } else {
        my $v1;
        my $v2;
        if (exists($inst->{expr1_var})) {
            $v1 = eval_var($inst->{expr1_var});
        } else {
            $v1 = $inst->{expr1_imm};
        }
        if (exists($inst->{expr2_var})) {
            $v2 = eval_var($inst->{expr2_var});
        } else {
            $v2 = $inst->{expr2_imm};
        }
        if ($t == 2) {
            return $v1 + $v2;
        } elsif ($t == 3) {
            return $v1 - $v2;
        } else {
            return $v1 * $v2;
        }
    }
}

sub exec_inst {
    my $inst = shift;
    my $op = $inst->{op_code};
    my $expr = 0;
    my $vars = $frame->{vars};
    my $func = $frame->{func};
    my $jump = 0;
    my $call = 0;
    my $ret = 0;
    my $end = 0;
    
    if (exists($inst->{expr_type}) && $inst->{expr_type} >= 0) {
        $expr = eval_expr($inst);
    }

    if ($op eq "BA") {
        $vars->{$inst->{var}} = $expr;
    } elsif ($op eq "TA") {
        my $st = $stack_ref{$inst->{stack}};
        push(@$st, $expr);
    } elsif ($op eq "DA") {
        my $st = $stack_ref{$inst->{stack}};
        if (scalar @$st == 0) {
            exec_error("Trying to pop an empty stack ($inst->{stack})");
        }
        $vars->{$inst->{var}} = pop(@$st);
    } elsif ($op eq "HOPLA") {
        $jump = 1;
    } elsif ($op eq "HOPLAZA") {
        $jump = ($expr == 0);
    } elsif ($op eq "HOPLAGA") {
        $jump = ($expr > 0);
    } elsif ($op eq "HOPLAFA") {
        $call = 1;
    } elsif ($op eq "ORWAR") {
        $ret = 1;
    }
    #Default PC increment
    $frame->{pc} += 1;

    if ($jump) {
        my $lbl = $inst->{label};
        my $lbls = $func->{lbls};
        if (!exists($lbls->{$lbl})) {
            exec_error("Label $lbl not defined in current context");
        } else {
            $frame->{pc} = $lbls->{$lbl};
        }
    }
    if ($call) {
        my $fname = $inst->{label};
        #Handle builtin print subroutine
        if ($fname eq "sekasa") {
            while (@stack) {
                my $v = pop(@stack);
                print "|> $v\n";
            }
            return 0;
        }
        $func = get_func_by_name($fname);
        if (!$func) {
            exec_error("Function $fname not defined");
        } else {
            if (scalar @frames > $MAX_FRAMES) {
                exec_error("Too many nested function calls");
            }
            #Push new frame
            $frame = {func => $func, pc => 0, vars => {}};
            push(@frames, $frame);
        }
    }
    if ($ret) {
        #Pop frame
        pop(@frames);
        if (scalar @frames == 0) {
            $end = 1;
        } else {
            $frame = $frames[$#frames];
        }
    }
    return $end;
}

# Main execution
$f = get_func_by_name("debu");
if (!$f) {
    exec_error("Function debu not found");
}
$frame->{func} = $f;
push(@frames, $frame);


push(@stack, @ARGV);

test_print(">Start execution\n\n", "");
while (1) {
    my $func = $frame->{func};
    my $pc = $frame->{pc};
    my $insts = $func->{insts};
    if ($pc > $#$insts) {
        exec_error("PC overflow ... missing ORWAR instruction ?");
    }
    $n_insts += 1;
    if (exec_inst($insts->[$pc])) {
        last;
    }
}
test_print("\n>End execution after $n_insts instruction\n", "$n_insts: ");
test_print(">Return stack is :\n", "");
foreach (@stack) {
    test_print (">\t$_\n", "$_ ");
}
test_print("\n", "\n");
