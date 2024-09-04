# mri_Qmarkerplacer

## Descrição

O **mri_Qmarkerplacer** é um sistema de gerenciamento de markers para o FiveM, permitindo que administradores criem, editem e gerenciem markers no jogo. Este recurso foi desenvolvido para ser integrado ao framework QBCore e oferece suporte completo à localização, tornando-o acessível para várias comunidades ao redor do mundo.

## Funcionalidades

- Criação e edição de markers diretamente no jogo.
- Suporte a múltiplos tipos de markers.
- Sincronização automática de markers entre todos os jogadores no servidor.
- Interface intuitiva para criação e gerenciamento de markers.
- Suporte a cores personalizadas para markers.
- Integração total com o framework QBCore.
- Suporte à localização (locales) para facilitar a tradução para diferentes idiomas.

## Requisitos

- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)

## Instalação

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/SeuUsuario/mri_Qmarkerplacer.git
   ```

2. **Adicione o recurso à sua pasta `resources`:**
   Copie a pasta `mri_Qmarkerplacer` para a sua pasta `resources` no servidor FiveM.

3. **Adicione o recurso ao `server.cfg`:**
   No arquivo `server.cfg`, adicione a linha abaixo para garantir que o recurso seja carregado:
   ```bash
   ensure mri_Qmarkerplacer
   ```

4. **Dependências:**
   Certifique-se de que as dependências `ox_lib` e `qb-core` estejam instaladas e funcionando corretamente no seu servidor.

## Uso

- Use o comando `/markermenu` no chat do jogo para abrir o menu de gerenciamento de markers.
- Crie novos markers usando a interface amigável ou edite markers existentes.

## Localização

O **mri_Qmarkerplacer** inclui suporte para múltiplos idiomas. Atualmente, os seguintes idiomas são suportados:

- **Inglês** (`locales/en.json`)
- **Português (Brasil)** (`locales/pt-br.json`)

Se desejar adicionar mais idiomas, basta criar um novo arquivo JSON na pasta `locales` e segui o formato dos arquivos existentes.

## Contribuições

Contribuições são bem-vindas! Se você deseja contribuir com melhorias, por favor, siga os passos abaixo:

1. Faça um fork do repositório.
2. Crie uma branch para a sua feature ou correção: `git checkout -b minha-feature`.
3. Faça o commit das suas alterações: `git commit -m 'Adicionei uma nova feature'`.
4. Envie as alterações para o repositório remoto: `git push origin minha-feature`.
5. Abra um Pull Request no repositório original.

## Licença

Este projeto está licenciado sob a licença [MIT](https://opensource.org/licenses/MIT).

## Autor

Desenvolvido por **Murai** para a comunidade **MRI Qbox Brasil**. Se você tem alguma dúvida ou deseja contribuir, sinta-se à vontade para entrar em contato!

---

Aproveite o recurso e ajude a melhorar a experiência de roleplay no FiveM!