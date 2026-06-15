# 🏗️ Robot Framework — BDD Automation Suite

> Suite de automação com Robot Framework e Python para sistemas financeiros e de seguro. Testes E2E, integração e API com BDD, cobrindo backend, BFF e serviços de billing em ambientes Dev, QA e HML.

![RobotFramework](https://img.shields.io/badge/Robot%20Framework-7.x-000000?logo=robot-framework)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python)
![CI](https://github.com/Roseleyne/robot-framework-automation/actions/workflows/robot-tests.yml/badge.svg)
![BDD](https://img.shields.io/badge/BDD-Gherkin-23D96C)

---

## 📋 Sobre o Projeto

Suite de automação construída com **Robot Framework** e Python para validação de sistemas financeiros críticos. Baseado em experiências reais no **Banco C6** (serviços de seguro) e **AGF** (sistemas financeiros), cobrindo fluxos de contratação, cancelamento, reativação e billing.

### Contexto de negócio coberto

- Fluxos de **contratação e cancelamento** de produtos de seguro
- Serviços de **billing e cobrança**
- Validação de **APIs de backend e BFF**
- Migração de dados (**SulAmérica → MetLife**) — zero incidentes críticos

---

## 🛠️ Stack

| Camada | Tecnologia |
|---|---|
| Framework | Robot Framework 7.x |
| Linguagem | Python 3.11 |
| API Testing | RequestsLibrary |
| DB Validation | DatabaseLibrary |
| Mobile | AppiumLibrary |
| Reports | RF HTML Reports + Allure |
| CI/CD | GitHub Actions |

---

## 🏗️ Arquitetura

```
robot-framework-automation/
│
├── resources/
│   ├── keywords/
│   │   ├── api_keywords.robot       # Keywords para API
│   │   ├── ui_keywords.robot        # Keywords para UI
│   │   └── db_keywords.robot        # Keywords para banco de dados
│   │
│   ├── variables/
│   │   ├── dev_vars.robot
│   │   ├── qa_vars.robot
│   │   └── hml_vars.robot
│   │
│   └── libraries/
│       └── custom_library.py        # Library Python customizada
│
├── tests/
│   ├── api/
│   │   ├── auth_tests.robot
│   │   ├── contracting_tests.robot
│   │   └── billing_tests.robot
│   ├── e2e/
│   │   ├── login_flow.robot
│   │   ├── contracting_flow.robot
│   │   └── cancellation_flow.robot
│   └── regression/
│       └── regression_suite.robot
│
├── data/
│   ├── test_users.json
│   └── contract_payloads.json
│
├── .github/
│   └── workflows/
│       └── robot-tests.yml
│
├── requirements.txt
└── README.md
```

---

## ⚡ Como Rodar

### Pré-requisitos
- Python 3.11+
- pip

### Instalação

```bash
git clone https://github.com/Roseleyne/robot-framework-automation.git
cd robot-framework-automation

python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Execução

```bash
# Todos os testes no ambiente QA
robot --variable ENV:qa tests/

# Suite específica — API
robot --variable ENV:qa tests/api/

# Suite de regressão completa
robot --variable ENV:qa \
      --outputdir reports/ \
      tests/regression/regression_suite.robot

# Relatório com Allure
robot --listener allure_robotframework tests/
allure serve allure-results/
```

---

## 🧩 Exemplos de Keywords

### Keywords de API
```robot
*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Keywords ***
Criar Sessão API
    [Arguments]    ${env}
    ${base_url}=   Get Variable Value    ${BASE_URL_${env.upper()}}
    Create Session    api    ${base_url}    verify=True

Contratar Produto
    [Arguments]    ${payload}
    ${response}=   POST On Session    api    /contracts    json=${payload}
    Status Should Be    201    ${response}
    Dictionary Should Contain Key    ${response.json()}    contractId
    [Return]    ${response.json()}[contractId]

Validar Status Contrato
    [Arguments]    ${contract_id}    ${expected_status}
    ${response}=   GET On Session    api    /contracts/${contract_id}
    Status Should Be    200    ${response}
    Should Be Equal    ${response.json()}[status]    ${expected_status}
```

### Teste E2E com BDD
```robot
*** Test Cases ***
Contratação bem-sucedida de produto de seguro
    [Documentation]    Valida fluxo completo de contratação via API
    [Tags]    e2e    contracting    regression

    Given que o cliente está autenticado    ${TEST_USER}
    When solicita contratação do produto    ${PRODUCT_PAYLOAD}
    Then o contrato deve ser criado com status    ACTIVE
    And o billing deve ser gerado corretamente

*** Keywords ***
que o cliente está autenticado
    [Arguments]    ${user}
    ${token}=    Autenticar Usuário    ${user}[email]    ${user}[password]
    Set Suite Variable    ${AUTH_TOKEN}    ${token}

solicita contratação do produto
    [Arguments]    ${payload}
    ${contract_id}=    Contratar Produto    ${payload}
    Set Test Variable    ${CONTRACT_ID}    ${contract_id}

o contrato deve ser criado com status
    [Arguments]    ${status}
    Validar Status Contrato    ${CONTRACT_ID}    ${status}
```

---

## 📊 Cobertura de Testes

| Suite | Casos | Automatizados | Ambientes |
|---|---|---|---|
| Autenticação | 12 | ✅ 12 | Dev, QA, HML |
| Contratação | 28 | ✅ 28 | Dev, QA, HML |
| Cancelamento | 15 | ✅ 15 | QA, HML |
| Reativação | 10 | ✅ 10 | QA, HML |
| Billing | 20 | ✅ 18 🔄 2 | QA |
| **Total** | **85** | **83** | — |

---

## 👩‍💻 Autora

**Roseleyne Duarte Silva** — Senior QA Engineer | SDET

Experiência com Robot Framework em sistemas financeiros críticos:
- **Banco C6** — Serviços de seguro SulAmérica/MetLife
- **AGF** — Sistemas financeiros Web e Mobile

---

- 🌐 [Portfolio](https://roseleyne.github.io/portfolio)
- 💼 [LinkedIn](https://www.linkedin.com/in/roseleyne-duarte-silva/)
- 🐙 [GitHub](https://github.com/Roseleyne)
- 📧 roseleyne.duarte@gmail.com
