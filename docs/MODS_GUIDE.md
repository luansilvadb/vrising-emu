# 🧛 V Rising Mods Guide - BepInEx Plugins

Este guia documenta os mods recomendados para servidores V Rising, com foco especial em **KindredLogistics** - o mod que transforma seu castelo em uma máquina de automação.

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Instalação de Mods](#instalação-de-mods)
3. [Mods Essenciais](#mods-essenciais)
4. [KindredLogistics - O Mod de Automação](#kindredlogistics---o-mod-de-automação)
5. [KindredCommands](#kindredcommands)
6. [Outros Mods Recomendados](#outros-mods-recomendados)
7. [Compatibilidade ARM64](#compatibilidade-arm64)

---

## Visão Geral

V Rising vanilla é excelente, mas jogadores vindos de experiências como **"Better Minecraft"** com mods como Applied Energistics e Refined Storage sentirão falta de automação e gerenciamento inteligente de inventário.

A solução? **BepInEx + Mods de qualidade de vida**.

### Por que usar mods?

| Problema Vanilla | Solução com Mods |
|------------------|------------------|
| Organização manual de milhares de itens | Quick Stash automático |
| Carregar recursos para cada estação | Crafting direto de baús |
| Verificar braziers e tombs manualmente | Auto-refill de recursos |
| Salvage manual de items indesejados | Auto-salvage para Devourer |

---

## Instalação de Mods

### Pré-requisitos

1. **BepInEx habilitado**: `ENABLE_PLUGINS=true`
2. Servidor reiniciado após habilitar
3. Diretório de plugins criado

### Estrutura de Arquivos

```
vrising/server/BepInEx/
├── core/                    # Core do BepInEx (não modificar)
├── config/                  # Configurações dos mods
├── plugins/                 # ← MODS VÃO AQUI
│   ├── KindredLogistics.dll
│   ├── KindredCommands.dll
│   └── VampireCommandFramework.dll
└── patchers/               # Patchers (avançado)
```

### Instalação Básica

1. Baixe o mod (`.dll`) do [Thunderstore](https://v-rising.thunderstore.io/) ou GitHub
2. Copie para `./vrising/server/BepInEx/plugins/`
3. Reinicie o servidor
4. Verifique os logs: `./vrising/server/BepInEx/LogOutput.log`

---

## Mods Essenciais

### Dependências Comuns

| Mod | Descrição | Obrigatório Para |
|-----|-----------|------------------|
| **VampireCommandFramework** | Framework de comandos | KindredCommands |
| **Bloodstone** | API base | Vários mods |

---

## KindredLogistics - O Mod de Automação

> 🏭 **"Logistical Optimization: The Industrial Castle"**

KindredLogistics é o mod definitivo para jogadores que valorizam automação e eficiência. Ele transforma seu castelo de um depósito caótico em uma **máquina industrial organizada**.

### Por que KindredLogistics?

Jogadores de "Better Minecraft" são obcecados com automação e gerenciamento de inventário (Applied Energistics, Refined Storage). V Rising vanilla requer organização manual de **milhares de itens**. KindredLogistics é a solução para esse tédio.

---

### 7.1 A Revolução do "Quick Stash"

A feature mais impactante do KindredLogistics é o **Quick Stash** (geralmente vinculado a um comando de chat ou interação específica).

#### Como Funciona

1. Jogador ativa Quick Stash (comando ou keybind)
2. Sistema escaneia baús próximos
3. Itens do inventário são **automaticamente depositados** em baús que já contêm aquele tipo de item

#### Benefícios

| Métrica | Vanilla | Com Quick Stash |
|---------|---------|-----------------|
| Tempo organizando | ~30% do gameplay | Próximo de zero |
| Cliques necessários | Centenas | Um comando |
| Frustração | Alta | Mínima |

> 📊 **Estudos de gameplay survival** sugerem que jogadores gastam até **30% do tempo** organizando inventário. Este mod reduz isso para quase zero.

**Filosofia**: Mantém o jogador **no mundo jogando o jogo**, ao invés de jogar "Inventory Tetris".

---

### 7.2 Crafting from Containers

Esta feature permite que estações de crafting (Sawmills, Furnaces, etc.) **puxem recursos diretamente de baús próximos**.

#### A "Base Network"

Isso efetivamente transforma o castelo em um **organismo unificado**:

```
┌─────────────────────────────────────────────────────────────┐
│                    CASTLE NETWORK                           │
│                                                             │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐              │
│   │  Chest  │────▶│ Sawmill │────▶│  Chest  │              │
│   │  (Wood) │     │         │     │ (Planks)│              │
│   └─────────┘     └─────────┘     └─────────┘              │
│        │                               │                    │
│        │              ┌────────────────┘                    │
│        ▼              ▼                                     │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐              │
│   │  Chest  │────▶│ Furnace │────▶│  Chest  │              │
│   │  (Ore)  │     │         │     │ (Ingots)│              │
│   └─────────┘     └─────────┘     └─────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Exemplo Prático

**Antes (Vanilla)**:
1. Ir ao baú de madeira
2. Pegar 500 madeira
3. Andar até a Sawmill
4. Depositar madeira
5. Esperar
6. Coletar planks
7. Levar para baú de planks
8. Repetir 100x

**Depois (KindredLogistics)**:
1. Clicar em "Refine" na Sawmill
2. ✅ Done

> 🏗️ **A Sensação**: Simula uma rede de pipes do Modded Minecraft **sem a bagunça visual de tubos e cabos**.

---

### 7.3 Automation: Salvage e Refill

KindredLogistics introduz **automação ativa** para tarefas repetitivas.

#### Auto-Salvage

Jogadores podem designar um **"Dump Chest"** (Baú de Descarte):

```
┌──────────────┐        ┌──────────────┐
│  Dump Chest  │───────▶│   Devourer   │
│   (Lixo)     │  Auto  │  (Reciclagem)│
└──────────────┘        └──────────────┘
```

**Fluxo**:
1. Jogador joga items indesejados no Dump Chest
2. Sistema automaticamente envia para o Devourer
3. Recursos são reciclados
4. Materiais base voltam para o inventário/storage

**Benefício**: Nunca mais acumular lixo. Equipamentos antigos, drops inúteis - tudo vira recursos úteis automaticamente.

#### Auto-Refill

Estruturas críticas podem ser **auto-alimentadas** de um suprimento central:

| Estrutura | Recurso | Automação |
|-----------|---------|-----------|
| **Mist Braziers** | Bones/Flowers | Auto-refill de supply |
| **Tombs** | Bones | Manutenção automática |
| **Blood Fountains** | Blood Essence | Opcional |

```
┌──────────────────┐
│  Central Supply  │
│  (Bones/Flowers) │
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│Brazier│ │Brazier│
│  #1   │ │  #2   │
└───────┘ └───────┘
    │         │
    └────┬────┘
         ▼
   ☀️ Protected ☀️
```

**Benefícios**:
- Base permanece **operacional** mesmo se o jogador esquecer de reabastecer
- Proteção solar **garantida** 24/7
- Menos micromanagement = mais diversão

---

### Configuração do KindredLogistics

Após primeira execução, um arquivo de config é criado em:
```
BepInEx/config/KindredLogistics.cfg
```

#### Opções Importantes

```ini
[General]
# Raio de busca para Quick Stash (em tiles)
QuickStashRadius = 50

# Habilitar crafting de containers
CraftFromContainers = true

# Habilitar auto-salvage
AutoSalvage = true

# Habilitar auto-refill de braziers
AutoRefillBraziers = true

[AutoSalvage]
# Nome do baú de dump (case insensitive)
DumpChestName = "DUMP"
# Delay entre operações (segundos)
SalvageInterval = 5.0

[AutoRefill]
# Recursos mínimos antes de reabastecer
MinBonesInBrazier = 10
RefillInterval = 30.0
```

---

### Comandos do KindredLogistics

| Comando | Descrição |
|---------|-----------|
| `.qs` ou `.quickstash` | Quick Stash - deposita itens em baús próximos |
| `.pull [item]` | Puxa item específico de baús próximos |
| `.sort` | Organiza inventário atual |
| `.logistics status` | Mostra status do sistema |
| `.logistics reload` | Recarrega configurações |

---

## KindredCommands

Framework de comandos administrativos para gerenciamento do servidor.

### Comandos Populares

| Comando | Descrição |
|---------|-----------|
| `.give [item] [qty]` | Dar item a jogador |
| `.tp [player]` | Teleportar para jogador |
| `.spawn [npc]` | Spawnar entidade |
| `.time [hour]` | Definir hora do dia |
| `.god` | Toggle god mode (admin) |

---

## Outros Mods Recomendados

### Quality of Life

| Mod | Descrição |
|-----|-----------|
| **ServerLaunchFix** | Corrige problemas de startup |
| **BloodyMerchant** | Merchants customizáveis |
| **CoffinSleep** | Pular tempo dormindo |
| **BloodRefill** | Refill automático de blood |

### PvP/Balance

| Mod | Descrição |
|-----|-----------|
| **BloodyBoss** | Bosses customizados |
| **PvPModes** | Modos PvP especiais |
| **RaidGuard** | Proteção de raid customizada |

### Admin/Server

| Mod | Descrição |
|-----|-----------|
| **VRising.GameData** | API de dados do jogo |
| **Wetstone** | Framework administrativo |
| **BloodyNotify** | Notificações customizadas |

---

## Compatibilidade ARM64

### Status de Compatibilidade

| Mod | ARM64 Status | Notas |
|-----|--------------|-------|
| KindredLogistics | ✅ Funciona | Requer BepInEx patched |
| KindredCommands | ✅ Funciona | Requer BepInEx patched |
| VampireCommandFramework | ✅ Funciona | - |
| Bloodstone | ✅ Funciona | - |

### Requisitos para ARM64

1. **Usar tsx-cloud/vrising-ntsync** ou Dockerfile com BepInEx patched
2. **Il2CppInterop modificado** (já incluído na imagem tsx-cloud)
3. **Box64 configurado** com dynarec otimizado

### Troubleshooting ARM64

```bash
# Verificar se BepInEx carregou
cat ./vrising/server/BepInEx/LogOutput.log | grep "Loading"

# Verificar erros
cat ./vrising/server/BepInEx/LogOutput.log | grep -i "error\|fail"

# Verificar plugins carregados
cat ./vrising/server/BepInEx/LogOutput.log | grep "Loaded plugin"
```

---

## 🔗 Links Úteis

### Downloads

- [Thunderstore - V Rising Mods](https://v-rising.thunderstore.io/)
- [KindredLogistics](https://v-rising.thunderstore.io/package/odjit/KindredLogistics/)
- [KindredCommands](https://v-rising.thunderstore.io/package/odjit/KindredCommands/)
- [VampireCommandFramework](https://v-rising.thunderstore.io/package/deca/VampireCommandFramework/)

### Documentação

- [BepInEx Docs](https://docs.bepinex.dev/)
- [V Rising Modding Discord](https://discord.gg/vrising)
- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)

---

## 📊 Resumo: O Castelo Industrial

Com **KindredLogistics**, seu castelo evolui de:

```
❌ ANTES: O Castelo Caótico
┌─────────────────────────────────────┐
│  🧛 Jogador gastando 30% do tempo   │
│     organizando inventário          │
│  📦 Baús desorganizados             │
│  🔥 Braziers apagando               │
│  🗑️ Lixo acumulando                 │
│  😤 Frustração alta                 │
└─────────────────────────────────────┘
```

Para:

```
✅ DEPOIS: O Castelo Industrial
┌─────────────────────────────────────┐
│  🧛 Jogador focado em GAMEPLAY      │
│  📦 Quick Stash = 1 comando         │
│  🔥 Auto-refill = sempre aceso      │
│  🗑️ Auto-salvage = zero lixo        │
│  🏭 Crafting from containers        │
│  😊 Experiência fluida              │
└─────────────────────────────────────┘
```

> **"O melhor sistema de automação é aquele que você esquece que existe."**
> 
> — Filosofia do KindredLogistics
