#!/bin/perl

use strict;
use warnings;

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
#   lbls-> {name => idx, ... }

my $vowel = '[aeiou]';
my $conso = '[b-df-hj-np-tv-z]';
my $rval = '\w.*';

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

my $line = 0;
sub parse_error
{
    my $e = shift;
    die(">Parser error @ line $line : $e\n");
}

sub parse_inst
{
    my $i = shift;
    my %inst = ();
    my $rinst = \%inst;
    # BA
    if ($i =~ m/BA\s+(\w+)\s*($rval)$/) {
        if (!is_var($1)) {
            parse_error("Expected variable as 1st argument of BA instruction <$i>");
        }
        if (parse_rval($2, $rinst) < 0) {
            parse_error("Expected rvalue as 2nd argument of BA instruction <$i>");
        }
        $rinst->{op_code} = "BA";
        $rinst->{var} = $1;
    } elsif ($i =~ m/TA\s+($rval)\s*(?:>(\w+))?$/) {
        if (parse_rval($1, $rinst) < 0) {
            parse_error("Expected rvalue as 1st argument of TA instruction <$i>");
        }
        $rinst->{stack} = parse_stack($2, $i);
        $rinst->{op_code} = "TA";
    } elsif ($i =~ m/DA\s+(\w+)\s*(?:<(\w+))?$/) {
        if (!is_var($1)) {
            parse_error("Expected variable as 1st argument of DA instruction <$i>");
        }
        $rinst->{stack} = parse_stack($2, $i);
        $rinst->{op_code} = "DA";
        $rinst->{var} = $1;
    } elsif ($i =~ m/(HOPLA|HOPLAFA)\s+(\w+)$/) {
        if (!is_label($2)) {
            parse_error("Expected label as 1st argument of $1 instruction <$i>");
        }
        $rinst->{op_code} = $1;
        $rinst->{label} = $2;
    } elsif ($i =~ m/(HOPLAZA|HOPLAGA)\s+(\w+)\s+($rval)$/) {
        if (!is_label($2)) {
            parse_error("Expected label as 1st argument of $1 instruction <$i>");
        }
        if (parse_rval($3, $rinst) < 0) {
            parse_error("Expected rvalue as 2nd argument of $1 instruction <$i>");
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

###########
#Parse file
#
my @functions = ();
my $f = {insts => [], lbls => {}};

open(FILE, "<", shift @ARGV)
    or die($!);

while (<FILE>) {
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
            my $lbl = $rinst->{name};
            my $inst_idx = scalar @{$f->{insts}};    #Current number of instructions
            $f->{lbls}->{$lbl} = $inst_idx;
        }
        #Regular instruction
        else {
            push(@{$f->{insts}}, $rinst);
            #End of function, append to functions array
            if ($rinst->{op_code} eq "ORWAR") {
                push (@functions, $f);
                $f = {insts => [], lbls => {}};
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

print ">Parsing $ARGV[0] successful: $line lines\n";
print ">Functions:\n";
foreach (@functions) {
    my %f = %{$_};
    my $n_inst = @{$f{insts}};
    my $n_lbls = keys %{$f{lbls}};
    print "\t-$f{name} with $n_inst instructions and $n_lbls labels\n";
}


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

sub eval_rval {
    my $inst = shift;
    my $t = $inst->{rval_type};

    if ($t == 0) {
        return eval_var($inst->{rval1_var});
    } elsif ($t == 1) {
        return $inst->{rval1_imm};
    } else {
        my $v1;
        my $v2;
        if (exists($inst->{rval1_var})) {
            $v1 = eval_var($inst->{rval1_var});
        } else {
            $v1 = $inst->{rval1_imm};
        }
        if (exists($inst->{rval2_var})) {
            $v2 = eval_var($inst->{rval2_var});
        } else {
            $v2 = $inst->{rval2_imm};
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
    my $rval = 0;
    my $vars = $frame->{vars};
    my $func = $frame->{func};
    my $jump = 0;
    my $call = 0;
    my $ret = 0;
    my $end = 0;
    
    if (exists($inst->{rval_type}) && $inst->{rval_type} >= 0) {
        $rval = eval_rval($inst);
    }

    if ($op eq "BA") {
        $vars->{$inst->{var}} = $rval;
    } elsif ($op eq "TA") {
        my $st = $stack_ref{$inst->{stack}};
        push(@$st, $rval);
    } elsif ($op eq "DA") {
        my $st = $stack_ref{$inst->{stack}};
        if (scalar @$st == 0) {
            exec_error("Trying to pop an empty stack $inst->{stack}");
        }
        $vars->{$inst->{var}} = pop(@$st);
    } elsif ($op eq "HOPLA") {
        $jump = 1;
    } elsif ($op eq "HOPLAZA") {
        $jump = ($rval == 0);
    } elsif ($op eq "HOPLAGA") {
        $jump = ($rval > 0);
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

# Main start
$f = get_func_by_name("debu");
if (!$f) {
    exec_error("Function debu not found");
}
$frame->{func} = $f;
push(@frames, $frame);
push(@stack, @ARGV);

print ">Start execution\n";
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
print ">End execution after $n_insts instruction\n";
print ">Return stack is :\n";
foreach (@stack) {
    print ">\t$_\n";
}
