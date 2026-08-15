<!-- Idioma: [English](../quickstart.md) · **Português** -->

# Quickstart

> *Tradução do [documento canônico em inglês](../quickstart.md). Em caso de divergência, o original vale.*

Do zero a um gate bloqueante em cerca de dez minutos.

## 0. Você precisa mesmo do fluxo completo?

Seja honesto sobre a mudança que está na sua frente:

| A mudança é… | Faça isto |
|---|---|
| Descritível em uma frase, raio de impacto pequeno | Pule as fases. Converse com o modelo, rode seus testes. |
| Correção de bug com causa conhecida | `/define` (uma spec de bug-fix precisa de pelo menos um `shall continue to`) e depois `/build`. |
| Comportamento novo, vários arquivos, ou caro de errar | O fluxo completo abaixo. |

Um framework que se declara o único caminho está mentindo pra você. Use as fases onde errar
é caro.

## 1. Instalação

```bash
git clone https://github.com/<owner>/specgate.git /tmp/specgate
cp -r /tmp/specgate/.claude your-project/
cp -r /tmp/specgate/scripts your-project/
cp /tmp/specgate/sdd.config.example.yaml your-project/sdd.config.yaml
```

Nada é registrado, compilado ou instalado — são instruções em markdown e scripts bash.
Um requisito: rode os scripts **de dentro de um repositório git** (o gate resolve paths a partir
da raiz do repo; fora de um, ele sai com `64`).

## 2. Aponte os slots para o seu projeto

Edite o `sdd.config.yaml`:

```yaml
project:
  name: your-project
  test_cmd: "npm test"
  typecheck_cmd: "tsc --noEmit"
deploy:
  cmd: "./deploy.sh production"
release:
  landmines_cmd: "bash scripts/release-landmines.sh"
```

Os comandos referenciam esses slots em vez de fixar qualquer coisa no código, e é isso que torna
o framework portátil entre stacks.

## 3. Verifique a instalação

```bash
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CONTROL.md;              echo "exit=$?"  # 0
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_NEEDS_CLARIFICATION.md;  echo "exit=$?"  # 5
```

Obter `0` e `5` significa que o runner do gate e o contrato de exit funcionam. Se o segundo
retornar `0`, a detecção de ambiguidade está quebrada — não prossiga, porque premissas silenciosas
são exatamente o que ela existe pra pegar.

## 4. Escreva sua primeira spec

```
/define Add a discount code field to the checkout form
```

O comando vai te confrontar de três maneiras, todas deliberadas:

**Ele escreve testes de aceite em EARS.** Não "o desconto deveria funcionar", e sim:

> **When** um cliente envia um código de desconto válido, o sistema **shall** recalcular o total
> do pedido e exibir o valor com desconto antes do pagamento.
>
> **If** o código de desconto estiver expirado, **then** o sistema **shall** manter o total
> original e mostrar o motivo inline.

O segundo é o padrão de *comportamento indesejado*, e o `/define` vai recusar uma spec que tenha
um modo de falha plausível sem um deles. Essa é a classe de bug que mais escapa do review.

**Ele marca a ambiguidade em vez de chutar.** Se não conseguir dizer se os códigos são
cumulativos, ele planta um marcador e pergunta pra você — no máximo cinco perguntas de múltipla
escolha por rodada. Até você responder, o gate retorna exit `5` e o pipeline fica parado.

**Ele exige um gate executável.** A spec não é salva sem um:

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/discount.test.ts"
  pass_when: "exit 0"
```

## 5. Design, build, release

```
/design .claude/sdd/features/DEFINE_DISCOUNT_CODES.md   # architecture, decisions, file manifest
/build  .claude/sdd/features/DESIGN_DISCOUNT_CODES.md   # code, then the gate — blocking
/release "discount codes at checkout"                    # graded verdict, one human approval
```

O `/build` não vai declarar sucesso com o gate em `2` (vermelho) nem com `3` (inconclusivo) não
resolvido. O `/release` termina em PASS (aprovado), CONCERNS (com ressalvas), FAIL (reprovado) ou
WAIVED (dispensado) — e uma dispensa exige um motivo escrito por um humano, nunca pelo agente.

## O contrato de exit, de uma vez

| exit | Significado | O que o chamador faz |
|---|---|---|
| `0` | verde | prossiga |
| `2` | vermelho | aborte |
| `3` | inconclusivo (ferramenta ausente, ruído de infra) | resolva explicitamente; nunca conta como vermelho |
| `4` | manual-ux: precisa de assinatura humana | mostre o checklist, aguarde o recibo |
| `5` | há um marcador de ambiguidade ainda ativo | pare, volte pro `/define` — nunca itere o design |
| `64` | o bloco do gate está ausente ou malformado | a spec é inválida |

A distinção entre `2` e `5` é a que as pessoas deixam passar: um gate vermelho significa que o
código está errado, enquanto `5` significa que a *pergunta* está errada. Loops que tratam os dois
igual vão iterar alegremente um design construído sobre uma premissa não validada.

## A seguir

- [Guia de adaptação](adaptation-guide.md) — encaixar isto na sua stack, CI e time
- [Contrato do Verify Gate](verify-gate-contract.md) — a referência completa
- [Comparação](comparison.md) — como isto difere de outros frameworks
