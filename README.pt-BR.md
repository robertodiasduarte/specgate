<!-- Idioma: [English](README.md) · **Português** -->

# SpecGate

> *Tradução do [README canônico em inglês](README.md). Em caso de divergência, o original vale.*

**Aceite executável, não prosa.**

SpecGate é um framework de desenvolvimento orientado a especificação para agentes de código.
O mecanismo que o distingue é uma linha de YAML que toda spec precisa carregar:

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/pricing.test.ts"
  pass_when: "exit 0"
```

Esse bloco não é documentação. O `scripts/verify-gate.sh` o executa, e `/build` e `/release`
tratam o exit code dele como bloqueante. O aceite deixa de ser um parágrafo que alguém lê na
diagonal e vira um comando que a máquina roda.

---

## Por que isto existe

Os frameworks de spec-driven development concordam sobre o fluxo — descrever o trabalho,
planejar, construir. Discordam sobre o que significa "pronto". Na maioria deles, pronto é
decidido lendo markdown e marcando checkbox: um humano (ou um agente) julga prosa contra prosa.

Isso funciona até você deixar um agente em loop. Um loop autônomo precisa de um critério de
parada com o qual ele não consiga discutir, e "a spec diz que o checkout deve ser rápido" não é
um. Sem gate executável, autonomia produz lixo em escala — o loop roda, mas contra o que ele para?

A resposta do SpecGate: **o critério de aceite é um comando com exit code.** Todo o resto do
framework existe para tornar esse comando confiável — uma gramática de requisitos para que os
critérios sejam testáveis, um protocolo de ambiguidade para que ninguém chute, e um veredito
graduado de release para que entregar com uma lacuna conhecida seja uma decisão registrada, e
não um silêncio.

Veja [docs/pt-BR/comparison.md](docs/pt-BR/comparison.md) para a comparação com Spec-Kit,
OpenSpec, BMAD, Kiro e Tessl, e para a relação com as práticas de Andrej Karpathy, Boris Cherny
e Peter Steinberger.

---

## Os cinco mecanismos

| Mecanismo | O que faz | Onde |
|---|---|---|
| **Verify Gate** | Aceite como comando executável, com contrato de exit de seis estados (`0/2/3/4/5/64`) — incluindo *inconclusivo* e *exige assinatura humana*, porque "vermelho ou verde" é mentira quando falta uma ferramenta ou o critério é estético | [`fragments/VERIFY_GATE.md`](.claude/sdd/templates/fragments/VERIFY_GATE.md) · [`scripts/verify-gate.sh`](scripts/verify-gate.sh) |
| **Gramática EARS** | Testes de aceite numa gramática restrita (When / While / If-Then / Where / shall). Cada padrão mapeia num tipo de teste, e o padrão de *comportamento indesejado* obriga a nomear o modo de falha antes de construí-lo | [`fragments/EARS.md`](.claude/sdd/templates/fragments/EARS.md) |
| **Protocolo de clarify** | Ambiguidade vira marcador na spec, nunca suposição silenciosa. Marcador ativo devolve exit `5` e para o pipeline — um estado distinto de falha, para que loops nunca "consertem" uma spec ambígua iterando o design | [`fragments/CLARIFY.md`](.claude/sdd/templates/fragments/CLARIFY.md) |
| **Veredito graduado** | Releases terminam em PASS / CONCERNS / FAIL / WAIVED. O waiver é só humano, restrito por classe e exige motivo escrito | [`commands/release.md`](.claude/commands/release.md) |
| **Contrato de review adversarial** | Um review de segundo vendor responde em formato fixo (veredito, ≤3 riscos ranqueados, fixes específicos, o que ignorar) e toda nota é aplicada ou rebatida por escrito — nunca descartada em silêncio | [`fragments/ADVISOR_CONSULT.md`](.claude/sdd/templates/fragments/ADVISOR_CONSULT.md) |

---

## Fluxo

```text
/brainstorm  →  /define  →  /design  →  /build  →  /release
  (opcional)      ↑          ↑           │            │
                  └──────────┴───────────┘            │
                   /iterate devolve correções         │
                                                      ▼
                    O Verify Gate roda aqui, e de novo aqui — bloqueante nas duas
```

`/ux-review` é um gate opcional entre `/define` e `/design` para trabalho com interface.
O `/build` também tem modos de autonomia opt-in (`--mode ralph`, `--mode briefs`) que usam o
Verify Gate como critério de parada.

---

## Instalação

SpecGate é arquivo, não pacote. Copie dois diretórios para o seu repositório:

```bash
git clone https://github.com/<owner>/specgate.git
cp -r specgate/.claude seu-projeto/
cp -r specgate/scripts seu-projeto/
cp specgate/sdd.config.example.yaml seu-projeto/sdd.config.yaml
```

Depois edite o `sdd.config.yaml` para apontar os slots (`{{TEST_CMD}}`, `{{DEPLOY_CMD}}`, …)
para os comandos reais do seu projeto. Os comandos referenciam esses slots — nada é hard-coded.

Passo a passo completo: [docs/pt-BR/quickstart.md](docs/pt-BR/quickstart.md) · adaptação à sua
stack: [docs/pt-BR/adaptation-guide.md](docs/pt-BR/adaptation-guide.md).

**Requisitos:** bash, git e o test runner que os seus gates chamarem. `gitleaks` só se você usar
o gate de publicação.

---

## Teste em dois minutos

```bash
# uma spec com ambiguidade em aberto para o pipeline (exit 5)
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_NEEDS_CLARIFICATION.md; echo "exit=$?"

# a mesma spec, ambiguidade resolvida (exit 0)
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CLARIFY_RESOLVED.md; echo "exit=$?"
```

Essas quatro fixtures são a suíte de regressão do próprio framework: elas fixam o contrato de
exits, então uma mudança no `verify-gate.sh` que o quebre falha alto.

---

## Status e procedência

O SpecGate nasceu de dois anos de uso diário em produção num codebase privado, e é publicado
como um snapshot curado — veja o [CONTRIBUTING.md](CONTRIBUTING.md) para o que isso significa
para issues e pull requests.

Começou como uma customização do [AgentSpec](https://github.com/luanmorenommaciel/agentspec),
de Luan Moreno Maciel (MIT). A estrutura de fases descende daquele trabalho; o Verify Gate, o
protocolo de clarify, o veredito graduado e o contrato de review são adições. Veja o
[NOTICE](NOTICE).

Licenciado sob a [licença MIT](LICENSE).
