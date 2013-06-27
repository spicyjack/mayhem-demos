#!/usr/bin/env perl

# Gtk2 threads demo, as written by muppet
# http://mail.gnome.org/archives/gtk-perl-list/2003-November/msg00028.html

use strict;
use warnings;
use threads;
use threads::shared;

my $deathflag : shared;
my @work_q : shared;

$deathflag = 0;
my $thread = threads->create (sub {
    while (! $deathflag) {
        if (@work_q) {
            print "next: ".(shift @work_q)."\n";
            sleep 1;
        } else {
            threads->yield;
        }
    }
});

use Glib;
use Gtk2 '-init';

my $lastbusy = 0;
my $n = 0;

my $win = Gtk2::Window->new;
$win->signal_connect (delete_event => sub {
        if (@work_q) {
            warn "can't quit, busy...\n";
        } else {
            Gtk2->main_quit;
            $deathflag = 1;
        }
        # either way, don't destroy the window -- we'll do that
        # by hand below.
        return 1;
    });
my $box = Gtk2::VBox->new;
$win->add ($box);
my $label = Gtk2::Label->new ('idle');
$box->add ($label);
my $button = Gtk2::Button->new ('queue some work');
$box->add ($button);
$button->signal_connect (clicked => sub {
    push @work_q, ++$n;
});

Glib::Idle->add (sub {
    # touch the queue only once to avoid race conditions.
    my $thisbusy = @work_q;
    if ($thisbusy != $lastbusy) {
        $label->set_text ($thisbusy ? "$thisbusy left" : 'idle');
        $lastbusy = $thisbusy;
    }
    1;
});
$win->show_all;
Gtk2->main;
$win->destroy;

$thread->join;
