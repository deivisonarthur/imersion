#!/bin/bash
# Imersion 2.0

# Monta as informações necessárias
export TOKEN=`date +%Y-%m-%d-%H-%M-%S`
export IMERSIONPATH=`pwd -P`

# Força a criação dos diretórios
mkdir -p "${IMERSIONPATH}/backups/development"
mkdir -p "${IMERSIONPATH}/backups/production"

# Funções

# Faz o backup do DB de desenvolvimento local
backup_development_local(){

	echo "[DESENVOLVIMENTO] => Realizando backup do DB MySQL local"
	if ( eval ${development_local_conection/mysql/mysqldump --add-drop-table --complete-insert} | gzip > $FILEDEVELOPMENT ); then
		echo "[DESENVOLVIMENTO] => Backup realizado com sucesso!"

	else exit 1; fi

}

# Faz o backup do DB de desenvolvimento remoto
backup_development_remote(){

	echo "[DESENVOLVIMENTO] => Realizando backup do DB MySQL"
	if ( eval ${development_remote_conection/mysql/mysqldump --add-drop-table --complete-insert} | gzip > $FILEDEVELOPMENT ); then
		echo "[DESENVOLVIMENTO] => Backup realizado com sucesso!"

	else exit 1; fi

}

# Faz o backup do DB de desenvolvimento local
# Também faz o backup do banco de produção remoto
backup_to_development(){

	backup_development_local
	backup_production_remote

}

# Faz backup e envia banco de desenvolvimento para o banco de produção
backup_development_to_production(){

	echo "[PRODUÇÃO] => Iniciado processo de cópia dos dados do DB de desenvolvimento para o DB de produção..."

	# Faz o backup de ambos os servers
	backup_development_local
	backup_production_remote

	# Atualiza o DB de PRODUÇÃO usando o arquivo de backup de DESENVOLVIMENTO
	echo "[PRODUÇÃO] => Atualizando dados do DB MySQL"

	if( gunzip < $FILEDEVELOPMENT | eval ${production_remote_connection} ); then
		echo "[PRODUÇÃO] => Atualização concluída com sucesso!"

	else exit 1; fi

	# Executa um script para alterar as referências nas "rows" do DB de PRODUÇÃO
	if [ "$on_production" != "" ]; then

		echo "[PRODUÇÃO] => Executando SQL on_production";
		if( eval ${production_remote_connection} <<EOF
	$on_production
EOF
		 ); then
			echo "[PRODUÇÃO] => SQL executada com sucesso!"

		else exit 1; fi

	fi

	echo "[PRODUÇÃO] => PRONTO!"

}

# Faz o backup do DB de produção local
backup_production_local(){

	echo "[PRODUÇÃO] => Realizando backup do DB MySQL local"
	if( eval ${production_local_connection/mysql/mysqldump --add-drop-table --complete-insert} | gzip > $FILEPRODUCTION ); then
		echo "[PRODUÇÃO] => Backup realizado com sucesso!"

	else exit 1; fi

}

# Faz o backup do DB de produção remoto
backup_production_remote(){

	echo "[PRODUÇÃO] => Realizando backup do DB MySQL"
	if( eval ${production_remote_connection/mysql/mysqldump --add-drop-table --complete-insert} | gzip > $FILEPRODUCTION ); then
		echo "[PRODUÇÃO] => Backup realizado com sucesso!"

	else exit 1; fi

}

# Faz o backup do DB de desenvolvimento remoto
# Também faz o backup do banco de produção local
backup_to_production(){

	backup_development_remote
	backup_production_local

}

# Faz backup e envia banco de produção para o banco de desenvolvimento
backup_production_to_development(){

	echo "[DESENVOLVIMENTO] => Iniciado processo de cópia dos dados do DB de produção para o DB de desenvolvimento..."

	# Faz o backup de ambos os servers
	backup_development_local
	backup_production_remote

	# Atualiza o DB de DESENVOLVIMENTO usando o arquivo de backup de PRODUÇÃO
	echo "[DESENVOLVIMENTO] => Atualizando dados do DB MySQL"

	if( gunzip < $FILEPRODUCTION | eval ${development_local_conection} ); then
		echo "[DESENVOLVIMENTO] => Atualização concluída com sucesso!"

	else exit 1; fi

	# Executa um script para alterar as referências nas "rows" do DB de DESENVOLVIMENTO
	if [ "$on_development" != "" ]; then

		echo "[DESENVOLVIMENTO] => Executando SQL on_development";
		if( eval ${development_local_conection} <<EOF
	$on_development
EOF
		); then
			echo "[DESENVOLVIMENTO] => SQL executada com sucesso!"

		else exit 1; fi

	fi

	echo "[DESENVOLVIMENTO] => PRONTO!"
}

# Remove todos os backups realizados dos DB e cria uma cópia do estado atual de todos os DB
remove_all_databases(){

	echo "[LIMPEZA] => Iniciando processo de limpeza de backups"

	# Remove tudo
	echo "[LIMPEZA] => Removendo arquivos de backups"
	rm -f -R "${IMERSIONPATH}/backups/development"
	rm -f -R "${IMERSIONPATH}/backups/production"

	# Recria as pastas
	echo "[LIMPEZA] => Recriando diretório para backups"
	mkdir -p "${IMERSIONPATH}/backups/development"
	mkdir -p "${IMERSIONPATH}/backups/production"

	# Faz o backup de ambos os servers
	backup_development_local
	backup_production_remote

	echo "[LIMPEZA] => Limpeza concluída!"

}

