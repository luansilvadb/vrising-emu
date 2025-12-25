# Deep Research: V Rising Dedicated Server + BepInEx no ARM64 com EasyPanel

> **Data**: 25 de Dezembro de 2024  
> **Hardware Target**: Oracle Ampere CPU 4x (ARM64), 24GB RAM  
> **Objetivo**: Rodar V Rising Dedicated Server + BepInEx usando EasyPanel

---

## 📋 Sumário Executivo

### A Resposta Direta

**Buildpacks NÃO são adequados para este caso.** 

Buildpacks (Heroku, Paketo, Nixpacks) são projetados para detectar automaticamente linguagens e frameworks conhecidos (Node.js, Python, Go, PHP, etc.). V Rising Dedicated Server é:

- Um **jogo Windows x86_64** que roda via **Wine**
- Requer **Box64/Box86** para emulação em ARM64
- Usa **SteamCMD** para download dos arquivos do servidor
- **BepInEx** requer patches específicos para ARM64 (Il2CppInterop modificado)
- Beneficia de **NTSync** para performance otimizada

### Soluções Viáveis no EasyPanel

| Método | Complexidade | Controle | Manutenção | Recomendação |
|--------|-------------|----------|------------|--------------|
| **Docker Image Mode** | Baixa | Médio | Mínima | ✅ **Recomendado** |
| **Dockerfile via GitHub** | Média | Total | Moderada | Para customização |
| ~~Buildpacks~~ | N/A | N/A | N/A | ❌ Não funciona |

---

## 🏗️ Arquitetura da Solução

### Stack Tecnológica

```
┌─────────────────────────────────────────────────────────────┐
│                      EasyPanel UI                           │
├─────────────────────────────────────────────────────────────┤
│                    Docker Container                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Ubuntu 25.04                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │          Wine 10.9 (staging-ntsync-wow64)       │  │  │
│  │  │  ┌─────────────────────────────────────────────┐│  │  │
│  │  │  │         V Rising Dedicated Server           ││  │  │
│  │  │  │  ┌───────────────────────────────────────┐  ││  │  │
│  │  │  │  │     BepInEx (Patched for ARM64)       │  ││  │  │
│  │  │  │  │  ┌─────────────────────────────────┐  │  ││  │  │
│  │  │  │  │  │           Mods/Plugins          │  │  ││  │  │
│  │  │  │  │  └─────────────────────────────────┘  │  ││  │  │
│  │  │  │  └───────────────────────────────────────┘  ││  │  │
│  │  │  └─────────────────────────────────────────────┘│  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐ │  │
│  │  │   Box64     │  │  SteamCMD   │  │   NTSync*     │ │  │
│  │  │  (ARM64→x64)│  │ (ARM→32-bit)│  │(kernel module)│ │  │
│  │  └─────────────┘  └─────────────┘  └───────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│               Oracle Ampere A1 (ARM64)                      │
│                4 Cores @ 3GHz | 24GB RAM                    │
└─────────────────────────────────────────────────────────────┘

* NTSync requer kernel Ubuntu 25.04+ com módulo habilitado
```

### Requisitos de Hardware

| Recurso | Mínimo | Recomendado | Seu Setup | Status |
|---------|--------|-------------|-----------|--------|
| CPU Cores | 4 | 6 | 4 | ⚠️ Mínimo |
| RAM | 6GB | 16GB | 24GB | ✅ Excelente |
| Disco | 15GB | 25GB | ? | Verificar |
| Arquitetura | ARM64 | ARM64 | ARM64 | ✅ |

### Requisitos de Armazenamento

| Componente | Tamanho |
|------------|---------|
| Wine Prefix | ~2GB |
| V Rising Server | ~8GB |
| BepInEx + Mods | ~500MB |
| Saves/Data | 100MB-1GB |
| **Total Mínimo** | **15GB** |

---

## 🚀 Método 1: Deploy via Docker Image (RECOMENDADO)

Esta é a abordagem mais simples e rápida, usando a imagem pré-construída `tsxcloud/vrising-ntsync`.

### Passo 1: Criar Novo Projeto no EasyPanel

1. Acesse o EasyPanel
2. Clique em **"Create Project"**
3. Nome: `vrising-server`

### Passo 2: Criar App Docker

1. No projeto, clique em **"Add Service"** → **"App"**
2. Selecione **"Docker Image"** (NÃO Buildpack)
3. Configure:
   - **Name**: `vrising`
   - **Image**: `tsxcloud/vrising-ntsync:latest`

### Passo 3: Configurar Variáveis de Ambiente

Na aba **"Environment"**, adicione:

```env
TZ=America/Sao_Paulo
SERVERNAME=VRising-ARM64-Server
ENABLE_PLUGINS=true
```

### Passo 4: Configurar Volumes (Persistência)

Na aba **"Mounts"** ou **"Volumes"**, configure:

