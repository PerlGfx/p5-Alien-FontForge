package Alien::FontForge;
# ABSTRACT: Alien package for the FontForge library

use strict;
use warnings;

use base qw( Alien::Base );
use Role::Tiny::With qw( with );

with 'Alien::Role::Dino';

use File::Spec;

sub pkg_config_path {
	my ($class) = @_;
	File::Spec->catfile($class->dist_dir, qw(lib pkgconfig));
}

1;
