# mri_Qmarkerplacer — Manual

Ferramenta de administração para criar, editar e posicionar markers 3D no mundo em runtime, com texto opcional, persistência em JSON e sincronização com todos os jogadores.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Comandos](#comandos)
5. [Menu de markers](#menu-de-markers)
6. [Modo de seleção com o mouse](#modo-de-seleção-com-o-mouse)
7. [Formato dos dados (`data.json`)](#formato-dos-dados-datajson)
8. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
9. [Localização](#localização)
10. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qb-core` | Sim | Declarado em `dependencies`; `exports['qb-core']:GetCoreObject()` e o evento `QBCore:Client:OnPlayerLoaded` |
| `ox_lib` | Sim | Declarado em `dependencies`; menus de contexto, input dialogs, callbacks, comando, locale, raycast e Text UI |

---

## Instalação

1. Copie a pasta `mri_Qmarkerplacer` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qmarkerplacer
   ```
3. Dê a um grupo ou jogador o principal `group.admin` — veja [Permissões (ACE)](#permissões-ace).

Os markers são gravados em `data.json`, na raiz do recurso, via `SaveResourceFile`. O arquivo já existe vazio (`[]`) e não precisa de banco de dados.

---

## Permissões (ACE)

O comando é registrado com `lib.addCommand(..., { restricted = 'group.admin' })`. O `ox_lib` cria a ACE `command.markermenu` e a libera para `group.admin` automaticamente — você só precisa colocar o administrador nesse grupo:

```
add_principal identifier.license:<licença_do_admin> group.admin
```

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/markermenu` | `group.admin` | Abre o menu de gerenciamento de markers |

---

## Menu de markers

O menu principal (`/markermenu`) lista todos os markers existentes e traz três ações no topo:

| Opção | O que faz |
|---|---|
| Selecionar tipo de marker | Entra no [modo de seleção com o mouse](#modo-de-seleção-com-o-mouse) |
| Criar novo marker | Abre o formulário direto na posição atual do personagem |
| Ativar/desativar debug | Desenha o ID de cada marker visível como texto 3D |

Ao abrir um marker da lista, o submenu oferece:

| Opção | O que faz |
|---|---|
| Teletransportar | Move o personagem para as coordenadas do marker |
| Editar marker | Reabre o formulário com os valores atuais |
| Renomear marker | Define o nome exibido na lista do menu |
| Texto do marker | Configura o texto 3D acima do marker: conteúdo, cor RGBA, tamanho, fonte, fundo e altura própria |
| Redefinir localização | Move o marker para a posição atual do personagem |
| Apagar marker | Remove o marker da lista |

Toda alteração é sincronizada com **todos os clientes** na hora e salva em `data.json`. Não é preciso reiniciar o recurso.

---

## Modo de seleção com o mouse

Um raycast a partir da câmera mostra uma prévia do marker onde você está mirando. Os controles são:

| Tecla | Ação |
|---|---|
| Scroll | Muda o tipo do marker (0 a 43) |
| Shift + Scroll | Aumenta/diminui a escala (mínimo 0.1) |
| Q | Abaixa o marker (−0.01 por frame) |
| E | Levanta o marker (+0.01 por frame) |
| Enter | Confirma e abre o formulário de criação |
| Esc | Cancela e volta ao menu |

---

## Formato dos dados (`data.json`)

Cada marker é um objeto do array. Os campos abaixo são os gravados pelo formulário:

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `marker` | number | Sim | Tipo do marker (0 a 43), usado em `DrawMarker` |
| `vector` | objeto `{x,y,z}` | Sim | Posição do marker |
| `scale` | number | Sim | Escala aplicada nos três eixos |
| `r`, `g`, `b` | number | Sim | Cor do marker (0-255) |
| `alpha` | number | Sim | Opacidade. Fixada em `255` na criação |
| `bobUpAndDown` | bool | Sim | Faz o marker flutuar para cima e para baixo |
| `faceCamera` | bool | Sim | Mantém o marker virado para a câmera |
| `rotate` | bool | Sim | Gira o marker no próprio eixo |
| `range` | number | Sim | Distância máxima (em metros) em que o marker é desenhado |
| `show` | bool | Sim | Se `false`, o marker não é desenhado para ninguém |
| `name` | string | Não | Nome exibido na lista do menu. Definido em "Renomear marker" |
| `text` | string | Não | Texto 3D desenhado 1 metro acima do marker |
| `textcolor` | objeto `{r,g,b,a}` | Não | Cor do texto |
| `textsize` | number | Não | Escala do texto (0.01 a 0.99) |
| `textfont` | number | Não | Fonte: `0` London 1960, `1` House Script, `2` House Script 2, `3` Slab Serif, `4` Cologne 1960, `7` Pricedown |
| `togglerect` | bool | Não | Desenha um retângulo escuro atrás do texto |
| `textvectorz` | number | Não | Altura própria do texto, independente do Z do marker |

---

## Entrypoints para outros recursos

### Callbacks de servidor

Registrados via `lib.callback.register`:

```lua
-- adiciona um marker e sincroniza com todos os clientes
lib.callback.await('markerplacer:addMarker', false, markerData)

-- substitui a lista inteira de markers e sincroniza
lib.callback.await('markerplacer:syncMarkers', false, markers)

-- pede a lista atual; o servidor responde com markerplacer:receiveMarkers
lib.callback.await('markerplacer:requestMarkers', false)
```

Os três são **irrestritos**: qualquer cliente pode chamá-los. Só o comando `/markermenu` é protegido por ACE.

### Evento `markerplacer:receiveMarkers` (cliente)

Entrega a lista completa de markers ao cliente.

```lua
TriggerClientEvent('markerplacer:receiveMarkers', source, markers)
```

### Evento `markerplacer:showMainMenu` (cliente)

Abre o menu de markers no cliente. É o que o `/markermenu` dispara.

```lua
TriggerClientEvent('markerplacer:showMainMenu', source)
```

---

## Localização

As strings do menu e dos formulários passam pelo locale do `ox_lib`. Os arquivos ficam em `locales/`:

- `en.json` — inglês
- `pt-br.json` — português do Brasil

O idioma ativo vem da convar do `ox_lib`:

```
setr ox:locale "pt-br"
```

Para adicionar um idioma, crie `locales/<codigo>.json` com as mesmas chaves e reinicie o recurso.

---

## Estrutura de arquivos

```
mri_Qmarkerplacer/
├── client.lua        — menus de contexto, formulários, modo de seleção por raycast, desenho dos markers e do texto 3D
├── server.lua        — carrega/salva data.json, callbacks de CRUD, sync com todos os clientes, comando /markermenu
├── data.json         — lista de markers (fonte da verdade, escrita em runtime)
├── locales/
│   ├── en.json
│   └── pt-br.json
└── fxmanifest.lua
```