| Container Path | Host Path / Volume | Descrição |
|----------------|-------------------|-----------|
| `/mnt/vrising/server` | Volume persistente | Arquivos do servidor |
| `/mnt/vrising/persistentdata` | Volume persistente | Saves e configs |

### Passo 5: Configurar Portas

Na aba **"Ports"**:

| Container Port | Host Port | Protocol | Descrição |
|----------------|-----------|----------|-----------|
| `9876` | `9876` | UDP | Game port |
| `9877` | `9877` | UDP | Query port |
| `25575` | `25575` | TCP | RCON (opcional) |
| `9090` | `9099` | TCP | Metrics (opcional) |

### Passo 6: Configurações Avançadas

Na aba **"Advanced"**:

- **Stop Grace Period**: `60s` (permite autosave correto)
- **Restart Policy**: `unless-stopped`

### Passo 7: Deploy

Clique em **"Deploy"** e aguarde. O primeiro start demora 5-15 minutos (download via SteamCMD).

---

## ⚙️ Método 2: Deploy via Dockerfile Customizado (GitHub)

Para quem deseja controle total sobre o ambiente.

### Estrutura do Repositório

```
vrising-emu/
├── Dockerfile
├── docker-compose.yml          # Para dev local
├── docker-compose.easypanel.yml
├── .dockerignore
├── .env.example
├── entrypoint.sh
├── config/
│   ├── ServerHostSettings.json
│   └── ServerGameSettings.json
├── scripts/
│   ├── wine-wrapper.sh
│   └── steamcmd-wrapper.sh
└── docs/
    ├── DEEP_RESEARCH_EASYPANEL_ARM64.md
    └── OPTIMIZATION.md
```

### Configuração no EasyPanel

1. **Conectar Repositório GitHub**
   - Settings → Git → Connect GitHub
   - Autorize o acesso ao repositório

2. **Criar App**
   - Add Service → App
   - Source: **GitHub**
   - Repository: `seu-usuario/vrising-emu`
   - Branch: `main`

3. **Build Settings**
   - Build Type: **Dockerfile** (auto-detectado)
   - Dockerfile Path: `./Dockerfile`
   - Context: `.`

4. **Push to Deploy**
   - Cada push para `main` triggera rebuild

---

## 🔧 Otimizações para ARM64 com 24GB RAM

### Variáveis de Ambiente Otimizadas

```env
# Timezone
TZ=America/Sao_Paulo

# Server Identity
SERVERNAME=VRising-ARM64-Server

# BepInEx
ENABLE_PLUGINS=true

# Wine Performance
WINE_LARGE_ADDRESS_AWARE=1
WINEDEBUG=-all

# Box64 Dynarec Optimizations
BOX64_DYNAREC=1
BOX64_DYNAREC_FASTROUND=1
BOX64_DYNAREC_FASTNAN=1
BOX64_DYNAREC_SAFEFLAGS=0
BOX64_DYNAREC_BIGBLOCK=2
BOX64_DYNAREC_STRONGMEM=0
BOX64_DYNAREC_BLEEDING_EDGE=1

# Memory
BOX64_MALLOC_HACK=1
```

### Limites de Recursos Recomendados

Configure no EasyPanel → Resources:

| Recurso | Limite | Justificativa |
|---------|--------|---------------|
| **CPU** | 3.5 cores | Deixa 0.5 core para sistema |
| **Memory** | 16GB | V Rising usa ~8-12GB, resto para overhead |
| **Memory Swap** | 4GB | Segurança extra |

### Configuração ServerGameSettings.json para Performance

```json
{
  "GameModeType": "PvP",
  "CastleDamageMode": "TimeRestricted",
  "PlayerDamageMode": "Always",
  "PlayerInteractionSettings": {},
  "BloodBoundEquipment": true,
  "ShardedWaypointLimit": 2,
  "ReducedResourceDurationMinutes": 0,
  "GameTimeModifiers": {
    "DayDurationInSeconds": 1080,
    "DayStartHour": 9,
    "DayStartMinute": 0,
    "DayEndHour": 17,
    "DayEndMinute": 0
  }
}
```

### Configuração ServerHostSettings.json

```json
{
  "Name": "VRising-ARM64",
  "Description": "Servidor ARM64 otimizado",
  "Port": 9876,
  "QueryPort": 9877,
  "MaxConnectedUsers": 10,
  "MaxConnectedAdmins": 2,
  "SaveName": "world1",
  "Password": "",
  "Secure": true,
  "ListOnSteam": false,
  "ListOnEOS": false,
  "AutoSaveCount": 20,
  "AutoSaveInterval": 300,
  "CompressSaveFiles": true,
  "GameSettingsPreset": "",
  "Rcon": {
    "Enabled": true,
    "Port": 25575,
    "Password": "CHANGE_ME_STRONG_PASSWORD"
  },
  "API": {
    "Enabled": true,
    "BindAddress": "0.0.0.0",
    "BindPort": 9090
  }
}
```

---

## 📊 NTSync: Performance Boost

