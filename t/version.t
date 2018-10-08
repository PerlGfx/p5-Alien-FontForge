#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;
use Alien::FontForge;

subtest 'FontForge version' => sub {
	alien_ok 'Alien::FontForge';

	use DynaLoader;
	unshift @DynaLoader::dl_library_path, Alien::FontForge->rpath;
	# load shared object dependencies
	for my $lib ( qw(-lgunicode -lgutils -lgioftp) ) {
		my @files = DynaLoader::dl_findfile($lib);
		DynaLoader::dl_load_file($files[0]) if @files;
	}

	if( $^O eq 'darwin' ) {
		my @install_name_tool_commands = ();
		my @libs = qw(
			lib/libfontforge.2.dylib
			lib/libfontforgeexe.2.dylib lib/libgioftp.2.dylib
			lib/libgunicode.4.dylib
			lib/libgutils.2.dylib
		);

		for my $lib (@libs) {
			my $prop = Alien::FontForge->runtime_prop;
			my $rpath_install = $prop->{prefix}; # '%{.runtime.prefix}'
			my $rpath_blib = $prop->{distdir}; # '%{.install.stage}';
			my $blib_lib = "$rpath_blib/$lib";

			push @install_name_tool_commands,
				"install_name_tool -add_rpath $rpath_install -add_rpath $rpath_blib $blib_lib";
			push @install_name_tool_commands,
				"install_name_tool -id \@rpath/$lib $blib_lib";
			for my $other_lib (@libs) {
				push @install_name_tool_commands,
					"install_name_tool -change $rpath_install/$other_lib \@rpath/$other_lib $blib_lib"
			}
		}
		for my $command (@install_name_tool_commands) {
			system($command);
		}
	}

	my $xs = do { local $/; <DATA> };
	xs_ok {
		xs => $xs,
		verbose => 0,
		cbuilder_link => {
			extra_linker_flags =>
				# add -dylib_file since during test, the dylib is under blib/
				$^O eq 'darwin'
					? ' -rpath ' . Alien::FontForge->runtime_prop->{distdir}
					: ' '
		},
	}, with_subtest {
		my($module) = @_;
		is $module->version, Alien::FontForge->version,
			"Got FontForge version @{[ Alien::FontForge->version ]}";
	};

};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef _

#include "fontforge.h"

const char *
version(const char *class)
{
	return PACKAGE_VERSION;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
