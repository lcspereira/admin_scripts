#!/usr/bin/perl
# ====================================================================================
# checkurl.pl
# ====================================================================================
# Script de verificação da URL a ser acessada pelo Squid.
# @author: Lucas Pereira
# @since: 04-04-2012
# ====================================================================================
require 'functions.ph';
use Net::SMTP;
use IO::File;
use DBI;
use Data::Dumper qw(Dumper);
use autodie;

# ===================================================
# Tratamento de sinais
# ===================================================
$SIG{INT}  = 'IGNORE';
$SIG{TERM} = 'IGNORE';
$SIG{QUIT} = 'IGNORE';
# ===================================================

%hConfig = ();
readConf ();

$oArqLog = IO::File->new ();
$oArqLog->open ($hConfig{'log_file'}, "a");
$oArqLog->print ("[" . localtime () . "] Iniciando script de verificação de URL do Squid.\n");
$oDB     = DBI->connect ("dbi:Pg:dbname=" . $hConfig{'database_base'} . ";host=" . $hConfig{'database_host'} . ";port=" . $hConfig{'database_port'}, $hConfig{'database_user'}, $hConfig{'database_password'}); 
$|       = 1; # Descarrega buffer de entrada padrão. Esta flag vale em toda a execução do script.
@aTbl = mapTables ();
$oArqLog->close();

while ($sURL = <>) {
  chop ($sURL);
  $oArqLog->open ($hConfig{'log_file'}, "a");
  if ($sURL ne "") {
    # ===================================================
    # Processamento da URL (extração do domínio)
    # ===================================================
    @aURL    = split ( /\//, $sURL);
    $sDomain = $aURL[2];
    undef (@aURL);
    @aDomain = split (/\./, $sDomain);
    $sSuffixTbl  = pop (@aDomain);
    $sNomeTabela = "domains_" . $sSuffixTbl;
    push (@aDomain, $sSuffixTbl);
    if ($aDomain[0] =~ /^www(|[0-100])\.*/) {
      shift (@aDomain);
    }
    undef ($sDomain);
    $sDomain = join (".",@aDomain);
    undef (@aDomain);
    $oArqLog->print ("[" . localtime () . "] $sDomain\n");
    # ===================================================


    # ===================================================
    # Validação do acesso
    # ===================================================
    if (grep { $_ = $sNomeTabela } @aTbl) {
      eval {
        $sSQLDomain = "SELECT url
                         FROM $sNomeTabela
                        WHERE url = '$sDomain';";
        $oResDomain = $oDB->prepare ($sSQLDomain);
        $oResDomain->execute ();
        if ($oResDomain->rows() > 0) {
          print "OK\n";
          $oArqLog->print ("[" . localtime () ."] OK\n");
        } else {
          print "ERR\n";
          $oArqLog->print ("[" . localtime () . "] ERR\n");
        }
        $oResDomain->finish ();
      };
      if ($@) {
        $sErr  = $@;
        $oArqLog->print ("$sErr\n");
        # Envia e-mail em caso de erro na conexão com o banco de dados
        $oMail = Net::SMTP->new ($hConfig{'mail_host'});
        $oMail->mail ('squid');
        $oMail->to ($hConfig{'mail_send'});
        $oMail->data ();
        $oMail->datasend ('To: ' . $hConfig{'mail_send'});
        $oMail->datasend ("\n");
        $oMail->datasend ('Subject: Squid - [ ERRO ]');
        $oMail->datasend ("\n");
        $oMail->datasend ("==========================================================\n");
        $oMail->datasend ("E-MAIL AUTOMÁTICO DO SCRIPT DE VERIFICAÇÃO DE URL DO SQUID\n");
        $oMail->datasend ("==========================================================\n\n");
        $oMail->datasend ("OCORREU UM ERRO AO CONECTAR COM A BASE DE DADOS DE URL'S DO SQUID:\n");
        $oMail->datasend ("$sErr");
        $oMail->dataend ();
        $oMail->quit ();
      }
      # ===================================================
    } else {
      print "ERR\n"; # Se a tabela contendo o domínio não for encontrada, considera a URL válida.
      $oArqLog->print ("[" . localtime () ."] ERR\n");
    }
  }
  $oArqLog->close ();
}

# ===================================================
# Encerrando programa
# ===================================================
$oArqLog->open ($hConfig{'log_file'}, "a");
$oArqLog->print ("[" . localtime () . "] AVISO: EOF detectado. Encerrando programa...\n");
$oResDomain->finish () if ($oResDomain);
$oDB->disconnect () if ($oDB);
$oArqLog->close ();
# ===================================================
exit 0;