### O que é NTSync?

NTSync é um módulo do kernel Linux que implementa primitivas de sincronização do Windows NT diretamente no kernel, oferecendo ganhos de performance de 20-600% para jogos Windows rodando via Wine/Proton.

### Status do NTSync

| Kernel | Status |
|--------|--------|
| 6.10 | Componentes básicos |
| 6.14+ (Março 2025) | Suporte completo |
| Ubuntu 25.04 | Disponível (manual enable) |

### Verificar Suporte no Host

```bash
# No servidor (host)
ls /dev/ntsync
# Se existir, NTSync está disponível
```

### Habilitar no Docker

Se o host suporta NTSync, adicione ao docker-compose:

```yaml
services:
  vrising:
    # ...
    devices:
      - /dev/ntsync:/dev/ntsync
```

### Sem NTSync

Se o host **NÃO** suporta NTSync, simplesmente não inclua a seção `devices`. O servidor funcionará normalmente, apenas sem a otimização extra.

---

## 🔌 BepInEx no ARM64

### O Problema

BepInEx usa `Il2CppInterop` que tem operações multithreaded que falham sob Box64 (emulador x86_64→ARM64).

### A Solução

O projeto `tsx-cloud/vrising-ntsync` inclui uma versão patcheada do Il2CppInterop que desabilita o multithreading problemático:

- Repositório: https://github.com/tsx-cloud/Il2CppInterop/commits/v-rising_1.1_arm_friendly/

### Instalação de Mods

1. Certifique-se que `ENABLE_PLUGINS=true`
2. Coloque os `.dll` dos mods em:
   ```
   ./vrising/server/BepInEx/plugins/
   ```
3. Reinicie o container

### Configuração Box64 para BepInEx

Crie/edite o arquivo:
```
./vrising/server/BepInEx/addition_stuff/box64.rc
```

Configurações recomendadas:
```ini
[VRisingServer.exe]
BOX64_DYNAREC=1
BOX64_DYNAREC_BIGBLOCK=2
BOX64_DYNAREC_FASTROUND=1
BOX64_DYNAREC_FASTNAN=1
BOX64_DYNAREC_BLEEDING_EDGE=1
```

---

## 🐛 Troubleshooting

### Problema: Container não inicia

**Causa provável**: Falta de memória ou CPU
**Solução**: Verifique os logs do container no EasyPanel

### Problema: SteamCMD falha no download

**Causa provável**: Espaço em disco insuficiente ou rede
**Solução**: 
- Verifique espaço em disco (mínimo 15GB)
- Verifique conectividade de rede

### Problema: BepInEx não carrega

**Causa provável**: Usando imagem sem patch ARM64
**Solução**: Use especificamente `tsxcloud/vrising-ntsync`

### Problema: Crash ao iniciar com plugins

**Causa provável**: Mod incompatível
**Solução**: 
1. Desabilite todos os plugins (`ENABLE_PLUGINS=false`)
2. Reative um por um para identificar o problemático

### Problema: NTSync device not found

**Causa**: Kernel do host não suporta NTSync
**Solução**: Remova a seção `devices` do docker-compose

### Logs Úteis

```bash
# Ver logs do container
docker logs vrising

# Logs do Wine
cat ./vrising/server/wine.log

# Logs do BepInEx
cat ./vrising/server/BepInEx/LogOutput.log
```

---

## 📚 Referências

### Repositórios

- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync) - Imagem Docker otimizada
- [TrueOsiris/docker-vrising](https://github.com/TrueOsiris/docker-vrising) - Base original
- [ptitSeb/box64](https://github.com/ptitSeb/box64) - Emulador x86_64→ARM64
- [Kron4ek/Wine-Builds](https://github.com/Kron4ek/Wine-Builds) - Wine staging builds

### Docker Hub

- [tsxcloud/vrising-ntsync](https://hub.docker.com/r/tsxcloud/vrising-ntsync)

### Documentação

- [EasyPanel Docs](https://easypanel.io/docs)
- [Box64 Usage](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)
- [V Rising Server Requirements](https://dathost.net/guides/v-rising-server-requirements)

---

## ✅ Checklist de Deploy

- [ ] EasyPanel instalado no servidor ARM64
- [ ] Projeto criado no EasyPanel
- [ ] App configurado com imagem `tsxcloud/vrising-ntsync:latest`
- [ ] Variáveis de ambiente configuradas
- [ ] Volumes persistentes configurados
- [ ] Portas mapeadas (9876/udp, 9877/udp, 25575/tcp)
- [ ] Stop grace period = 60s
- [ ] Primeiro deploy executado
- [ ] Aguardar download do SteamCMD (5-15 min)
- [ ] Verificar logs de inicialização
- [ ] Testar conexão via cliente V Rising
- [ ] (Opcional) Configurar mods BepInEx
- [ ] (Opcional) Configurar RCON
- [ ] (Opcional) Configurar backups automáticos
