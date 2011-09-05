#!/bin/sh

# Lê as configurações
source "app.conf"

# Monta as informações necessárias
export TOKEN=`date +%Y%m%d%H%M%s`
export IMERSIONPATH=`pwd -P`

# Exibe o token gerado
echo "=> O token para esta execução é: $TOKEN"

# Forma o nome do arquivo SQL
export FILEDEVELOPMENT="${IMERSIONPATH}/migrations/development/${development_mysql_database}-${TOKEN}.sql.gz"
export FILEPRODUCTION="${IMERSIONPATH}/migrations/production/${production_mysql_database}-${TOKEN}.sql.gz"

# Força a criação dos diretórios
mkdir -p "${IMERSIONPATH}/migrations/development"
mkdir -p "${IMERSIONPATH}/migrations/production"

# Checa se há o argumento task na chamada do arquivo
if [ "$1" != "" ]; then
	task=$1

# Se não tive, mostra as opções de tarefas
else
	
	echo "=> Escolha a tarefa que você deseja executar, digitando o nº da tarefa:
1 - [DESENVOLVIMENTO == PRODUÇÃO] Copia o conteúdo do banco de dados de produção e envia para o banco de dados de desenvolvimento, tornando ambos iguais. Se a SQL callback on_development foi setada, após a atualização do banco de dados a SQL será executada, permitindo a fácil atualização para as informações dos dados de desenvolvimento
2 - [PRODUÇÃO == DESENVOLVIMENTO] Copia o conteúdo do banco de dados de desenvolvimento e envia para o banco de dados de produção, tornando ambos iguais. Se a SQL callback on_production foi setada, após a atualização do banco de dados a SQL será executada, permitindo a fácil atualização para as informações dos dados de produção
3 - Realiza a limpeza nas migrações. Todas os backups são removidos e é criado um novo backup do estado atual de todos os banco de dados
4 - Restaura o banco de dados para uma versão X, a partir do token em que foi montada a SQL backup. (Não é o mesmo token desta execução, você deve informar qual será o token)"
	
	read task
fi

# Faz o backup de todos os banco de dados
backup_databases(){
	
	# DESENVOLVIMENTO
	echo "[DESENVOLVIMENTO] => Realizando backup do banco de dados MySQL"
	if ( mysqldump --add-drop-table --complete-insert -h ${development_mysql_host} -u ${development_mysql_user} -p${development_mysql_password} ${development_mysql_database} | gzip > $FILEDEVELOPMENT ); then
		echo "[DESENVOLVIMENTO] => Backup realizado com sucesso!"
	
	else exit 1; fi
	
	# PRODUÇÃO
	echo "[PRODUÇÃO] => Realizando backup do banco de dados MySQL"
	if( mysqldump --add-drop-table --complete-insert -h ${production_mysql_host} -u ${production_mysql_user} -p${production_mysql_password} ${production_mysql_database} | gzip > $FILEPRODUCTION ); then
		echo "[PRODUÇÃO] => Backup realizado com sucesso!"
	
	else exit 1; fi
	
}

# DESENVOLVIMENTO
# Faz o backup do banco de dados de PRODUÇÃO e envia para o banco de dados de DESENVOLVIMENTO
if [ "$task" == '1' ]; then
	
	echo "[DESENVOLVIMENTO] => Iniciado processo de cópia dos dados do banco de dados de produção para o banco de dados de desenvolvimento..."
	
	# Faz o backup de ambos os servers
	backup_databases
	
	# Atualiza o banco de dados de DESENVOLVIMENTO usando o arquivo de backup de PRODUÇÂO
	echo "[DESENVOLVIMENTO] => Atualizando dados do banco de dados MySQL"
	if( gunzip < $FILEPRODUCTION | mysql -h ${development_mysql_host} -u ${development_mysql_user} -p${development_mysql_password} ${development_mysql_database} ); then
		echo "[DESENVOLVIMENTO] => Atualização concluída com sucesso!"
	
	else exit 1; fi
	
	# Executa um script para alterar as referências nas "rows" do banco de dados de DESENVOLVIMENTO
	if [ "$on_development" != "" ]; then
		
		echo "[DESENVOLVIMENTO] => Executando SQL on_development";
		if( mysql -h ${development_mysql_host} -u ${development_mysql_user} -p${development_mysql_password} ${development_mysql_database} -e "$on_development" ); then
			echo "[DESENVOLVIMENTO] => SQL executada com sucesso!"
		
		else exit 1; fi
		
	fi
	
	echo "[DESENVOLVIMENTO] => PRONTO!"
	
