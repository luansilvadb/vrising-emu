# 🧛 V Rising ARM64 Dedicated Server

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![ARM64](https://img.shields.io/badge/ARM64-Optimized-green?logo=arm)](https://www.arm.com/)
[![BepInEx](https://img.shields.io/badge/BepInEx-Supported-purple)](https://github.com/BepInEx/BepInEx)

Servidor V Rising dedicado otimizado para **ARM64** (Oracle Ampere, Raspberry Pi 5, etc.) com suporte completo a **BepInEx** para mods.

---

## � Recursos

- ✅ **ARM64 Nativo** - Otimizado para CPUs Ampere/ARM64
- ✅ **Box64/Box86** - Emulação x86/x64 eficiente
- ✅ **Wine Staging** - Com suporte NTSync e WoW64
- ✅ **BepInEx** - Framework de mods com patches ARM64
- ✅ **SteamCMD** - Atualizações automáticas
- ✅ **EasyPanel Ready** - Deploy simples via UI
- ✅ **Graceful Shutdown** - Autosave antes de desligar

---

## 🏗️ Estrutura do Projeto

```
vrising-emu/
├── Dockerfile                          # Build customizado ARM64
├── docker-compose.yml                  # Dev local (build)
├── docker-compose.easypanel.yml        # Produção (imagem pronta)
├── entrypoint.sh                       # Script principal
├── .dockerignore                       # Otimização de build
├── .env.example                        # Template de variáveis
│
├── config/
│   ├── ServerHostSettings.json         # Configurações do host
│   └── ServerGameSettings.json         # Configurações de gameplay
│
├── scripts/
│   ├── wine-wrapper.sh                 # Wrapper Wine/Box64
│   ├── steamcmd-wrapper.sh             # Wrapper SteamCMD/Box86
│   ├── update-server.sh                # Atualizar servidor
│   ├── install-bepinex.sh              # Instalar BepInEx
│   └── healthcheck.sh                  # Health check Docker
│
├── bepinex/
│   ├── README.md                       # Instruções BepInEx ARM64
│   └── addition_stuff/
│       └── box64.rc                    # Config Box64 para BepInEx
│
└── docs/
    ├── DEEP_RESEARCH_EASYPANEL_ARM64.md  # Documentação técnica
    └── MODS_GUIDE.md                     # Guia de Mods (KindredLogistics, etc)
```

---

## 🚀 Quick Start

### Opção 1: Usar Imagem Pré-construída (Mais Rápido)

```bash
docker compose -f docker-compose.easypanel.yml up -d
```

### Opção 2: Build Local (Controle Total)

```bash
# Build e start
docker compose up -d --build

# Acompanhar logs
docker compose logs -f vrising
```

### Opção 3: Deploy via EasyPanel

1. Crie um novo projeto no EasyPanel
2. Conecte seu repositório GitHub
3. Configure as variáveis de ambiente
4. Deploy automático a cada push

---

## ⚙️ Configuração

### Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `TZ` | Timezone | `UTC` |
| `SERVERNAME` | Nome do servidor | `V Rising Server` |
| `ENABLE_PLUGINS` | Habilitar BepInEx | `false` |
| `UPDATE_SERVER` | Atualizar no start | `true` |

### Variáveis Box64 (Performance)

| Variável | Descrição | Valor Recomendado |
|----------|-----------|-------------------|
| `BOX64_DYNAREC` | Dynarec habilitado | `1` |
| `BOX64_DYNAREC_BIGBLOCK` | Tamanho do bloco | `2` |
| `BOX64_DYNAREC_FASTROUND` | Fast rounding | `1` |
| `BOX64_DYNAREC_FASTNAN` | Fast NaN | `1` |
| `BOX64_DYNAREC_SAFEFLAGS` | Safe flags | `0` |

Ver `.env.example` para lista completa.

---

## 📁 Volumes

| Container Path | Descrição |
|----------------|-----------|
| `/mnt/vrising/server` | Arquivos do servidor (Wine, V Rising, BepInEx) |
| `/mnt/vrising/persistentdata` | Dados persistentes (saves, configs) |

### Estrutura de Dados

```
vrising/
├── server/
│   ├── VRisingServer.exe
│   ├── VRisingServer_Data/
│   └── BepInEx/
│       ├── plugins/        ← Mods aqui
│       ├── config/
│       └── ...
└── persistentdata/
    ├── Settings/
    │   ├── ServerHostSettings.json
    │   └── ServerGameSettings.json
    └── Saves/
        └── world1/
```

---

## 🔌 Portas

| Porta | Protocolo | Descrição |
|-------|-----------|-----------|
| `9876` | UDP | Game port (obrigatório) |
| `9877` | UDP | Query port (server browser) |
| `25575` | TCP | RCON (administração) |
| `9090` | TCP | API/Metrics (Prometheus) |

---

## 🔧 BepInEx (Mods)

### Habilitar

```yaml
environment:
  - ENABLE_PLUGINS=true
```

### Instalar Mods

1. Coloque os arquivos `.dll` em:
   ```
   ./vrising/server/BepInEx/plugins/
   ```
2. Reinicie o container

### 🏭 Mod Destaque: KindredLogistics

O mod definitivo para automação de castelo. Transforma seu castelo em uma **máquina industrial**:

| Feature | Descrição |
|---------|-----------|
| **Quick Stash** | Deposita itens automaticamente em baús (reduz 30% do tempo gasto organizando) |
| **Craft from Containers** | Estações puxam recursos de baús próximos |
| **Auto-Salvage** | Dump chest → Devourer automático |
| **Auto-Refill** | Mist Braziers e Tombs auto-reabastecidos |

> 📖 **Guia Completo**: [docs/MODS_GUIDE.md](docs/MODS_GUIDE.md)

### Outros Mods Populares

| Mod | Descrição |
|-----|-----------|
| **KindredLogistics** | Automação completa de recursos |
| **KindredCommands** | Comandos admin avançados |
| **VampireCommandFramework** | Framework de comandos |
| **Bloodstone** | API base para mods |

---

## ⚡ NTSync (Performance Extra)

Se seu host tem Ubuntu 25.04+ com kernel 6.10+:

```bash
# Verificar suporte
ls /dev/ntsync

# Se existir, adicione ao docker-compose:
devices:
  - /dev/ntsync:/dev/ntsync
```

---

## 🛠️ Comandos Úteis

```bash
# Ver logs
docker compose logs -f vrising

# Atualizar servidor manualmente
docker compose exec vrising /opt/scripts/update-server.sh validate

# Instalar/Reinstalar BepInEx
docker compose exec vrising /opt/scripts/install-bepinex.sh --force

# Restart graceful (com autosave)
docker compose stop vrising
docker compose start vrising

# Acessar shell do container
docker compose exec vrising bash
```

---

## 📊 Requisitos de Hardware

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| CPU | 4 cores ARM64 | 6 cores ARM64 |
| RAM | 8GB | 16GB |
| Disco | 15GB | 25GB |
| Network | 10 Mbps | 100 Mbps |

---

## 🐛 Troubleshooting

### Servidor não inicia

```bash
# Verificar logs
docker compose logs vrising | tail -100

# Verificar se Wine inicializou
docker compose exec vrising ls -la /root/.wine
```

### BepInEx não carrega

```bash
# Verificar doorstop
docker compose exec vrising cat /mnt/vrising/server/doorstop_config.ini

# Verificar DLL override
docker compose exec vrising wine reg query "HKCU\\Software\\Wine\\DllOverrides"
```

### SteamCMD falha

```bash
# Verificar espaço
docker compose exec vrising df -h

# Rodar manualmente
docker compose exec vrising /opt/scripts/update-server.sh
```

---

## 📚 Documentação

- [Deep Research - EasyPanel ARM64](docs/DEEP_RESEARCH_EASYPANEL_ARM64.md)
- [Guia de Mods - KindredLogistics](docs/MODS_GUIDE.md)
- [BepInEx ARM64 Setup](bepinex/README.md)
- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)
- [Box64 Documentation](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)

---

## 📝 Licença

MIT

---

## 🙏 Agradecimentos

- [tsx-cloud](https://github.com/tsx-cloud) - Imagem Docker ARM64 base
- [TrueOsiris](https://github.com/TrueOsiris) - Docker original
- [ptitSeb](https://github.com/ptitSeb) - Box64/Box86
- [Kron4ek](https://github.com/Kron4ek) - Wine Builds
- [BepInEx Team](https://github.com/BepInEx) - Modding framework
