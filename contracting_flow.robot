*** Settings ***
# tests/e2e/contracting_flow.robot
Documentation     Testes E2E do fluxo de contratação de produtos de seguro.
...               Baseado em experiências reais no Banco C6 — validação de
...               fluxos de contratação, cancelamento e reativação de apólices.

Resource          ../../resources/keywords/api_keywords.robot
Resource          ../../resources/variables/qa_vars.robot

Suite Setup       Inicializar Suite
Suite Teardown    Finalizar Suite

Test Tags         e2e    contracting    regression


*** Variables ***
${PRODUTO_VIDA}         PROD_VIDA_001
${PRODUTO_AUTO}         PROD_AUTO_002


*** Test Cases ***

Contratação bem-sucedida de seguro de vida
    [Documentation]    Valida fluxo completo: contratação → status ATIVO → boleto gerado.
    [Tags]             smoke    vida

    Given que o cliente está autenticado como    ${USER_STANDARD}
    When solicita contratação do produto         ${PRODUTO_VIDA}    ${DADOS_SEGURADO_PADRAO}
    Then o contrato deve ter status              ATIVO
    And  o boleto deve ser gerado corretamente

Cancelamento de contrato ativo
    [Documentation]    Valida fluxo de cancelamento com motivo SOLICITACAO_CLIENTE.
    [Tags]             cancelamento

    Given que o cliente está autenticado como    ${USER_STANDARD}
    And   possui contrato ativo do produto       ${PRODUTO_VIDA}
    When  solicita cancelamento do contrato
    Then  o contrato deve ter status             CANCELADO

Rejeição de contratação com dados inválidos
    [Documentation]    Valida que API rejeita contratação sem CPF do segurado.
    [Tags]             negativo

    Given que o cliente está autenticado como    ${USER_STANDARD}
    When tenta contratar produto sem CPF         ${PRODUTO_VIDA}
    Then a API deve retornar erro                400
    And  a mensagem de erro deve conter          CPF é obrigatório

Migração de apólice — SulAmérica para MetLife
    [Documentation]    Valida que contrato migrado mantém status e dados corretos.
    ...                Cenário crítico baseado no projeto real de migração no Banco C6.
    [Tags]             migracao    critico

    Given que existe um contrato migrado do sistema origem    ${CONTRATO_MIGRADO_ID}
    When consulta o contrato no sistema destino
    Then o contrato deve ter status                          ATIVO
    And  os dados do segurado devem estar corretos
    And  o histórico de pagamentos deve estar preservado


*** Keywords ***

Inicializar Suite
    Criar Sessão API    qa

Finalizar Suite
    Delete All Sessions

que o cliente está autenticado como
    [Arguments]    ${user}
    ${token}=      Autenticar Usuário    ${user}[email]    ${user}[password]
    Set Suite Variable    ${AUTH_HEADERS}    ${Autenticado.Criar Headers Autenticados(token)}
    ${headers}=    Criar Headers Autenticados    ${token}
    Set Suite Variable    ${AUTH_HEADERS}    ${headers}

solicita contratação do produto
    [Arguments]    ${produto_id}    ${dados_segurado}
    ${contrato_id}=    Contratar Produto    ${AUTH_HEADERS}    ${produto_id}    ${dados_segurado}
    Set Test Variable    ${CONTRATO_ID}    ${contrato_id}

o contrato deve ter status
    [Arguments]    ${status_esperado}
    Aguardar Processamento
    ...    ${AUTH_HEADERS}    /contratos/${CONTRATO_ID}    status    ${status_esperado}
    Validar Status Contrato    ${AUTH_HEADERS}    ${CONTRATO_ID}    ${status_esperado}

o boleto deve ser gerado corretamente
    Validar Geração De Boleto    ${AUTH_HEADERS}    ${CONTRATO_ID}

possui contrato ativo do produto
    [Arguments]    ${produto_id}
    ${dados}=       Get Variable Value    ${DADOS_SEGURADO_PADRAO}
    ${contrato_id}= Contratar Produto    ${AUTH_HEADERS}    ${produto_id}    ${dados}
    Set Test Variable    ${CONTRATO_ID}    ${contrato_id}
    Aguardar Processamento
    ...    ${AUTH_HEADERS}    /contratos/${CONTRATO_ID}    status    ATIVO

solicita cancelamento do contrato
    Cancelar Contrato    ${AUTH_HEADERS}    ${CONTRATO_ID}

tenta contratar produto sem CPF
    [Arguments]    ${produto_id}
    ${dados_invalidos}=    Create Dictionary    nome=Teste Sem CPF
    ${response}=    POST On Session    api
    ...             /contratos
    ...             json=${{ {"produtoId": "${produto_id}", "segurado": ${dados_invalidos}} }}
    ...             headers=${AUTH_HEADERS}
    ...             expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

a API deve retornar erro
    [Arguments]    ${status_code}
    Should Be Equal As Integers    ${LAST_RESPONSE.status_code}    ${status_code}

a mensagem de erro deve conter
    [Arguments]    ${mensagem}
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Should Contain    str(${body})    ${mensagem}

que existe um contrato migrado do sistema origem
    [Arguments]    ${contrato_id}
    Set Test Variable    ${CONTRATO_ID}    ${contrato_id}

consulta o contrato no sistema destino
    ${contrato}=    Validar Status Contrato
    ...             ${AUTH_HEADERS}    ${CONTRATO_ID}    ATIVO
    Set Test Variable    ${CONTRATO_DADOS}    ${contrato}

os dados do segurado devem estar corretos
    Dictionary Should Contain Key    ${CONTRATO_DADOS}    segurado
    Should Not Be Empty    ${CONTRATO_DADOS}[segurado][cpf]
    Should Not Be Empty    ${CONTRATO_DADOS}[segurado][nome]

o histórico de pagamentos deve estar preservado
    ${response}=    GET On Session
    ...             api    /contratos/${CONTRATO_ID}/pagamentos
    ...             headers=${AUTH_HEADERS}
    Status Should Be    200    ${response}
    ${pagamentos}=    Set Variable    ${response.json()}
    Should Not Be Empty    ${pagamentos}
