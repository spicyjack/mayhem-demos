#!/usr/bin/env perl

# script to show a Builder XML interface created with Glade3
# requires the .glade file be concatenated to the end of this script, so it's
# probably best if you just create a new file on a tempoary filesystem with
# the contents of this file and the glade file, like this:
# cat layout_test.pl mayhem_gui_layout.glade > /tmp/layout.pl;
# perl /tmp/layout.pl

use strict;
use warnings;
use Gtk2;
use Glib qw(TRUE FALSE);

use constant {
    # script version
    VERSION         => "2010.4",
    # script release date
    RELEASE_DATE    => "01Sep2010",
    # for libgtk
    ID_COLUMN       => 0,
    # Mayhem logo for compact layout
    LOGO_COMPACT    => q(mayhem-logo.neon.orange-300x72.jpg),
    # Configuration logo
    ICON_CONFIGURE  => q(configure.png),
};

# a list of images to check for when starting up
#my @required_images = qw(
#    mayhem-logo.text.neon.orange-300x75.jpg
#    mohawkb-skinny-150x234.jpg
#    mayhem-logo.neon.orange-300x72.jpg
#    configure.png
#); # my @required_images

# set up the environment to point to a new GTKRC file
# can also be used to skip the GUI entirely
# http://mail.gnome.org/archives/gtk-perl-list/2007-August/msg00064.html
my @theme_dirs = qw(
    /usr/share/themes/Nodoka-Fuego
    /opt/local/share/themes/Nodoka-Fuego
); # my @theme_dirs

THEME:
    foreach my $theme ( @theme_dirs ) {
        if ( -d $theme ) {
            #print qq(Setting theme to Nodoka Fuego\n);
            #$ENV{q(GTK2_RC_FILES)} = $fuego . q(gtk-2.0/gtkrc);
            $ENV{q(GTK2_RC_FILES)} = qq($theme/gtk-2.0/gtkrc);
            last THEME;
        }
    } # foreach my $theme ( @theme_dirs )
# see also
# http://library.gnome.org/devel/gtk/stable/gtk-Resource-Files.html
# http://library.gnome.org/devel/gtk/unstable/gtk-running.html
# for more dirt on GTK2_RC_FILES

# FIXME demo script doesn't know which layout it's running with; different
# layouts use different image files, which breaks things when you go to check
# for files (below)
# check for the mayhem logo(s) and configure button icon
#foreach my $required_image ( @required_images ) {
#    if ( ! -e $required_image ) {
#        die qq(ERROR: Can't locate image $required_image);
#    } # if ( ! -e $required_image )
#} # foreach my $required_image ( @required_images )

# initialize GTK and friends
Gtk2->init;
#load UI from a text string
# http://mail.gnome.org/archives/gtk-perl-list/2010-April/msg00000.html
my $builder = Gtk2::Builder->new();
my @data = <DATA>;
my $joined_data = join(qq(), @data);
$builder->add_from_string($joined_data);

my @games = (
    q(Doom),
    q(Quake),
    q(Duke Nukem 3D),
    q(Descent),
); # my @games

my @engines = (
    q(Chocolate Doom),
    q(Doom Legacy),
    q(DENG - Doomsday Engine),
    q(EDGE - Enhanced Doom Game Engine),
    q(Eternity Engine),
    q(Odamex),
    q(PrBoom),
    q(PrBoom+),
    q(ReMooD),
    q(Vavoom),
    q(ZDoom),
);

my @iwads = (
    q(Freedoom),
    q(Doom),
    q(Shareware Doom),
    q(Doom II),
    q(Ultimate Doom),
    q(The Plutonia Experiment),
    q(TNT: Evilution),
    q(Heretic),
    q(Shareware Heretic),
    q(Hexen),
    q(Hexen: Deathkings of the Dark Citadel),
    q(Strife),
);

