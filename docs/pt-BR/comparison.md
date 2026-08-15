<!-- Idioma: [English](../comparison.md) · **Português** -->

# Como o SpecGate se compara

> *Tradução do [documento canônico em inglês](../comparison.md). Em caso de divergência, o original vale.*

*Panorama revisado em agosto de 2026. Contagens de estrelas e versões são de um ponto no tempo; as
capacidades mudam. Onde este documento estiver errado sobre outro projeto, está errado por acidente
— correções são bem-vindas.*

Esta não é uma página de "por que somos melhores". Os frameworks abaixo resolvem problemas reais e
os resolvem bem, e três deles são muito mais adotados que este. O propósito aqui é declarar com
precisão o que o SpecGate faz de diferente, pra você conseguir dizer se essa diferença importa pro
seu trabalho.

---

## A diferença em uma linha

**Todo framework spec-driven produz uma spec. O SpecGate faz a spec carregar um comando que decide
se o trabalho está pronto.**

No Spec-Kit, OpenSpec, BMAD, Kiro e Tessl, o aceite é avaliado por leitura: um humano ou um agente
compara a implementação com critérios escritos e marca um checkbox. No SpecGate, o aceite é um
bloco `verify_gate` que o `scripts/verify-gate.sh` executa, devolvendo um de seis códigos de exit
que o `/build` e o `/release` são contratualmente obrigados a honrar.

Essa única mudança é o que torna o resto coerente, e vale ser honesto sobre o custo: escrever um
critério executável é mais difícil que escrever uma frase. Se o seu aceite genuinamente não pode
ser expresso como um comando — um julgamento visual, uma decisão de tom de voz — o SpecGate não
finge o contrário; ele tem um kind `manual-ux` que retorna exit `4` e exige uma assinatura humana
em vez de simular automação.

---

## Comparação de capacidades

| Capacidade | Spec-Kit | OpenSpec | BMAD | Kiro | Tessl | **SpecGate** |
|---|---|---|---|---|---|---|
| Fluxo estruturado spec → plano → build | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Gate de aceite executável** | ❌ review | ❌ review | ❌ review | ❌ review | ❌ review | ✅ comando + contrato de exit |
| Gramática de requisitos (EARS) | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ (adotada do Kiro) |
| Marcador de ambiguidade com parada mecânica | ✅ marcador | ❌ | ❌ | ❌ | ❌ | ✅ marcador **+ estado de exit dedicado** |
| Veredito de release graduado | ❌ | ❌ | ✅ (test architect) | ❌ | ❌ | ✅ + taxonomia de dispensa |
| Reconciliação spec ↔ código após o build | ✅ `/analyze` | ✅ diffs | ⚠️ parcial | ⚠️ parcial | ✅ | ❌ *(planejado)* |
| Specs como deltas contra um conjunto canônico | ❌ | ✅ | ❌ | ❌ | ⚠️ | ❌ *(em avaliação)* |
| Independente de editor/IDE | ✅ | ✅ | ✅ | ❌ (IDE próprio) | ⚠️ | ✅ |
| Adoção | ~129k★ | ~65k★ | ~52k★ | vendor | vendor | novo |

**Leia as duas últimas linhas juntas.** O SpecGate é novo e não tem comunidade; o Spec-Kit tem uma
grande. Se você quer um framework com contribuidores, plugins e issues respondidas, use o
Spec-Kit. Se você quer o mecanismo do gate, pegue daqui — são aproximadamente 200 linhas de bash e
você pode portar pra qualquer coisa que você já rode.

### Onde os outros estão à frente

- **O specs-as-diffs do OpenSpec** resolve um problema que o SpecGate não resolveu: quando muitas
  branches rodam em paralelo, cada uma carregando uma spec inteira, a verdade canônica desliza.
  Deltas contra um conjunto canônico de capacidades são uma resposta melhor que documentos de vida
  longa. Isso está no roadmap aqui.
- **O `/analyze` do Spec-Kit** confere cobertura bidirecional — todo requisito tem uma tarefa, toda
  tarefa remete a um requisito. O SpecGate ainda não tem equivalente, o que é uma lacuna real: o
  gate dele prova que o *aceite* passou, não que o manifest *cobriu* todos os requisitos.
- **O test architect do BMAD** originou o veredito graduado adotado aqui. O BMAD também carrega um
  modelo multi-persona do qual a própria v6 recuou por questão de custo — um resultado negativo
  útil.
