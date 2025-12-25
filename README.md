# V Rising ARM64 Server

Servidor V Rising dedicado otimizado para ARM64 (Oracle Ampere) com suporte a BepInEx.

## 🚀 Quick Start

### Usando Docker Compose (Desenvolvimento Local)

```bash
docker compose -f docker-compose.easypanel.yml up -d
```

### Usando EasyPanel (Produção)

Consulte a documentação completa em:
- [📖 Deep Research - EasyPanel ARM64](docs/DEEP_RESEARCH_EASYPANEL_ARM64.md)

## 📁 Estrutura

```
vrising-emu/
├── docker-compose.easypanel.yml   # Config Docker para EasyPanel
├── .env.example                   # Template de variáveis de ambiente
├── config/
│   ├── ServerHostSettings.json    # Configurações do host
│   └── ServerGameSettings.json    # Configurações de gameplay
├── docs/
│   └── DEEP_RESEARCH_EASYPANEL_ARM64.md  # Documentação completa
└── vrising/                       # (criado no runtime)
    ├── server/                    # Arquivos do servidor
    └── persistentdata/            # Saves e configs
```

## 🔧 Requisitos

- **CPU**: ARM64 (Oracle Ampere, Raspberry Pi 5, etc.)
- **RAM**: Mínimo 16GB, Recomendado 24GB
- **Disco**: Mínimo 15GB
- **Docker**: 20.10+
- **EasyPanel**: Qualquer versão recente

## 📚 Documentação

- [Deep Research - EasyPanel ARM64](docs/DEEP_RESEARCH_EASYPANEL_ARM64.md)
- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)
- [Box64 Documentation](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)

## 🛠️ Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `TZ` | Timezone | `UTC` |
| `SERVERNAME` | Nome do servidor | `VRising` |
| `ENABLE_PLUGINS` | Habilitar BepInEx | `false` |

Veja `.env.example` para lista completa.

## 📝 Licença

MIT

## 🙏 Agradecimentos

- [tsx-cloud](https://github.com/tsx-cloud) - Imagem Docker ARM64
- [TrueOsiris](https://github.com/TrueOsiris) - Docker original
- [ptitSeb](https://github.com/ptitSeb) - Box64/Box86
- [Kron4ek](https://github.com/Kron4ek) - Wine Builds
