#!/usr/bin/perl
use Carp;
# ===================================================
# mapTables
# ===================================================
# Mapeia tabelas existentes no banco de dados
# para a memória.
# @return boolean: Retorna 0 
# ===================================================
sub mapTables () {
  if (!defined ($oDB)) {
    croak ("FATAL: Não conectado à base\n");
    return undef;
  } else {
    $sSQLTbl = "SELECT table_name
                  FROM information_schema.tables
                 WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'pg_temp', 'pg_toast');";
    $oTblRes = $oDB->prepare ($sSQLTbl);
    $oTblRes->execute ();
    while (@aTblRes = $oTblRes->fetchrow_array ()) {
      $sTbl = shift (@aTblRes);
      push (@aTbl, $sTbl);
    }
    $oTblRes->finish ();
    return @aTbl;
  }
}
# ===================================================


# ===================================================
# readConf
# ===================================================
# Lê arquivo de configuração.
# ===================================================
sub readConf () {
  eval {
    $oArqConfig = IO::File->new ("/etc/squid3/mods/checkurl.conf", "r");
    while ($sLinha = $oArqConfig->getline()) {
      if ($sLinha eq "" || $sLinha =~ /^#/) {
        next;
      } else {
        chop ($sLinha);
        @aLinha = split (/#/, $sLinha);
        @aLinha = split (/\ /, $aLinha[0]);
        if ($aLinha[0] eq "") {
          next;
        } else {
          $hConfig{$aLinha[0]} = $aLinha[1];
        }
      }
    }
    $oArqConfig->close ();
  };
}
# ===================================================
1;
