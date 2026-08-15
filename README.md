# 📊 Check-in Quinzenal & Gestão de Treinos

Aplicativo em **Flutter** desenvolvido para simplificar, automatizar e organizar o registro diário de treinos, sono, alimentação, cardio e hábitos de saúde, gerando relatórios estruturados para o preenchimento de planilhas de acompanhamento e feedback de coaching.

---

## 🚀 Funcionalidades Principais

### 1. 🏃 Gestão e Metas de Cardio
- **Adição Avulsa de Sessões:** registre quantos cardios fizer ao longo do dia ou da semana (duração, BPM médio, horário e anotações).
- **Meta Semanal com Projeção do Ciclo:** defina sua meta semanal em minutos (ex.: 150 min/semana), e o app calcula automaticamente a meta para o ciclo quinzenal (300 min), exibindo a barra de progresso, percentual atingido, minutos restantes e cálculo de BPM médio ponderado.
- **Visualização por Semana:** acompanhe o quanto fez na **Semana 1** vs **Semana 2** para compensar eventuais faltas.

### 2. 🏋️ Integração Inteligente com o Hevy
- **Importação Direta por Texto:** cole o texto compartilhado do treino do aplicativo Hevy.
- **Extração Automática:** detecta título, data, **horário do treino** (formatos 12h AM/PM e 24h), exercícios, séries, pesos, repetições e notas.
- **Sincronização Automática com o Check-in:** ao registrar um treino, o check-in do dia é automaticamente marcado como `treinou: sim` com o horário preenchido.

### 3. 🛌 Registro Rápido de Sono
- **Botão de 1 Toque (`+ Sono`):** permite registrar ou editar rapidamente os dados de sono de qualquer noite.
- **Chips de Duração Rápida:** botões pré-definidos (`6h`, `6.5h`, `7h`, `7.5h`, `8h`, `8.5h`, `9h`) e campo decimal para valores personalizados.
- **Qualidade e Satisfação:** registro de qualidade (0 a 100%) e escala visual de satisfação (1 a 5).

### 4. 💬 Resumo Diário & Compilação Semanal
- **Comentários do Dia:** anote como foi a recuperação, rendimento no treino, dieta ou imprevistos através do botão `+ Resumo`.
- **Agrupamento Automático no Relatório:** os comentários diários são compilados em seções organizadas por **Semana 1** e **Semana 2**, facilitando a cópia para a planilha.

### 5. 📑 Relatório de Feedback Estruturado
- **Abas Especializadas:**
  - **📅 Dia a Dia (Visão Integrada):** cartão visual completo para cada dia com Treino, Cardio, Chips coloridos de Check-in e Resumo diário.
  - **🏋️ Treinos:** listagem focada nos treinos de musculação do ciclo, detalhando séries, repetições e cargas.
  - **📋 Check-in:** visualização das métricas de saúde, rotina e bem-estar.
  - **📝 Texto Planilha:** saída formatada em texto puro monoespaçado, pronta para envio.
- **Opções de Cópia Flexíveis:** botões para *Copiar Relatório Completo*, *Copiar Apenas Treinos* ou *Compartilhar*.

### 6. ⚡ Alta Performance
- **Indexação $O(1)$ em Memória:** consultas de treinos e cardios por dia sem filtros lineares ou alocações redundantes no scroll.
- **Cache de Ciclos:** memoização inteligente de datas e períodos disponíveis.

---

## 🛠️ Tecnologias Utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (Channel Stable 3.x)
- **Linguagem:** [Dart 3.x](https://dart.dev/)
- **Armazenamento Local:** `shared_preferences`
- **Compartilhamento:** `share_plus`
- **Design System:** Material 3 (paleta dinâmica, tipografia responsiva e componentes acessíveis)

---

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                  # Ponto de entrada, ciclo de vida e tela inicial (HomeScreen)
├── models.dart                # Modelos de dados (CheckIn, Workout, CardioEntry, Settings)
├── storage.dart               # Gerenciador de estado (AppState), persistência e indexação rápida
├── hevy_parser.dart           # Parser regex para importação de treinos do Hevy
├── report.dart                # Gerador de texto formatado para a planilha
├── screens/
│   ├── day_form_screen.dart   # Formulário diário completo de 28 métricas
│   ├── report_screen.dart     # Tela de relatório com 4 abas visuais e KPIs
│   ├── settings_screen.dart   # Configurações de ciclo, esportes padrão e meta de cardio
│   └── workout_screen.dart    # Lista e editor detalhado de treinos e séries
└── widgets/
    └── form_widgets.dart      # Modais rápidos (+ Cardio, + Sono, + Resumo), escalas e seletores
```

---

## ⚙️ Como Executar

### Pré-requisitos
- Flutter SDK instalado e configurado no `PATH`.
- JDK 17 ou 21 LTS configurado (`java -version`).
- Dispositivo Android conectado via USB (com Depuração USB ativada) ou emulador.

### Passos

1. **Clonar o repositório:**
   ```bash
   git clone https://github.com/bcosta19/automatizacao-preenchimento-planilha.git
   cd automatizacao-preenchimento-planilha
   ```

2. **Instalar as dependências:**
   ```bash
   flutter pub get
   ```

3. **Executar os testes automatizados:**
   ```bash
   flutter test
   ```

4. **Executar no dispositivo conectado:**
   ```bash
   flutter run
   ```

5. **Gerar o APK de produção (Release):**
   ```bash
   flutter build apk --release
   ```
   *O arquivo APK gerado estará em `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 📄 Licença

Este projeto é de uso pessoal e privado para acompanhamento e automação de planilhas de treino.
