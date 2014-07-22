#!/usr/bin/perl
# =================================================================================
# bkp_database.pl
# =================================================================================
# Rotina de backup das bases através de pg_dump (cliente)
# Envia as informações ao servidor para que seja feito backups no servidor.
# Somente as bases listadas no arquivo databases terão backup.
# Pode fazer backups em vários clusters diferentes em um mesmo servidor.
#
# @author: Lucas Pereira
# @since: 22-06-2012
# =================================================================================
use DBI;
use IO::Socket::INET;
use IO::File;
use XML::Simple;
use autodie;

our $VERSION = 2.0;
# ==========================================
# Parâmetros passados por linha de comando
# ==========================================
$sHost      = $ARGV[0];                                         # Servidor onde estão as bases
$sPathArqDB = $ARGV[1];                                         # Caminho para o arquivo databases
# ==========================================

@aHost   = split (/:/, $sHost);
@aConfDB = ("port", "user", "password", "database", "version"); # Array de configurações para criar o 

$oSock   = IO::Socket::INET->new (
                                   PeerHost  => $aHost[0],
                                   PeerPort  => $aHost[1],
                                   Proto     => 'tcp',
                                   Type      => SOCK_STREAM,
                                   Timeout   => 30
                                 ) or die ($!);
$oSock->autoflush (1);
$oArqDB = IO::File->new ($sPathArqDB, "r") or die ($!);                    # Arquivo databases
$sLine  = $oArqDB->getline ();

do {
  @aLine = split (/,/, $sLine);
  $i     = 0;
  foreach $sLinha (@aLine) {
    $hConfDB{$aConfDB[$i]} = $sLinha;
    $oSock->send ("$sLinha\n");                                # Envia informações para fazer dump da base.
    sleep (2);
    $i++;
  }
  $oSock->recv ($_, 20);                                       # Recebe status do pg_dump enviado pelo servidor

  # ==========================================
  # VACUUM ANALYZE
  # ==========================================
  $oSock->send ("VACUUM ANALYZE\n");
  eval {
    $oDB = DBI->connect ("dbi:Pg:dbname=" . $hConfDB{'database'} . ";host=" . $aHost[0] . ";port=" . $hConfDB{'port'}, $hConfDB{'user'}, $hConfDB{'password'}, {
                                                                                                                                                                 RaiseError         => 1, 
                                                                                                                                                                 PrintWarn          => 1,
                                                                                                                                                                 ShowErrorStatement => 1,
                                                                                                                                                               });

    $oDB->do ("VACUUM ANALYZE;");
    $oSock->send ("OK\n");
    $oDB->disconnect ();
  };
  $oSock->send ($@ . "\n") if ($@);
  # ==========================================

  if (($sLine = $oArqDB->getline ())) {
    $oSock->send ("1\n");                                    # Informa ao servidor que existem mais bases que devem ser feitas backup.
  } else {
    $oSock->send ("0\n");                                    # Sinaliza para o servidor que não existem mais bases para backup.
  }
} while ($sLine ne "");

$oArqDB->close ();
$oSock->shutdown (2);
exit 0;


__END__
=head1 NOME

  bkp_database - Serviço de rotina de backup para bancos de dados PostgreSQL (cliente).

=head1 SINOPSE
  
  bkp_database.pl <host>:<porta> <arquivo databases>

=head1 DESCRIÇÃO

  Cliente para execução de backup lógico e rotinas de manutenção básicas (VACUUM ANALYZE) de bancos de dados PostgreSQL utilizando pg_dump.
  Pode ser utilizado tando em modo standalone, como pode utilizado juntamente com sistemas gerenciadores de backup, como o Bacula.
  
  Este script foi feito de maneira a ser possível fazer backup de bases em vários clusters em um mesmo servidor.

=head1 ARQUIVO DATABASES
  
  O arquivo databases é utilizado somente pelo cliente, e utiliza formato CSV, com as seguintes colunas:
  I<porta,usuario,senha,nome_da_base,versão_da_base>

  Este arquivo é o que torna possível fazer backup de vários clusters em um mesmo servidor.

=head1 VER TAMBÉM

  DBI
  
=head1 AUTOR

  Lucas Pereira, E<lt>lucas.pereira@dbseller.com.brE<gt>

=head1 LICENÇA

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.10.1 or,
  at your option, any later version of Perl 5 you may have available.

=cut
