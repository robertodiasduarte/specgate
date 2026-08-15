<!-- Idioma: [English](../adaptation-guide.md) · **Português** -->

# Guia de adaptação

> *Tradução do [documento canônico em inglês](../adaptation-guide.md). Em caso de divergência, o original vale.*

O SpecGate foi extraído de um único codebase de produção. Este documento marca as costuras — o que
é genérico, o que você precisa configurar, e o que foi deliberadamente deixado de fora por ser
específico de onde ele veio.

## O que você precisa configurar

Tudo que é específico do projeto vive no `sdd.config.yaml`. Os comandos referenciam slots; eles
nunca fixam um comando no código.

```yaml
project:
  name: your-project
  test_cmd: "npm test"              # {{TEST_CMD}}
  typecheck_cmd: "tsc --noEmit"     # {{TYPECHECK_CMD}}

deploy:
  cmd: "./deploy.sh production"     # {{DEPLOY_CMD}}
  drift_check_cmd: ""               # {{DRIFT_CHECK_CMD}} — see "drift" below

release:
  landmines_cmd: "bash scripts/release-landmines.sh"   # {{LANDMINES_CMD}}
  changelog_hook: ""                # {{CHANGELOG_HOOK}}

prompts:
  builder_skill: ""                 # your prompt-engineering skill, if you have one
```

## O ponto de extensão que mais importa: landmines

O [`scripts/release-landmines.sh`](../../scripts/release-landmines.sh) vem como um **mecanismo com
três regras genéricas** — um segredo literal em arquivo versionado, uma migration aplicada fora de
banda sem commit correspondente, e uma árvore de trabalho suja na hora do release.

Esse vazio é deliberado. No codebase de onde isto veio, aquele script carrega dezenas de regras, e
cada uma delas é uma cicatriz: uma queda específica, uma falha silenciosa específica, uma
descoberta específica às 2h da manhã. Essas regras não valem nada pra você — elas nomeiam tabelas,
fornecedores e funções internas que você não tem — e publicá-las teria sido um inventário dos
pontos fracos de um sistema privado.

**O que se transfere é o hábito:** depois de cada incidente, codifique a detecção como um grep e
adicione na sua cópia. A estrutura do script suporta isso diretamente:

```bash
crit "secret literal in tracked file" \
  "$(diff_added | grep -nE '(sk-[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY)')"

warn "migration applied out of band has no matching commit" \
  "$(your_check_here)"
```

`crit` bloqueia o release, `warn` faz aparecer no veredito, `info` registra. Um framework não pode
entregar os seus post-mortems; pode entregar o lugar onde colocá-los.

## Drift: coisas deployadas fora do git

Se o seu projeto consegue deployar sem um commit — uma função serverless publicada por um console,
uma migration aplicada por um dashboard, uma config alterada numa UI — então o seu repositório pode
silenciosamente deixar de descrever o que está rodando. É pra esse modo de falha que o
`{{DRIFT_CHECK_CMD}}` existe.

Se tudo que você deploya passa pelo git, deixe vazio. Se não, escreva uma checagem que compare o
que está deployado com o que está commitado, e ligue ela ali. O fluxo de release vai executá-la na
fase de pré-voo.

## Trabalho paralelo: worktrees

O fluxo assume que uma feature é desenvolvida numa branch a partir da branch default, e funciona
bem com `git worktree` quando várias features rodam ao mesmo tempo. O framework não exige
worktrees — ele exige que você não desenvolva na branch de onde você deploya.

Uma ressalva que vale internalizar se você adotar paralelismo pesado: com muitas worktrees vivas ao
mesmo tempo, as specs de cada uma descrevem futuros divergentes, e a verdade canônica fica
borrada. Essa é uma limitação real do framework hoje (veja [comparison.md](comparison.md) — o
specs-as-diffs do OpenSpec é uma resposta melhor, e está no roadmap).

## Agentes e modelos

O framework é agnóstico de modelo em princípio, com duas ressalvas práticas:

- **`/build --mode briefs` assume que existe um modelo barato** para workers paralelos, e exclui
  dele, por regra dura, itens de superfície de segurança e de prompt-engineering. Se você não tem
  uma estratégia de tiering, ignore esse modo; o loop in-context default é o caminho recomendado.
- **O review adversarial assume um segundo fornecedor.** O valor dele vem de um perfil de erro não
  correlacionado — uma família de modelo diferente revisando o trabalho da primeira. Revisar com o
  mesmo modelo que escreveu o código te dá concordância, não review.

Nomes de modelo estão deliberadamente ausentes dos arquivos entregues: eles envelhecem mal. Coloque
os seus no `sdd.config.yaml`.

## O que ficou de fora, e por quê

| Deixado de fora | Por quê |
|---|---|
| Regras concretas de landmine | Cada uma documenta um incidente privado específico; inútil em outro lugar, imprudente de publicar |
| Skills de domínio (importação de dados, consulta de cadastro, fluxos de publicação) | Regra de negócio de um produto, não framework |
| Convenções da camada de memória/conhecimento | Uma camada privada de fatos acumulados do projeto; o framework não depende dela |
| Pipeline de deploy, ligação com CI, configuração de host | O seu vai diferir em cada detalhe |
| Skills de prompt-engineering | Referenciadas como um slot configurável; os comandos chamam o que você plugar |

## Encaixando no CI

A integração mínima útil é rodar o gate da spec que um pull request implementa:

```yaml
- run: scripts/verify-gate.sh .claude/sdd/features/DEFINE_${{ env.FEATURE }}.md
```

Trate os exits `3` e `4` deliberadamente: `3` significa que falta algo no runner do CI (muitas
vezes é correto ignorar no CI e resolver localmente), `4` significa que um humano precisa assinar —
o que um job de CI não pode fazer por você. Mapear qualquer um dos dois para verde derrota o
mecanismo.
