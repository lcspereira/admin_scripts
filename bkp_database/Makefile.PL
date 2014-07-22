use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $DESTDIR = $ENV{DESTDIR} || '';
my $INSTALLDIRS = $ENV{INSTALLDIRS} || 'site';

WriteMakefile(
    NAME              => 'bkp_database',
    DIST_NAME         => 'bkp_database',
    VERSION_FROM      => 'bkp_database.pl', # finds $VERSION
    PREREQ_PM         => {
                           DBD::Pg     => '2.16.1',
                           XML::Simple => '2.20'
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'bkp_database.pl', # retrieve abstract from module
       AUTHOR         => 'Lucas Pereira <lucas.pereira@dbseller.com.br>' 
       MAN1PODS       => {
                           'doc/bkp_database.pod',
                           'doc/bkp_srv.pl'
                         }
        EXE_FILES     => [ qw(bkp_database.pl bkp_srv.pl) ]
     ) : ()),
);
