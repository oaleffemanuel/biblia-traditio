# Biblia Traditio

Aplicativo Flutter de leitura bíblica, liturgia, plano de leitura,
comentários patrísticos e biblioteca temática.

## Executar localmente

Pré-requisitos: Flutter instalado e um dispositivo físico, simulador iOS ou
emulador Android disponível.

```bash
cd ~/workspace/biblia-traditio
flutter pub get
flutter devices
flutter run -d <device-id>
```

No macOS, abra o Simulator pelo Xcode ou com `open -a Simulator`, aguarde o
dispositivo aparecer em `flutter devices` e então use o comando acima. Também é
possível usar um aparelho Android com depuração USB ativada.

O primeiro início pode demorar e consumir espaço porque o app instala os
pacotes bíblicos locais e, quando disponível, os comentários patrísticos.

## Verificações

```bash
flutter test
flutter analyze
./tool/check_release.sh
```

O tour visual de telas exige um dispositivo:

```bash
flutter test integration_test/screens_tour_test.dart -d <device-id>
```

## Conteúdo e licenças

O texto e os comentários são pacotes locais, descritos em
`assets/packages/manifest.json`. A tela de licenças do app deve ser conferida
antes de qualquer distribuição.

O pacote atual contém traduções beta cuja origem/licença ainda não está
confirmada (`pt_beta` e `pt_matos_soares`). Por isso,
`./tool/check_release.sh` bloqueia uma publicação sem `BETA=1`. Esse bloqueio é
intencional: não distribuir essas traduções publicamente até confirmar a cadeia
de direitos ou substituí-las por conteúdo autorizado.

Para adicionar CNBB, Peregrino, Navarra ou outra tradução, obtenha autorização
escrita para distribuição offline no aplicativo, incluindo texto integral,
território, uso comercial, atualizações, atribuição e prazo. A licença de um
livro ou de uma edição impressa não autoriza automaticamente copiar o texto
para um app.

## Pipeline de conteúdo

O importador offline fica em `tool/importer/`. O script
`tool/build_content_db.sh` gera os pacotes SQLite locais a partir das fontes
indicadas no próprio script. Não inclua bancos de usuário, credenciais ou fontes
sem licença no pacote de distribuição.
