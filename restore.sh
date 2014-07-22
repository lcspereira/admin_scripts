#!/bin/bash
# =======================================================================================
# restore.sh
# =======================================================================================
# Restaura uma base em SGBD PostgreSQL a partir de um dump SQL compactado com bzip2
# @author: Lucas Pereira
# @since: 23/01/2012
# @param string: IP ou nome do servidor PostgreSQL
# @param integer: porta do servidor
# @param string: usuário do SGBD 
# @param string: senha do usuário
# @param string: nome da base a ser criada
# @param string: arquivo do dump (caminho)
#========================================================================================


# =====================================================================
# CONSTANTES
# =====================================================================
readonly TRUE=1
readonly FALSE=0
# =====================================================================

declare -A CONN
CMD_BUNZIP="/bin/bunzip2"
CMD_PSQL="/usr/lib/postgresql/9.1/bin/psql"
CMD_RESTORE="/usr/lib/postgresql/9.1/bin/pg_restore"
NOME_BASE=$5
ARQ_DUMP=$6
CMD_EXECUTAR=$7

# =====================================================================
# testaerro
# =====================================================================
# Verifica status de comando. Caso o status seja diferente de zero, A função poderá disparar um erro, ou abortar a execução do programa (caso $2 esteja configurado)
# @param integer: status do comando executado
# @param integer: define erro fatal (aborta execução em caso de erro)
# =====================================================================

function testaerro () {
  if [ $1 -ne 0 ] && [ $2 -eq $TRUE ]
  then
    echo -ne "[ FATAL ]\n" >&2
    exit $1
  elif [ $1 -ne 0 ]
  then
    echo -ne "[ ERRO ]\n" >&2
    echo "$1"
  elif [ $1 -eq 0 ]
  then
    echo -ne "[ OK ]\n"
  fi
}

# =====================================================================



# =====================================================================
# executa_SQL
# =====================================================================
# Executa comando SQL na base inicializada com ini_db
# @param string: Comando SQL a ser executado.
# =====================================================================

function executa_sql () { 
  SQL="$1"
  DISCARD_STDOUT=$2
  if [ -z $PGPASSWORD ] && [ -z ${CONN[senha]} ]
  then
    export PGPASSWORD=${CONN[senha]}
  fi
  if [ $DISCARD_STDOUT -eq $TRUE ]
  then
    $CMD_PSQL -U ${CONN[usuario]} -h ${CONN[host]} -p ${CONN[porta]} ${CONN[base]} -t -A -c "$SQL" >/dev/null
  elif [ $DISCARD_STDOUT -eq $FALSE ]
  then
    $CMD_PSQL -U ${CONN[usuario]} -h ${CONN[host]} -p ${CONN[porta]} ${CONN[base]} -t -A -c "$SQL"
  fi
  testaerro $? 1
  unset PGPASSWORD
}

# =====================================================================


#========================================================================================
# INÍCIO DO PROGRAMA
#========================================================================================
CMD_BUNZIP="/bin/bunzip2"
CMD_PSQL="/usr/lib/postgresql/9.1/bin/psql"
CMD_RESTORE="/usr/lib/postgresql/9.1/bin/pg_restore"


NOME_BASE=$5
ARQ_DUMP=$6
CMD_EXECUTAR=$7
STATUS=0


#========================================================================================
# RESTAURAÇÃO DA BASE
#========================================================================================
CONN=([host]=$1
        [porta]=$2
        [usuario]=$3
        [senha]=$4
        [base]="postgres") 
executa_sql 'CREATE DATABASE "'$NOME_BASE'";' $FALSE

CONN=([host]=$1
      [porta]=$2
      [usuario]=$3
      [senha]=$4
      [base]=$NOME_BASE)

[ ! -z $PGPASSWORD -a -z ${CONN[senha]} ] || export PGPASSWORD=${CONN[senha]}
if [ "$(file $ARQ_DUMP | cut -d ':' -f 2 | cut -d ' ' -f 2)" = "bzip2" ] 
then
  $CMD_BUNZIP -c $ARQ_DUMP | psql -U ${CONN[usuario]} -h ${CONN[host]} -p ${CONN[porta]} ${CONN[base]}
  STATUS=$?
elif [ "$(file $ARQ_DUMP | cut -d ':' -f 2 | cut -d ' ' -f 2)" = "PostgreSQL" ]
then
  $CMD_RESTORE -U ${CONN[usuario]} -h ${CONN[host]} -p ${CONN[porta]} -d ${CONN[base]} -L $ARQ_DUMP.list $ARQ_DUMP -v
  STATUS=$?
fi

if [ $STATUS -ne 0 ]
then
  CONN=([host]=$1
        [porta]=$2
        [usuario]=$3
        [senha]=$4
        [base]="postgres")
  executa_sql "DROP DATABASE \"$NOME_BASE\";" $FALSE # Em caso de erro, dropa a base que estava sendo restaurada.
  testaerro 1 1
else
  testaerro 0 1
  $CMD_PSQL -U postgres -h ${CONN[host]} -p ${CONN[porta]} ${CONN[base]} << SQL
    SET vacuum_cost_delay = 0;
    VACUUM ANALYZE;
SQL
fi
#========================================================================================


# EXECUÇÃO DO SCRIPT PÓS-RESTAURAÇÃO
[ -z "$CMD_EXECUTAR" ] || executa_sql "$CMD_EXECUTAR" $FALSE 
exit 0