# Restaura o DB para uma versão X, a partir do token em que foi montada a SQL backup
# Também é feito o backup antes da restauração
restore_to_backup_token(){

	echo "[RESTAURAÇÃO] => Iniciando processo de restauração..."

	# Faz o backup de ambos os servers
	backup_development_local
	backup_production_remote

	echo "[RESTAURAÇÃO] => Digite o nº do token para a restauração do DB: "
	read version

	# Forma o nome do arquivo SQL
	restoreDEVELOPMENT="${IMERSIONPATH}/backups/development/${development_codename}-${version}.sql.gz"
	restorePRODUCTION="${IMERSIONPATH}/backups/production/${production_codename}-${version}.sql.gz"

	# Checa se existe o backup de desenvolvimento
	if [ ! -f $restoreDEVELOPMENT ]; then
		echo "[RESTAURAÇÃO] => Arquivo de restauração não encontrado... $restoreDEVELOPMENT"
		echo "[RESTAURAÇÃO] => Processo de restauração cancelado"
		exit 1
	fi

	# Checa se existe o backup de desenvolvimento
	if [ ! -f $restorePRODUCTION ]; then
		echo "[RESTAURAÇÃO] => Arquivo de restauração não encontrado... $restorePRODUCTION"
		echo "[RESTAURAÇÃO] => Processo de restauração cancelado"
		exit 1
	fi

	echo "[RESTAURAÇÃO] => Arquivos para restauração encontrados! Iniciando restauração dos DB..."

	# Restaura o DB de DESENVOLVIMENTO
	echo "[RESTAURAÇÃO] => Realizando a restauração para o DB de desenvolvimento"

	if( gunzip < $restoreDEVELOPMENT | eval ${development_local_conection} ); then
		echo "[DESENVOLVIMENTO] => Restauração realizada com sucesso!"

	else exit 1; fi

	# Restaura o DB de DESENVOLVIMENTO
	echo "[RESTAURAÇÃO] => Realizando a restauração para o DB de produção"

	if( gunzip < $restorePRODUCTION | eval ${production_remote_connection} ); then
		echo "[PRODUÇÃO] => Restauração realizada com sucesso!"

	else exit 1; fi

	echo "[RESTAURAÇÃO] => Restauração concluída!"

}

# Define as opções do programa
declare -a options

options[${#options[*]}]="BACKUP DESENVOLVIMENTO LOCAL - Realiza o backup do DB de desenvolvimento local";

options[${#options[*]}]="BACKUP PRODUÇÃO LOCAL - Realiza o backup do DB de produção local";

options[${#options[*]}]="BACKUP DESENVOLVIMENTO REMOTO - Realiza o backup do DB de desenvolvimento remoto";

options[${#options[*]}]="BACKUP PRODUÇÃO REMOTO - Realiza o backup do DB de produção remoto";

options[${#options[*]}]="BACKUP PARA DESENVOLVIMENTO - Realiza o backup do DB de desenvolvimento local e também faz o backup do DB de produção remoto";

options[${#options[*]}]="BACKUP PARA PRODUÇÃO - Realiza o backup do DB de produção local e também faz o backup do DB de desenvolvimento remoto";

options[${#options[*]}]="DESENVOLVIMENTO == PRODUÇÃO - Copia o conteúdo do DB de produção remoto e envia para o DB de desenvolvimento local, tornando ambos iguais. Se a SQL callback on_development foi setada, após a atualização do DB a SQL será executada, permitindo a fácil atualização para as informações dos dados de desenvolvimento";

options[${#options[*]}]="PRODUÇÃO == DESENVOLVIMENTO - Copia o conteúdo do DB de desenvolvimento local e envia para o DB de produção remoto, tornando ambos iguais. Se a SQL callback on_production foi setada, após a atualização do DB a SQL será executada, permitindo a fácil atualização para as informações dos dados de produção";

options[${#options[*]}]="LIMPEZA - Realiza a limpeza nos backups. Todos os backups são removidos e é criado um novo backup do estado atual de todos os DB";

options[${#options[*]}]="RESTAURAÇÃO - Restaura o DB para uma versão X, a partir do token em que foi montada a SQL backup. (Não é o mesmo token desta execução, você deve informar qual será o token)";

# Lê as configurações
echo "=> O token para esta execução é: $TOKEN"
echo "=> Selecione o arquivo de configuração para a execução do programa:"

select CONFFILE in conf/*;
do
	echo "=> Lendo arquivo de configuração: ${CONFFILE}"
	source "${CONFFILE}"

	# Forma o nome do arquivo SQL
	export FILEDEVELOPMENT="${IMERSIONPATH}/backups/development/${development_codename}-${TOKEN}.sql.gz"
	export FILEPRODUCTION="${IMERSIONPATH}/backups/production/${production_codename}-${TOKEN}.sql.gz"

	# Exibe o token gerado
	echo ""
	echo "=> Escolha a tarefa que você deseja executar:"
	echo "=> Executar em local de DESENVOLVIMENTO: 1, 4, 5, 7, 8, 9 e 10"
	echo "=> Executar em local de PRODUÇÃO: 2, 3 e 6"
	echo ""

	select TASK in "${options[@]}" "Sair"; do

		case "$REPLY" in
			1 ) backup_development_local; break;;
			2 ) backup_production_local; break;;
			3 ) backup_development_remote; break;;
			4 ) backup_production_remote; break;;

			5 ) backup_to_development; break;;
			6 ) backup_to_production; break;;

			7 ) backup_production_to_development; break;;
			8 ) backup_development_to_production; break;;

			9 ) remove_all_databases; break;;
			10 ) restore_to_backup_token; break;;

			$(( ${#options[@]}+1 )) ) echo "Até mais!"; break;;
    		*) echo "Opção inválida. Tente outra opção."; continue;;
		esac

	done

	exit 0;
done

# Acabou :)