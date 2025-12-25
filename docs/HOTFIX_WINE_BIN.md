# HOTFIX FINAL - Wine Binary Detection

## Problema Real Identificado

O script de detecção do Wine estava encontrando o **arquivo .so da biblioteca** ao invés do **executável**:

```bash
# ERRADO - Encontrava isto primeiro:
/opt/wine/lib/wine/x86_64-unix/wine64  # <- Arquivo .so (biblioteca)

# CORRETO - Deveria encontrar isto:
/opt/wine/bin/wine                      # <- Executável real
```

## Fix Aplicado

**Dockerfile linha 225-228:**
```dockerfile
# ANTES (quebrado):
WINE_BIN_PATH=$(find ${WINE_PATH} -name "wine64" -type f 2>/dev/null | head -1)

# DEPOIS (corrigido):
WINE_BIN_PATH=$(find ${WINE_PATH}/bin -name "wine64" -o -name "wine" 2>/dev/null | grep -v "\.so" | head -1)
```

**Mudanças:**
1. ✅ Busca APENAS em `${WINE_PATH}/bin`
2. ✅ Exclui arquivos `.so` com `grep -v "\.so"`
3. ✅ Busca `wine64` OU `wine` (o que existir)

## Deploy no Easypanel

### Via Easypanel Web UI:
1. Acesse o painel Easypanel
2. Vá em "Projects" → "luan" → "vrising"
3. Clique em "Rebuild" ou "Redeploy"
4. Aguarde o rebuild (20-40 min)

### Via Docker CLI no Servidor:
```bash
# 1. Copie o Dockerfile atualizado para o servidor
scp Dockerfile root@servidor:/caminho/do/projeto/

# 2. Rebuild manual
cd /caminho/do/projeto
docker build -t easypanel/luan/vrising:latest .

# 3. Restart via Easypanel
# (use a UI do Easypanel para restart)
```

## Verificação Pós-Deploy

```bash
# 1. Checar wrapper corrigido
docker run --rm easypanel/luan/vrising:latest cat /usr/local/bin/wine

# Deve mostrar:
# exec box64 /opt/wine/bin/wine "$@"
# NÃO: exec box64 /opt/wine/lib/wine/x86_64-unix/wine64 "$@"

# 2. Testar Wine
docker run --rm --entrypoint /bin/bash easypanel/luan/vrising:latest -c "wine --version"

# Deve mostrar: wine-11.0-rc3
# NÃO: wine: could not load ntdll.so

# 3. Ver logs do container
docker logs $(docker ps | grep vrising | awk '{print $1}') 2>&1 | tail -50
```

## Expected Build Output

Durante o rebuild, você deve ver:

```
=== Looking for wine binaries ===
/opt/wine/bin/wine
/opt/wine/bin/wineserver
/opt/wine/bin/winegcc
...
Found wine binary at: /opt/wine/bin/wine    ← BIN, não LIB!
Wine bin directory: /opt/wine/bin
Wine lib directories:
  Unix libs: /opt/wine/lib/wine/x86_64-unix
  Base libs: /opt/wine/lib/wine
Wine 11.0-rc3 installed and wrappers created successfully
```

## Status

- ✅ Root cause identificado
- ✅ Fix aplicado no Dockerfile
- ⏳ **Aguardando rebuild no Easypanel**

## Próximos Passos

1. Deploy via Easypanel UI
2. Aguardar 20-40 min de rebuild
3. Verificar logs não mostram erro de ntdll.so
4. Servidor deve iniciar corretamente