- **O Kiro** inventou a integração com EARS que este framework toma emprestada. O custo dele é
  lock-in de IDE.

---

## Alinhamento com praticantes

As três pessoas abaixo não desenharam este framework, e nenhuma delas o endossou. As posições
publicadas por elas são citadas porque o SpecGate é, em grande parte, uma tentativa de tornar o
conselho delas mecânico em vez de aspiracional.

### Boris Cherny — verificação é a alavanca máxima

A posição de Cherny, tirada das best practices do Claude Code e das notas públicas dele, é que dar
a um agente uma forma de **verificar o próprio trabalho** é a intervenção de maior alavancagem que
existe, valendo um múltiplo em qualidade de saída; e que um revisor adversarial numa sessão nova
pega o que o contexto do autor não consegue pegar.

*O que o SpecGate faz com isso:* o Verify Gate é essa verificação tornada obrigatória e lida por
máquina — não uma sugestão de "adicione testes", mas um bloco que a spec não pode omitir (um gate
ausente ou malformado é exit `64`, uma spec inválida). O review adversarial é formalizado no
[`ADVISOR_CONSULT.md`](../../.claude/sdd/templates/fragments/ADVISOR_CONSULT.md): um formato de
resposta fixo, limitado a três riscos ranqueados, mais um ledger onde toda observação precisa ser
APPLIED (aplicada) ou REBUTTED (refutada) por escrito.

### Andrej Karpathy — engenharia agêntica em vez de vibe coding

O enquadramento de Karpathy distingue prompting casual de **engenharia agêntica**: manter um humano
no "controle deslizante de autonomia", exigir que premissas apareçam como perguntas, insistir em
simplicidade e mudanças cirúrgicas, e definir critérios verificáveis antes de escrever código. O
resumo dele de que o *harness* importa mais que o modelo é a premissa deste repositório inteiro.

*O que o SpecGate faz com isso:* esses pontos são cinco diretrizes inegociáveis no prompt do agente
de build — uma premissa vira uma pergunta, nada que não foi pedido é construído, as mudanças ficam
cirúrgicas, os critérios vêm antes do código, e evidência (uma saída de comando colada) substitui a
frase "implementado com sucesso". O controle deslizante de autonomia é explícito: o `/build` roda
in-context por default, `--mode ralph` por tarefa num contexto novo, `--mode briefs` em paralelo —
e o modo é sempre uma decisão humana, nunca inferida.

### Peter Steinberger — a maior parte do trabalho não precisa de cerimônia

Steinberger defende o oposto do que um autor de framework quer ouvir: para raio de impacto pequeno,
**apenas converse com o modelo**. Cerimônia é overhead, e verificação por comportamento observável
ganha de processo.

*O que o SpecGate faz com isso:* toma isso como restrição, não como refutação. Um framework que se
declara o único caminho está errado, então a orientação honesta está no
[docs/quickstart.md](quickstart.md): se a mudança é descritível em uma frase e o raio de impacto
dela é pequeno, pule as fases. O gate ainda ajuda ali — como um comando de uma linha, não como um
documento. O SpecGate é pra trabalho onde errar é caro; sobre todo o resto, Steinberger tem razão.

---

## Quando NÃO usar isto

- **Trabalho solo, pequeno, descartável.** As fases custam mais do que devolvem. Converse com o
  modelo.
- **Você precisa de um ecossistema hoje.** Sem plugins, sem comunidade, só releases curados.
- **Seu aceite é inerentemente visual.** Você pode usar `manual-ux`, mas aí o que você ganha é um
  checklist disciplinado, não automação — decida se isso vale o framework.
- **Você já tem um gate forte.** Se o seu CI bloqueia merges com base em testes significativos,
  você já tem o mecanismo. Pegue o protocolo de clarify e a gramática EARS e pule o resto.

---

## Fontes

- Spec-Kit — <https://github.com/github/spec-kit> · <https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/>
- OpenSpec — <https://github.com/Fission-AI/OpenSpec>
- BMAD-METHOD — <https://github.com/bmad-code-org/BMAD-METHOD>
- Kiro (specs, EARS) — <https://kiro.dev/docs/specs/> · EARS — <https://alistairmavin.com/ears/>
- Tessl — <https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry>
- Boris Cherny — <https://code.claude.com/docs/en/best-practices> · <https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny>
- Andrej Karpathy — <https://www.latent.space/p/s3>
- Peter Steinberger — <https://steipete.me/posts/just-talk-to-it>
