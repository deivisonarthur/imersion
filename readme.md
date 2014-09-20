# Imersion 2.0 - Shell MySQL deploy system
Não é um script muito inteligente, mas funciona que é uma beleza!

#### Como utilizar

- Ajuste os dados de acesso em *conf/NAME.conf* (NAME é o nome do arquivo)
- Se você precisa realizar o backup de outros bancos de dados, crie outros arquivos de configuração com os dados do bancos. Ex: *conf/app.conf*, *conf/blog.conf*. Quando há mais de um arquivo de configuração, o programa irá lhe perguntar qual é o arquivo de configuração que deve ser lido para a execução.
- Execute *chmod +x run.sh* e depois execute *./run.sh*. Nesse momento você irá escolher uma tarefa a ser executada e agora é partir pro abraço... XD

#### Changelog

##### 2.0
- imersion.sh renomeado para run.sh
- Adicionado suporte a múltiplos DB
- Adicionado suporte a backup local
- Configurações agora ficam em um local específico *conf/*, com suporte a múltiplas configurações
- Novo diretório para os dumps: *backups/*

##### 1.0.5
- Token agora são no formato de data no padrão inglês para tornar mais fácil a leitura.

##### 1.0.4
- Ajuste para tornar SQLs on_* melhor executadas.

##### 1.0.3
- Fix para modo de execução em terminais Linux.

##### 1.0.2
- Fix para SQLs on_*, que agora também podem ter comentários.

##### 1.0.1
- Adicionado prefixo ao nome dos arquivos;
- Número do token simplificado mais ainda.

##### 1.0
- Primeira versão descente;
- Agora também funciona com conexões via SSH.

##### 0.1
- Versão inicial.