# PRODUÇÃO
# Faz o backup do banco de dados de DESENVOLVIMENTO e envia para o banco de dados de produção
elif [ "$task" == '2' ]; then
	
	echo "[PRODUÇÃO] => Iniciado processo de cópia dos dados do banco de dados de desenvolvimento para o banco de dados de produção..."
	
	# Faz o backup de ambos os servers
	backup_databases
	
	# Atualiza o banco de dados de PRODUÇÃO usando o arquivo de backup de DESENVOLVIMENTO
	echo "[PRODUÇÃO] => Atualizando dados do banco de dados MySQL"
	if( gunzip < $FILEDEVELOPMENT |	mysql -h ${production_mysql_host} -u ${production_mysql_user} -p${production_mysql_password} ${production_mysql_database} ); then
		echo "[PRODUÇÃO] => Atualização concluída com sucesso!"
	
	else exit 1; fi
	
	# Executa um script para alterar as referências nas "rows" do banco de dados de PRODUÇÃO
	if [ "$on_production" != "" ]; then
		
		echo "[PRODUÇÃO] => Executando SQL on_production";
		if( mysql -h ${production_mysql_host} -u ${production_mysql_user} -p${production_mysql_password} ${production_mysql_database} -e "$on_production" ); then
			echo "[PRODUÇÃO] => SQL executada com sucesso!"
		
		else exit 1; fi
	
	fi
	
	echo "[PRODUÇÃO] => PRONTO!"
	
# LIMPEZA
# Remove todos os backups realizados dos banco de dados e cria uma cópia do estado atual de todos os banco de dados
elif [ "$task" == '3' ]; then
	
	echo "[LIMPEZA] => Iniciando processo de limpeza para migrações"
	
	# Remove tudo
	echo "[LIMPEZA] => Removendo arquivos de migração"
	rm -f -R "${IMERSIONPATH}/migrations/development"
	rm -f -R "${IMERSIONPATH}/migrations/production"
	
	# Recria as pastas
	echo "[LIMPEZA] => Recriando diretório para migrações"
	mkdir -p "${IMERSIONPATH}/migrations/development"
	mkdir -p "${IMERSIONPATH}/migrations/production"
	
	# Faz o backup de ambos os servers
	backup_databases
	
	echo "[LIMPEZA] => Limpeza concluída!"
	
# RESTAURAÇÃO
# Restaura o banco de dados para uma versão X, a partir do token em que foi montada a SQL backup
# Também é feito o backup antes da restauração
elif [ "$task" == '4' ]; then
	
	echo "[RESTAURAÇÃO] => Iniciando processo de restauração..."
	
	# Faz o backup de ambos os servers
	backup_databases
	
	# Checa se há o argumento version na chamada do arquivo
	if [ "$2" != "" ]; then
		version=$2
	
	# Se não tiver, lê o input do usuário
	else
		echo "[RESTAURAÇÃO] => Digite o nº do token para a restauração do banco de dados"
		read version
	fi
	
	# Forma o nome do arquivo SQL
	restoreDEVELOPMENT="${IMERSIONPATH}/migrations/development/${development_mysql_database}-${version}.sql.gz"
	restorePRODUCTION="${IMERSIONPATH}/migrations/production/${production_mysql_database}-${version}.sql.gz"
	
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
	
	echo "[RESTAURAÇÃO] => Arquivos para restauração encontrados! Iniciando restauração dos banco de dados..." 
	
	# Restaura o banco de dados de DESENVOLVIMENTO
	echo "[RESTAURAÇÃO] => Realizando a restauração para o banco de dados de desenvolvimento"
	if( gunzip < $restoreDEVELOPMENT | mysql -h ${development_mysql_host} -u ${development_mysql_user} -p${development_mysql_password} ${development_mysql_database} ); then
		echo "[DESENVOLVIMENTO] => Restauração realizada com sucesso!"
	
	else exit 1; fi
	
	# Restaura o banco de dados de DESENVOLVIMENTO
	echo "[RESTAURAÇÃO] => Realizando a restauração para o banco de dados de produção"
	if( gunzip < $restorePRODUCTION | mysql -h ${production_mysql_host} -u ${production_mysql_user} -p${production_mysql_password} ${production_mysql_database} ); then
		echo "[PRODUÇÃO] => Restauração realizada com sucesso!"
	
	else exit 1; fi
	
	echo "[RESTAURAÇÃO] => Restauração concluída!"

fi

# Acabou :)
exit 0
