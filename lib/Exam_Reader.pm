package Exam_Reader;

use v5.36;
use warnings;
use strict;
use Exporter 'import';
use lib './lib';

use Regex ':regex';

sub new ($class,$filename) {
    my $self = {
        class         => $class,
        layouts       => [],
        questions     => [],
        marked_answer => {},
        answers       => {},
    };
    
    my $reader = bless ($self, $class);
    load_file($reader,$filename);
    return $reader;
}

sub load_file ($self,$filename) {
    open (my $fh_in, '<', $filename) or die ("Could not open file: $filename");
    
    while (my $line = readline($fh_in)) {
        
        if ($line =~ $Regex::STARTLINE_DETECT_REGEX) {
            my ($layout,$question,$position);
            
            while ($line !~ $Regex::QUESTION_START_DETECT_REGEX) {
                $layout .= $line;
                $line = readline ($fh_in);
            }
            $layout .= "Q";

            while ($line !~ $Regex::QUESTION_END_DETECT_REGEX) {
                $question .= $line;
                $line = readline ($fh_in);
            }

            while ($line !~ $Regex::ANSWER_START_DETECT_REGEX) {
                $layout .= $line;
                $line = readline ($fh_in);
            }
            $layout .= "A";
            
            while ($line !~ $Regex::ANSWER_END_DETECT_REGEX) {
                my $press_question = get_pressed($question);
                
                if ($line =~ $Regex::ANSWER_PATTERN_REGEX){
                    push (@{$self->{marked_answer}{$press_question}}, $line);
                    $line =~ s{$Regex::ANSWER_PATTERN_REGEX}{[ ]$1};
                }

                push (@{$self->{answers}{$press_question}}, $line);
                $line = readline ($fh_in);
            }
            
            while ($line !~ qr{$Regex::STARTLINE_DETECT_REGEX|$Regex::ENDLINE_DETECT_REGEX}) {
                $layout .= $line;
                $position = tell($fh_in);
                $line = readline ($fh_in);
            }
            seek ($fh_in,$position,0);

            push (@{$self->{questions}}, $question);
            push (@{$self->{layouts}}, $layout);
        }
        elsif ($line =~ $Regex::ENDLINE_DETECT_REGEX) {
            my $outro = $line;
            while ($line = readline($fh_in)) {
                $outro .= $line;
            }
            
            push (@{$self->{layouts}}, $outro);
        }
        else {
            my ($intro,$position);
            while ($line !~ $Regex::STARTLINE_DETECT_REGEX) {
                $intro .= $line;
                $position = tell($fh_in);
                $line = readline ($fh_in);
            }
            seek ($fh_in,$position,0);
            
            push (@{$self->{layouts}}, $intro);
        }
    }
}

sub get_question_total ($self) {
    return scalar(@{$self->{questions}});
}

sub get_marked_answer_pressed ($self,$question) {
    my @marked_answers = @{$self->{marked_answer}{$question}}; 
    my @pressed_answers = map { get_pressed($_) } @marked_answers;
    return @pressed_answers;
}

sub get_answers_pretty ($self,$num) {
    my $question = $self->get_question_pretty($num);
    $question = get_pressed($question);
    return @{$self->{answers}{$question}};
}

sub get_answers_pressed ($self,$num) {
    my @answers = get_answers_pretty ($self,$num);
    my @pressed_answers = map { get_pressed($_) } @answers;
    return @pressed_answers;
} 

sub get_question_pretty ($self,$num) {
    return $self->{questions}[$num - 1];
}

sub get_question_pressed ($self,$num) {
    my $question = get_question_pretty ($self,$num);
    return get_pressed($question);
}

sub get_layout ($self,$num) {
    return $self->{layouts}[$num];
}

sub get_pressed ($string) {
    my $press = $string;
    if ($string =~ $Regex::ANSWER_START_DETECT_REGEX) {
        $press =~ s{$Regex::ANSWER_PRESS_REGEX}{}g;
    }
    elsif ($string =~ $Regex::QUESTION_START_DETECT_REGEX) {
        $press =~ s{$Regex::QUESTION_PRESS_REGEX}{}g;
    }
    else {
        warn ("String: $string not modified");
    }
    return $press;
}

1;