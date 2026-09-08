# Núcleo de um Coprocessador Gráfico em FPGA - DE1-SoC

MI - Sistemas Digitais (2026.2) - Problema #1
Universidade Estadual de Feira de Santana (UEFS), Departamento de Tecnologia, Área de Eletrônica

## Sobre o projeto

Este repositório contém o núcleo de um coprocessador gráfico em Verilog, desenvolvido para a placa **Terasic DE1-SoC** (FPGA Intel/Altera Cyclone V, modelo `5CSEMA5F31C6`), inspirado na arquitetura de consoles de 16 bits. O núcleo gera continuamente um sinal de vídeo VGA a partir de três camadas gráficas, plano de fundo baseado em *tiles*, *sprites* e polígonos rasterizados, combinadas por um compositor de prioridades.

O projeto foi pensado para, em etapas futuras do curso, ser controlado por um driver em Assembly ARM (via MMIO) e utilizado por uma aplicação de jogo em C. Nesta primeira etapa, apenas o núcleo gráfico em FPGA foi desenvolvido; a interface de comandos de 32 bits já está definida no formato final, mas ainda é apenas demonstrativa (ver [Limitações conhecidas](#limitações-conhecidas-e-funcionalidades-não-atendidas)).

## Requisitos

### Funcionais

- Gerar saída de vídeo VGA em 640×480 pixels a ~60 Hz, a partir de uma resolução lógica de 320×240 com duplicação de pixel 2×2;
- Renderizar um plano de fundo baseado em tilemap de 40×30 posições, com tiles de 8×8 pixels (mínimo de 256 padrões), suportando atualização de tile e deslocamento (*scroll*) horizontal/vertical;
- Renderizar até 32 sprites de 16×16 pixels, com posição, padrão gráfico, habilitação, prioridade, espelhamento horizontal/vertical e transparência;
- Rasterizar triângulos e retângulos preenchidos usando aritmética inteira;
- Compor as três camadas por pixel, com pelo menos três níveis de prioridade documentados e transparência aplicada antes da seleção do pixel final;
- Converter o índice de cor de 8 bits em um sinal RGB de saída;
- Receber comandos de 32 bits em um formato preparado para a futura interface MMIO, sem depender de uma cena ou jogo específico.

### Não funcionais

- Núcleo inteiramente descrito em Verilog, com arquitetura modular (um arquivo por bloco funcional) e separação clara entre controle, *datapath*, memórias, motores gráficos e saída de vídeo;
- Todos os registradores e memórias com estratégia de inicialização/reset definida;
- Saída de vídeo sem instabilidade visual, perda de sincronismo ou pixels indefinidos após a inicialização;
- Código organizado, comentado e versionado neste repositório GitHub, com projeto Quartus completo para compilação e programação da placa.

## Arquitetura

O núcleo segue o fluxo: um gerador de sincronismo (`controlador_vga`) produz as coordenadas de varredura → essas coordenadas alimentam, em paralelo, os três motores gráficos → um compositor (`compositor`) decide, pixel a pixel, qual camada prevalece → um módulo de conversão de cor (`ram_paleta`) gera o RGB final. Paralelamente, uma unidade de controle (`fsm_controle`) seleciona, via chaves da placa, qual motor está sob operação manual para fins de demonstração.

O diagrama de blocos de alto nível, a descrição detalhada de cada módulo, a justificativa de cada decisão de projeto (incluindo a escolha de usar RGB332 em vez de uma paleta RAM programável) e a explicação das memórias ROM/RAM utilizadas estão no relatório técnico completo (Manual do Sistema e Manual do Usuário) incluído neste repositório em `docs/relatorio.pdf`.

## Hardware utilizado

| Item | Especificação |
|---|---|
| Placa | Terasic DE1-SoC |
| FPGA | Intel/Altera Cyclone V, `5CSEMA5F31C6` |
| Ferramenta | Quartus Prime (testado na versão 20.1.1) |
| Saída de vídeo | Monitor com entrada VGA |

## Como compilar e gravar (reprodução)

1. Clone ou baixe este repositório.
2. Abra o arquivo `PBL_1-SD_grupo_4.qpf` no Quartus Prime.
3. Execute *Processing → Start Compilation* (ou utilize o `.sof` já compilado em `output_files/`, caso não deseje recompilar).
4. Conecte a DE1-SoC ao computador via USB-Blaster e ligue a placa.
5. Abra o *Programmer* do Quartus, selecione `PBL_1-SD_grupo_4.sof` e clique em *Start* para gravar a FPGA.
6. Conecte o monitor VGA à placa.
7. Pressione `KEY0` para resetar o sistema.

Toda a pinagem (chaves, botões, VGA, displays) já vem definida no arquivo `PBL_1-SD_grupo_4.qsf` deste repositório — não é necessário reatribuir pinos manualmente.

### Uso — seleção de modo

O botão `KEY0` é o reset geral. As chaves `SW9`/`SW8` selecionam o motor gráfico ativo:

| Estado | Código (SW9/SW8) | Motor ativo |
|---|---|---|
| A | 00 | Background |
| B | 01 | Sprites |
| C | 11 | Rasterizador de polígonos |

A pinagem completa de cada estado (o que cada chave/botão faz e o pino físico correspondente) está detalhada em `docs/relatorio.pdf`, Seção "Manual do Usuário".

## Estrutura do repositório

```
.
├── PBL_1-SD_grupo_4.qpf / .qsf      # Projeto Quartus
├── main.v                           # Integração de todos os blocos e portas físicas
├── DE1_SOC_golden_top.v             # Top-level padrão da Terasic (pinagem completa da placa)
├── clock_reset.v                    # Geração de clock de vídeo (25 MHz) e reset sincronizado
├── controlador_vga.v                # Gerador de sincronismo VGA (640x480@60Hz)
├── fsm_controle.v                   # Unidade de controle (FSM de demonstração, 3 estados)
├── decodificador_comandos.v         # Interface de comandos de 32 bits (demonstrativa)
├── gerador_comandos_demo.v          # Simulador do processador central para demonstração
├── motor_background.v               # Motor de background (tilemap + scroll)
├── motor_sprites.v                  # Motor de sprites (32 sprites, espelhamento, prioridade)
├── rasterizador_poligonos.v         # Rasterizador de triângulos/retângulos (edge functions)
├── compositor.v                     # Composição das três camadas por prioridade
├── ram_paleta.v                     # Conversão de índice de cor para RGB (RGB332)
├── decodificador_hex.v              # Decodificador de display de 7 segmentos
├── tilemap_ram.v / tilemap_ram_bb.v         # RAM do tilemap (IP altsyncram)
├── tile_pattern_rom.v / tile_pattern_rom_bb.v  # ROM dos padrões de tile (IP altsyncram)
├── sprite_rom.v / sprite_rom_bb.v           # ROM dos padrões de sprite (IP altsyncram)
├── tilemap.mif / tilepattern.mif / sprite_patterns.mif  # Conteúdo inicial das memórias
├── output_files/                    # Arquivos de síntese (.sof, relatórios do Quartus)
└── docs/relatorio.pdf               # Relatório completo (Manual do Sistema e do Usuário)
```

## Memórias ROM e RAM

| Memória | Tipo | Tamanho | Uso |
|---|---|---|---|
| `tilemap_ram` | RAM (leitura/escrita) | 1200 × 8 bits | Índice do tile em cada posição do mapa 40×30; editável em tempo real (futuro comando `OP_SET_TILE`) |
| `tile_pattern_rom` | ROM | 16384 × 8 bits | Desenhos de até 256 padrões de tile 8×8, fixos, carregados via `.mif` |
| `sprite_rom` | ROM | 8192 × 8 bits | Desenhos de até 32 padrões de sprite 16×16, fixos, carregados via `.mif` |

A justificativa completa da escolha de ROM vs. RAM para cada memória está no relatório.

## Testes planejados

Foram planejados os seguintes cenários de teste, exigidos pelo enunciado: transparência, espelhamento, sobreposição, prioridade e comandos inválidos. A metodologia detalhada de cada teste está no relatório técnico. **Estes testes ainda não foram executados na placa física pela equipe**, e não há registros fotográficos/em vídeo de demonstração disponíveis nesta entrega.

## Resultados de síntese

Compilação para o dispositivo `5CSEMA5F31C6` (Quartus Prime):

| Recurso | Utilização |
|---|---|
| Lógica (ALMs) | 880 / 32.070 (3%) |
| Registradores | 829 |
| Pinos | 241 / 457 (53%) |
| Bits de memória de bloco | 148.864 / 4.065.280 (4%) |
| Blocos de RAM | 19 / 397 (5%) |
| Blocos DSP | 3 / 87 (3%) |

O *Timing Analyzer* do Quartus reporta *setup slack* negativo para o clock de vídeo (`vga_clk`) em todos os *corners* de temperatura/tensão analisados (ex.: aproximadamente −10,17 ns no modelo lento a 85 °C) — ou seja, o projeto não fecha *timing* na frequência atual, apesar do baixo uso de lógica. A causa raiz não foi investigada pela equipe até esta entrega.

## Limitações conhecidas e funcionalidades não atendidas

- **Interface de comandos apenas demonstrativa:** o `decodificador_comandos` fatia corretamente o comando de 32 bits, mas seus registradores internos não são lidos por nenhum motor gráfico nesta versão — o núcleo ainda não é controlável externamente por comandos.
- **Transparência de sprites com defeito:** a chave `SW7` deveria tornar o índice de cor 0 do sprite transparente, mas essa funcionalidade não está funcionando corretamente.
- **Sem controle de habilitação de sprites:** os 32 sprites existem na memória de atributos, mas não há chave/botão para habilitar ou desabilitar sprites em tempo de execução; a habilitação é fixa desde o reset (sprites 0–3 habilitados, 4–31 desabilitados).
- **Paleta não é uma RAM programável:** por decisão de projeto (documentada no relatório técnico), o índice de cor de 8 bits é convertido diretamente para RGB332, em vez de usar uma tabela de 256 entradas editável — divergência consciente em relação à redação literal do enunciado.
- **Sem *frame buffer*:** a imagem é gerada pixel a pixel a cada varredura; não há *double buffering* implementado.
- **Timing não fechado:** ver seção de resultados de síntese acima.
- **Testes não executados na placa física** e sem demonstração registrada até esta entrega.

## Trabalhos futuros

- Corrigir o defeito de transparência dos sprites;
- Investigar e corrigir o fechamento de *timing*;
- Ligar efetivamente o decodificador de comandos às memórias/registradores dos motores gráficos;
- Implementar o driver em Assembly ARM e a aplicação de jogo em C que consumirão a interface de comandos aqui projetada.

## Documentação completa

O relatório técnico completo (Manual do Sistema e Manual do Usuário, no formato exigido pela disciplina) está disponível em [`relatorio.pdf`](relatorio.pdf).