my @profiles = (
    q(No Profile),
    q(Profile #1),
    q(Profile #2),
    q(Profile #3),
    q(Profile #4),
);

sub get_version_string {
    return q(Mayhem Launcher, version )
        . VERSION . q| (|
        . RELEASE_DATE . q|)|;
} # sub get_version_string

# set up the information stores
# doom engines
my $engines_store = Gtk2::ListStore->new(qw(Glib::String));
foreach my $engine ( @engines ) {
    $engines_store->set($engines_store->append(), ID_COLUMN, $engine);
} # foreach my $engine ( @engines )

# doom wads
my $game_store = Gtk2::ListStore->new(qw(Glib::String));
foreach my $game ( @games ) {
    $game_store->set($game_store->append(), ID_COLUMN, $game);
} # foreach my $game ( @games )

# profiles
my $profiles_store = Gtk2::ListStore->new(qw(Glib::String));
foreach my $profile ( @profiles ) {
    $profiles_store->set($profiles_store->append(), ID_COLUMN, $profile);
} # foreach my $profile ( @profiles )

# see http://gtk2-perl.sourceforge.net/doc/pod/Gtk2/ComboBox.html
# for a full explanation of how to create a ComboBox using a renderer

# a renderer for text in cells, needed for the combo boxes below
my $renderer = Gtk2::CellRendererText->new();

# grab all of the controls that we will want to modify later; make sure that
# we have valid controls though
my $toplevel = $builder->get_object(q(toplevel));

# profiles combo box
my $cbo_profile = $builder->get_object(q(cbo_profile));
if ( defined $cbo_profile ) {
    $cbo_profile->pack_start($renderer, TRUE);
    $cbo_profile->add_attribute($renderer, q(text) => ID_COLUMN);
    $cbo_profile->set_model($profiles_store);
    $cbo_profile->set_active(0);
} # if ( defined $cbo_profile )

# game combo box
my $cbo_game = $builder->get_object(q(cbo_game));
if ( defined $cbo_game ) {
    $cbo_game->pack_start($renderer, TRUE);
    $cbo_game->add_attribute($renderer, q(text) => ID_COLUMN);
    $cbo_game->set_model($game_store);
    $cbo_game->set_active(0);
} # if ( defined $cbo_game )

# engines combo box
my $cbo_engine = $builder->get_object(q(cbo_engine));
if ( defined $cbo_engine ) {
    $cbo_engine->pack_start($renderer, TRUE);
    $cbo_engine->add_attribute($renderer, q(text) => ID_COLUMN);
    $cbo_engine->set_model($engines_store);
    $cbo_engine->set_active(0);
} # if ( defined $cbo_engine )

# grab the statusbar object
my $statusbar = $builder->get_object(q(statusbar));
if ( defined $statusbar ) {
    # set the statusbar message
    my $id_version = $statusbar->get_context_id(q(script_version));
    # the msg_id would be used to pop this message back off of the stack
    my $msg_id = $statusbar->push($id_version, get_version_string() );

} # if ( defined $statusbar )

# progress bar for the splash screen
my $progress = $builder->get_object(q(progress_splash));

if ( defined $progress ) {
    my $lbl_substatus = $builder->get_object(q(lbl_substatus));
    $lbl_substatus->set_text( get_version_string() );
    # add a script killer
    Glib::Timeout->add(6000, sub {Gtk2->main_quit} );
    my $progress_value = 0;
    $progress->set_orientation(q(left-to-right));
    Glib::Timeout->add(500, sub {
        $progress->set_fraction( $progress_value/10 );
        $progress->set_text($engines[$progress_value]);
        $progress_value++;
        if ( $progress_value == 11 ) {
            $progress->set_text(q(Done!));
            return FALSE;
        } else {
            return TRUE;
        } # if ( $progress_value == 1.1 )
    }) # Glib::Timeout->add(500, sub
} # if ( defined $progress )


# the buttons at the bottom of the dialog
my $quit_btn = $builder->get_object(q(quit));
my $launch_btn = $builder->get_object(q(launch));
# connect some signals
$toplevel->signal_connect(destroy => sub {Gtk2->main_quit});
# but only if the controls are defined
if ( defined $quit_btn && defined $launch_btn ) {
    $quit_btn->signal_connect(clicked => sub {Gtk2->main_quit});
    $launch_btn->signal_connect(clicked => sub {warn qq(LAUNCH!!!\n)});
} # if ( defined $quit_btn && defined $launch_btn )

# display the main window
$toplevel->show_all();

# pass control to GTK MainLoop
Gtk2->main();

# http://gtk2-perl.sourceforge.net/doc/yapc-2004-perl-gtk2/slides.html
=pod

Gtk2::Rc->parse_string(<<__);
include "/usr/local/share/themes/Bumblebee/gtk-2.0/gtkrc"

style "normal" {
    font_name ="serif 30"
}

style "my_entry" {
    font_name ="sans 25"
    text[NORMAL] = "#FF0000"
}

widget "*" style "normal"
widget "*Entry*" style "my_entry"
__

=cut

# from http://mail.gnome.org/archives/gtk-perl-list/2010-May/msg00062.html
=pod
my $mod   = Gtk2::RcStyle->new;
$mod->Gtk2::Rc::parse_string(
qq[
gtk-theme-name = "Unity"
style "user-font"
{
                font_name="Sans 10"
}
widget_class "*" style "user-font"
]);
=cut

# http://cgi2.cs.rpi.edu/~lallip/perl/fall05/debugging.shtml
__DATA__
