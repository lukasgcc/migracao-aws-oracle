Oracle Cloud Multi-Node Infrastructure: OurCraft Ecosystem

Este repositório armazena a infraestrutura de código, arquivos de automação e configurações de produção desenvolvidos para o ecossistema do servidor **OurCraft** (`ourcraft.com.br`). 

O projeto aplica conceitos avançados de DevOps, SysAdmin e Arquitetura de Nuvem para implementar uma infraestrutura resiliente, segura e de alta performance na **Oracle Cloud Infrastructure (OCI)**, dividida em múltiplos nós dedicados para isolar aplicações web de servidores de jogos de alta demanda de processamento.

---

Arquitetura de Rede e Sistemas

A infraestrutura é segmentada em dois nós computacionais (VMs) independentes na nuvem OCI:

```
                              [ Usuários / Jogadores ]
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼ (Porta 80 / 443 - HTTPS)                      ▼ (Porta 25565 - Minecraft)
      ┌───────────────────────┐                       ┌───────────────────────┐
      │     ORACLE NODE 1     │                       │     ORACLE NODE 2     │
      │   (Web Node - Web)    │                       │  (Game Node - Jogo)   │
      ├───────────────────────┤                       ├───────────────────────┤
      │ 🐳 Docker Compose     │                       │ 🟢 Crafty Controller  │
      │  ├── Nginx (Reverse)  │                       │  └── Minecraft Server │
      │  └── Spring API (21)  │                       │                       │
      └───────────────────────┘                       └───────────────────────┘
                                                                  │ (Hourly Cron Script)
                                                                  ▼
                                                       ┌───────────────────────┐
                                                       │  ☁️ Google Drive Cloud │
                                                       │   (Rolling Backups)   │
                                                       └───────────────────────┘
```
Web Node (VM de Aplicação e Telemetria)

* **Domínio Principal:** `ourcraft.com.br` (Site Institucional)
* **Subdomínio de Gerenciamento:** `painel.ourcraft.com.br` (API & Crafty Access)
* **Orquestração de Container:** Gerenciado via **Docker & Docker Compose** para isolamento absoluto de dependências.
* **Proxy Reverso & Segurança:** Um servidor **Nginx** intercepta as chamadas na porta `80` (HTTP) e as redireciona automaticamente para a porta segura `443` (HTTPS) criptografada via certificado digital **Let's Encrypt (Certbot)**.
* **Gestão de Rotas Avançada:**
  * Chamadas na raiz `/` de `ourcraft.com.br` servem a página web estática do site institucional.
  * Chamadas para `painel.ourcraft.com.br` realizam um tunelamento via Proxy Reverso apontando diretamente para o painel de administração física do Crafty no Game Node (Porta `8443`), mascarando o IP real do jogo, contornando bloqueios de firewalls residenciais de portas altas e habilitando WebSockets para console síncrono.
  * Chamadas para `painel.ourcraft.com.br/api/` são traduzidas e repassadas internamente ao container da API Java.

Game Node (VM Dedicada de Jogos)

* **Subdomínio de Conexão:** `mc.ourcraft.com.br` (Porta padrão do jogo: `25565`)
* **Gerenciador:** **Crafty Controller v4** integrado nativamente como um serviço do sistema operacional Linux (`systemd`), garantindo resiliência e inicialização no boot.
* **Automação de Backups com Retenção FIFO:**
  * Um script inteligente em Bash (`backup.sh`) é disparado de hora em hora pelo agendador do sistema (`cron`).
  * O script compacta as pastas ativas de todos os servidores de jogos criados na máquina de forma automatizada e realiza o upload criptografado para o Google Drive do projeto via **Rclone API**.
  * **Algoritmo FIFO:** O script verifica os arquivos contidos na nuvem e retém rigorosamente apenas os **3 backups mais recentes** de cada mundo ativo de forma independente, apagando os excedentes para economia de custos e manutenção de histórico rápido de recuperação em caso de falhas (*disaster recovery*).

Tecnologias de Infraestrutura Utilizadas

* **Provedor de Nuvem:** Oracle Cloud Infrastructure (OCI)
* **Isolamento de Processos:** Docker & Docker Compose
* **Web Server & Gateway:** Nginx
* **Segurança de Comunicação:** Let's Encrypt SSL (Certbot)
* **Linguagens e Runtimes:** Java JDK 21 (Eclipse Temurin), Python (.venv) e Bash Shell Scripting
* **Framework Backend:** Spring Boot
* **Painel de Controle:** Crafty Controller 4
* **Integração de Cloud Storage:** Google Drive API via Rclone
* **Sistema Operacional:** Linux Ubuntu Server LTS
* **Defesa de Rede:** Regras persistentes de IPTables e Security Lists de nuvem.

---

Como Executar o Ambiente Web Localmente

Se desejar clonar o repositório e executar a camada web em seu computador localmente, certifique-se de ter o Docker e Docker Compose instalados e siga as etapas:

```bash
# Clone o repositório
git clone [https://github.com/lukasgcc/migracao-aws-oracle.git](https://github.com/lukasgcc/migracao-aws-oracle.git)
cd migracao-aws-oracle/docker-web-node

# Certifique-se de ter um arquivo .jar da API dentro de /api
# Inicie o ecossistema local em segundo plano
docker compose up -d
```
O servidor do Nginx estará disponível em seu navegador em `http://localhost`.
```
