<!-- Idioma: [English](../verify-gate-contract.md) · **Português** -->

# O contrato do Verify Gate

> *Tradução do [documento canônico em inglês](../verify-gate-contract.md). Em caso de divergência, o original vale.*

Referência completa do mecanismo que dá nome ao framework. O fragmento em
[`.claude/sdd/templates/fragments/VERIFY_GATE.md`](../../.claude/sdd/templates/fragments/VERIFY_GATE.md)
é a versão que os agentes leem; este documento explica o raciocínio por trás dela.

## O bloco

Toda spec carrega exatamente um bloco `yaml` cercado por fence sob um cabeçalho `## Verify Gate`:

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/pricing.test.ts"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

| Campo | Obrigatório | Significado |
|---|---|---|
| `kind` | sempre | `test` · `smoke` · `eval` · `typecheck` · `manual-ux` |
| `cmd` | exceto em `manual-ux` | o comando executável |
| `pass_when` | sempre | `exit 0` · `exit N` · `contains: TEXT` |
| `threshold` | só em `eval` | o alvo numérico, documentado para humanos; a imposição vive no `cmd` |
| `manual_fallback` | só em `manual-ux` | o checklist humano a percorrer e assinar |

O parser lê a primeira ocorrência de cada chave e pega tudo depois do primeiro dois-pontos — então
as linhas de valor não podem carregar comentários inline.

## Por que seis códigos de exit

Um pass/fail binário é uma mentira em três situações comuns, e cada mentira tem um custo.

**Uma ferramenta ausente não é uma falha (`3`).** Se o runner de testes não está instalado nesta
máquina, o código não está errado — você simplesmente não aprendeu nada. Retornar vermelho aqui
treina as pessoas a ignorar o vermelho. Retornar verde aqui envia código não testado. A resposta
honesta é um terceiro estado que o chamador precisa resolver.

**Ruído de infraestrutura não é uma regressão (`3`).** Um smoke test que recebe um 403 de um WAF
por causa do endereço IP do runner não diz nada sobre o seu endpoint. O gate detecta essa forma
específica — `kind: smoke`, um 403 na saída, e 403 não sendo o que você esperava — e retorna
inconclusivo com instruções para re-rodar a partir do host de origem.

**Alguma aceitação é genuinamente humana (`4`).** Se uma tela transmite sofisticação não é um
comando. A tentação é escrever um teste que passa tecnicamente e dar por encerrado. O `manual-ux`
recusa essa troca: retorna `4`, imprime o checklist e espera uma assinatura registrada no build
report.

E um estado que não é sobre o código de jeito nenhum:

**Uma pergunta não resolvida não é um build que falhou (`5`).** Esse é o mais sutil. Se a spec
ainda contém um marcador de ambiguidade ativo, o build não falhou — ele nunca deveria ter
começado. A distinção importa porque loops autônomos reagem ao vermelho iterando: dado um `2`, um
driver vai reescrever o design, sem parar, em cima de uma premissa que ninguém validou. O exit `5`
é um estado separado justamente pra que os loops parem em vez de iterar.

| exit | Estado | Obrigação do chamador |
|---|---|---|
| `0` | verde | prossiga |
| `2` | vermelho | **aborte**; conserte o código, ou itere a spec se o defeito estiver na spec |
| `3` | inconclusivo | resolva explicitamente; nunca registre como verde, nunca conte como vermelho |
| `4` | exige assinatura humana | mostre o `manual_fallback`, pare até o recibo ser registrado |
| `5` | esclarecimento pendente | **pare**, volte pro `/define`; nunca itere o design |
| `64` | bloco inválido ou ausente | a spec não é válida |

## O marcador de ambiguidade

Forma canônica ativa — a única que o scanner detecta, e apenas fora de code fences:

```
[NEEDS CLARIFICATION: <specific question>]
```

Toda referência a ele na documentação — em templates, fragmentos, exemplos — precisa ficar dentro
de um code fence ou largar os colchetes. Essa convenção existe porque a alternativa é um template
que bloqueia toda spec escrita a partir dele. O scanner remove os blocos cercados por fence
(inclusive fences aninhados em blockquotes) antes de buscar.

## Escolhendo um `kind`

Derive-o do padrão EARS do teste de aceite que ele impõe:

| Padrão EARS | Kind natural | Formato do teste |
|---|---|---|
| **When** (dirigido por evento) | `test` | dispare o evento, verifique a resposta |
| **If/Then** (indesejado) | `test` ou `smoke`, **negativo** | provoque o gatilho indesejado pelo caminho real |
| **While** (dirigido por estado) | `test` | monte a fixture do estado, verifique sob ele |
| **Where** (feature opcional) | `test` | rode com a flag ligada e desligada |
| **shall continue to** (não regressão) | `test` | um caso de regressão explícito |

Um teste negativo precisa passar pelo caminho real. Mockar a falha que você está testando prova
que o seu mock funciona.

## Antipadrões

| Nunca | Em vez disso |
|---|---|
| `cmd: "manually check that it works"` | Um comando, ou `kind: manual-ux` com um checklist de verdade |
| `kind: test` com cmd vazio ou `N/A` | Inválido — o gate retorna `64` |
| Marcar um critério de UX como `test` pra "passar tecnicamente" | Se o valor é percebido, é `manual-ux` |
| Tratar `3` como verde porque você está com pressa | Resolva, ou registre como não resolvido no report |
| Afrouxar o `pass_when` até passar | Isso é deletar o critério de aceite com passos extras |

## Testando o próprio gate

Quatro fixtures fixam o contrato:

```bash
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_NEEDS_CLARIFICATION.md  # 5
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CLARIFY_RESOLVED.md     # 0
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_TOKEN_IN_FENCE.md       # 0
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CONTROL.md              # 0
```

Rode essas depois de qualquer mudança no `verify-gate.sh`. A terceira — um marcador que aparece
apenas dentro de um fence — é a guarda contra falso positivo, e é a que quebra quando alguém
"simplifica" o tratamento de fences.
